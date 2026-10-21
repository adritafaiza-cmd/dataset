```verilog
module axis_adapter #
(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH>8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH+7)/8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH>8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1
)
(
    input  wire                     clk,
    input  wire                     rst,
    /*
     * AXI input
     */
    input  wire [S_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI output
     */
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser
);

    localparam S_KEEP_MASK = S_KEEP_ENABLE ? ~{S_KEEP_WIDTH{1'b0}} : 1;
    localparam M_KEEP_MASK = M_KEEP_ENABLE ? ~{M_KEEP_WIDTH{1'b0}} : 1;

    // Calculate the number of source beats required to fill one destination beat
    localparam S_BEATS_PER_M = M_DATA_WIDTH / S_DATA_WIDTH;
    
    // Calculate the number of destination beats required to fill one source beat
    localparam M_BEATS_PER_S = S_DATA_WIDTH / M_DATA_WIDTH;

    // State machine states
    localparam IDLE = 0;
    localparam FILLING = 1;
    localparam FLUSHING = 2;

    reg [2:0] state;
    reg [S_BEATS_PER_M-1:0] s_beats_left;
    reg [M_BEATS_PER_S-1:0] m_beats_left;
    reg [S_DATA_WIDTH-1:0] shift_reg;
    reg [S_DATA_WIDTH-1:0] data_in;
    reg [S_KEEP_WIDTH-1:0] keep_in;
    reg [M_DATA_WIDTH-1:0] data_out;
    reg [M_KEEP_WIDTH-1:0] keep_out;
    reg s_last;
    reg m_last;
    reg s_valid;
    reg m_valid;
    reg [ID_WIDTH-1:0] tid;
    reg [DEST_WIDTH-1:0] tdest;
    reg [USER_WIDTH-1:0] tuser;

    // Internal signals for keep logic
    reg [S_KEEP_WIDTH-1:0] s_keep_mask;
    reg [M_KEEP_WIDTH-1:0] m_keep_mask;

    // Initialize parameters
    assign s_keep_mask = S_KEEP_ENABLE ? {S_KEEP_WIDTH{1'b1}} : 1;
    assign m_keep_mask = M_KEEP_ENABLE ? {M_KEEP_WIDTH{1'b1}} : 1;

    // State Machine Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            s_beats_left <= 0;
            m_beats_left <= 0;
            shift_reg <= 0;
            data_in <= 0;
            keep_in <= 0;
            s_last <= 0;
            m_last <= 0;
            s_valid <= 0;
            m_valid <= 0;
            tid <= 0;
            tdest <= 0;
            tuser <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid && m_axis_tready) begin
                        state <= FILLING;
                        s_beats_left <= S_BEATS_PER_M;
                        m_beats_left <= M_BEATS_PER_S;
                        shift_reg <= s_axis_tdata;
                        data_in <= s_axis_tdata;
                        keep_in <= s_axis_tkeep;
                        s_last <= s_axis_tlast;
                        tid <= s_axis_tid;
                        tdest <= s_axis_tdest;
                        tuser <= s_axis_tuser;
                        s_valid <= 1;
                        m_valid <= 0;
                    end else begin
                        s_valid <= 0;
                        m_valid <= 0;
                    end
                end

                FILLING: begin
                    // Check if we have enough source data to fill a destination beat
                    if (s_axis_tvalid && m_axis_tready && s_beats_left > 0) begin
                        // Shift data into the register
                        shift_reg <= {shift_reg[(S_DATA_WIDTH-S_DATA_WIDTH):0], s_axis_tdata[S_DATA_WIDTH-1:0]};
                        
                        // Update keep bits
                        keep_in <= {keep_in[(S_KEEP_WIDTH-1):S_KEEP_WIDTH], s_axis_tkeep[S_KEEP_WIDTH-1:0]};
                        
                        // Decrement source beats counter
                        s_beats_left <= s_beats_left - 1;
                        
                        // If we have filled the destination beat width
                        if (s_beats_left == 0) begin
                            // Prepare output data
                            data_out <= shift_reg;
                            keep_out <= keep_in;
                            m_last <= s_last;
                            
                            // Output valid if ready
                            if (m_axis_tready) begin
                                m_valid <= 1;
                            end
                            
                            // Reset source valid
                            s_valid <= 0;
                            
                            // Transition to FLUSHING if there is more source data coming
                            if (s_axis_tvalid) begin
                                state <= FLUSHING;
                                s_beats_left <= S_BEATS_PER_M;
                                m_beats_left <= M_BEATS_PER_S;
                                shift_reg <= s_axis_tdata;
                                data_in <= s_axis_tdata;
                                keep_in <= s_axis_tkeep;
                                s_last <= s_axis_tlast;
                                tid <= s_axis_tid;
                                tdest <= s_axis_tdest;
                                tuser <= s_axis_tuser;
                            end else begin
                                state <= IDLE;
                            end
                        end
                    end else begin
                        // If we are waiting for source data but have no destination ready
                        // We need to hold the current state and wait for either source or destination
                        if (s_axis_tvalid && !m_axis_tready) begin
                            // Wait for destination ready
                        end else if (!s_axis_tvalid && m_axis_tready) begin
                            // Wait for source valid
                        end
                    end
                end

                FLUSHING: begin
                    // This state is used when we have a partial beat at the end of a packet
                    // and need to flush it out beat by beat
                    
                    // Check if we have enough source data to fill a destination beat
                    if (s_axis_tvalid && m_axis_tready && s_beats_left > 0) begin
                        // Shift data into the register
                        shift_reg <= {shift_reg[(S_DATA_WIDTH-S_DATA_WIDTH):0], s_axis_tdata[S_DATA_WIDTH-1:0]};
                        
                        // Update keep bits
                        keep_in <= {keep_in[(S_KEEP_WIDTH-1):S_KEEP_WIDTH], s_axis_tkeep[S_KEEP_WIDTH-1:0]};
                        
                        // Decrement source beats counter
                        s_beats_left <= s_beats_left - 1;
                        
                        // If we have filled the destination beat width
                        if (s_beats_left == 0) begin
                            // Prepare output data
                            data_out <= shift_reg;
                            keep_out <= keep_in;
                            m_last <= s_last;
                            
                            // Output valid if ready
                            if (m_axis_tready) begin
                                m_valid <= 1;
                            end
                            
                            // Reset source valid
                            s_valid <= 0;
                            
                            // Transition to IDLE if there is no more source data
                            if (!s_axis_tvalid) begin
                                state <= IDLE;
                            end else begin
                                // Continue filling
                                state <= FILLING;
                                s_beats_left <= S_BEATS_PER_M;
                                m_beats_left <= M_BEATS_PER_S;
                                shift_reg <= s_axis_tdata;
                                data_in <= s_axis_tdata;
                                keep_in <= s_axis_tkeep;
                                s_last <= s_axis_tlast;
                                tid <= s_axis_tid;
                                tdest <= s_axis_tdest;
                                tuser <= s_axis_tuser;
                            end
                        end
                    end else begin
                        // If we are waiting for source data but have no destination ready
                        if (s_axis_tvalid && !m_axis_tready) begin
                            // Wait for destination ready
                        end else if (!s_axis_tvalid && m_axis_tready) begin
                            // Wait for source valid
                        end
                    end
                end
            endcase
        end
    end

    // Output Logic
    assign m_axis_tdata = data_out;
    assign m_axis_tkeep = keep_out;
    assign m_axis_tvalid = m_valid;
    assign m_axis_tlast = m_last;
    assign m_axis_tid = tid;
    assign m_axis_tdest = tdest;
    assign m_axis_tuser = tuser;

    // Input Logic
    assign s_axis_tready = s_valid && m_axis_tready;

endmodule
```<|im_end|>
