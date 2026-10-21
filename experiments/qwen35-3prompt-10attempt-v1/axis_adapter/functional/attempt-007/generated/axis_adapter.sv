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

    // Calculate bit width ratios
    localparam S_KEEP_RATIO = S_KEEP_ENABLE ? S_KEEP_WIDTH : 1;
    localparam M_KEEP_RATIO = M_KEEP_ENABLE ? M_KEEP_WIDTH : 1;
    
    // Calculate number of source beats per destination beat (packing)
    localparam S_BEATS_PER_M = M_DATA_WIDTH / S_DATA_WIDTH;
    
    // Calculate number of destination beats per source beat (unpacking)
    localparam M_BEATS_PER_S = S_DATA_WIDTH / M_DATA_WIDTH;

    // State machine to handle packing/unpacking logic
    typedef enum logic [1:0] {
        IDLE,
        PACKING,
        UNPACKING
    } state_t;

    state_t state, next_state;
    logic [S_DATA_WIDTH/S_DATA_WIDTH-1:0] s_data_buffer; // Buffer for source data
    logic [M_DATA_WIDTH/M_DATA_WIDTH-1:0] m_data_buffer; // Buffer for destination data
    logic s_last_seen;
    logic m_last_seen;
    logic s_valid_buffer;
    logic m_valid_buffer;
    logic s_ready_buffer;
    logic m_ready_buffer;
    
    // Counters for packing/unpacking
    logic [32:0] s_beats_left;
    logic [32:0] m_beats_left;
    logic [S_DATA_WIDTH/S_DATA_WIDTH-1:0] s_idx;
    logic [M_DATA_WIDTH/M_DATA_WIDTH-1:0] m_idx;

    // Sideband registers
    logic [ID_WIDTH-1:0] tid_reg;
    logic [DEST_WIDTH-1:0] tdest_reg;
    logic [USER_WIDTH-1:0] tuser_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            s_data_buffer <= '0;
            m_data_buffer <= '0;
            s_last_seen <= 1'b0;
            m_last_seen <= 1'b0;
            s_valid_buffer <= 1'b0;
            m_valid_buffer <= 1'b0;
            s_ready_buffer <= 1'b0;
            m_ready_buffer <= 1'b0;
            s_beats_left <= 0;
            m_beats_left <= 0;
            s_idx <= 0;
            m_idx <= 0;
            tid_reg <= '0;
            tdest_reg <= '0;
            tuser_reg <= '0;
        end else begin
            state <= next_state;
            s_data_buffer <= s_data_buffer;
            m_data_buffer <= m_data_buffer;
            s_last_seen <= s_last_seen;
            m_last_seen <= m_last_seen;
            s_valid_buffer <= s_valid_buffer;
            m_valid_buffer <= m_valid_buffer;
            s_ready_buffer <= s_ready_buffer;
            m_ready_buffer <= m_ready_buffer;
            s_beats_left <= s_beats_left;
            m_beats_left <= m_beats_left;
            s_idx <= s_idx;
            m_idx <= m_idx;
            tid_reg <= tid_reg;
            tdest_reg <= tdest_reg;
            tuser_reg <= tuser_reg;
        end
    end

    always @(*) begin
        next_state = IDLE;
        s_axis_tready = 1'b0;
        m_axis_tvalid = 1'b0;
        m_axis_tlast = 1'b0;
        m_axis_tid = '0;
        m_axis_tdest = '0;
        m_axis_tuser = '0;
        m_axis_tkeep = '0;
        m_axis_tdata = '0;

        case (state)
            IDLE: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    if (s_axis_tlast) begin
                        // Last beat of a packet
                        s_last_seen = 1'b1;
                        s_valid_buffer = 1'b1;
                        s_beats_left = 0;
                        s_idx = 0;
                        next_state = (S_BEATS_PER_M == 1) ? IDLE : PACKING;
                    end else begin
                        // First beat of a packet
                        s_last_seen = 1'b0;
                        s_valid_buffer = 1'b1;
                        s_beats_left = S_BEATS_PER_M - 1;
                        s_idx = 0;
                        next_state = (S_BEATS_PER_M == 1) ? IDLE : PACKING;
                    end
                    // Forward sidebands immediately for first beat
                    tid_reg = s_axis_tid;
                    tdest_reg = s_axis_tdest;
                    tuser_reg = s_axis_tuser;
                    
                    // Prepare output
                    m_axis_tvalid = 1'b1;
                    m_axis_tlast = s_axis_tlast;
                    m_axis_tid = tid_reg;
                    m_axis_tdest = tdest_reg;
                    m_axis_tuser = tuser_reg;
                    
                    // Calculate keep mask
                    if (M_KEEP_ENABLE) begin
                        m_axis_tkeep = 1'b1;
                        for (integer i = 0; i < M_KEEP_WIDTH; i = i + 1) begin
                            if (i < M_DATA_WIDTH) begin
                                m_axis_tkeep[i] = 1'b1;
                            end
                        end
                    end
                    m_axis_tdata = s_axis_tdata;
                    
                    s_axis_tready = 1'b1;
                end
            end

            PACKING: begin
                // Accumulate data from source
                if (s_axis_tvalid && m_axis_tready) begin
                    s_data_buffer[s_idx] = s_axis_tdata;
                    s_idx = s_idx + 1;
                    
                    if (s_idx >= S_BEATS_PER_M - 1) begin
                        // We have enough data to form one destination beat
                        // Check if this was the last beat of the source packet
                        if (s_axis_tlast) begin
                            s_last_seen = 1'b1;
                            s_valid_buffer = 1'b1;
                            s_beats_left = 0;
                            s_idx = 0;
                            next_state = IDLE;
                        end else begin
                            s_last_seen = 1'b0;
                            s_valid_buffer = 1'b1;
                            s_beats_left = s_beats_left - 1;
                            s_idx = 0;
                            next_state = PACKING;
                        end
                        
                        // Prepare output
                        m_axis_tvalid = 1'b1;
                        m_axis_tlast = s_axis_tlast;
                        m_axis_tid = tid_reg;
                        m_axis_tdest = tdest_reg;
                        m_axis_tuser = tuser_reg;
                        
                        // Calculate keep mask
                        if (M_KEEP_ENABLE) begin
                            m_axis_tkeep = 1'b1;
                            for (integer i = 0; i < M_KEEP_WIDTH; i = i + 1) begin
                                if (i < M_DATA_WIDTH) begin
                                    m_axis_tkeep[i] = 1'b1;
                                end
                            end
                        end
                        m_axis_tdata = s_data_buffer;
                        
                        s_axis_tready = 1'b1;
                    end
                end
            end

            UNPACKING: begin
                // Distribute data from source to multiple destination beats
                if (s_axis_tvalid && m_axis_tready) begin
                    m_data_buffer[m_idx] = s_axis_tdata;
                    m_idx = m_idx + 1;
                    
                    if (m_idx >= M_BEATS_PER_S - 1) begin
                        // We have enough data to form one source beat
                        if (s_axis_tlast) begin
                            s_last_seen = 1'b1;
                            s_valid_buffer = 1'b1;
                            s_beats_left = 0;
                            s_idx = 0;
                            next_state = IDLE;
                        end else begin
                            s_last_seen = 1'b0;
                            s_valid_buffer = 1'b1;
                            s_beats_left = s_beats_left - 1;
                            s_idx = 0;
                            next_state = UNPACKING;
                        end
                        
                        // Prepare output
                        m_axis_tvalid = 1'b1;
                        m_axis_tlast = s_axis_tlast;
                        m_axis_tid = tid_reg;
                        m_axis_tdest = tdest_reg;
                        m_axis_tuser = tuser_reg;
                        
                        // Calculate keep mask
                        if (M_KEEP_ENABLE) begin
                            m_axis_tkeep = 1'b1;
                            for (integer i = 0; i < M_KEEP_WIDTH; i = i + 1) begin
                                if (i < M_DATA_WIDTH) begin
                                    m_axis_tkeep[i] = 1'b1;
                                end
                            end
                        end
                        m_axis_tdata = m_data_buffer;
                        
                        s_axis_tready = 1'b1;
                    end
                end
            end
        endcase
    end

    // Output sideband updates on valid
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tid_reg <= '0;
            tdest_reg <= '0;
            tuser_reg <= '0;
        end else if (m_axis_tvalid) begin
            tid_reg <= s_axis_tid;
            tdest_reg <= s_axis_tdest;
            tuser_reg <= s_axis_tuser;
        end
    end

    // Keep signal generation logic
    always @(*) begin
        if (M_KEEP_ENABLE) begin
            m_axis_tkeep = '0;
            for (integer i = 0; i < M_KEEP_WIDTH; i = i + 1) begin
                if (i < M_DATA_WIDTH) begin
                    m_axis_tkeep[i] = 1'b1;
                end
            end
        end else begin
            m_axis_tkeep = '0;
        end
    end

endmodule
```<|im_end|>
