```verilog
module axis_switch #
(
    parameter S_COUNT = 4,
    parameter M_COUNT = 4,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter S_ID_WIDTH = 8,
    parameter M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
    parameter M_DEST_WIDTH = 1,
    parameter S_DEST_WIDTH = M_DEST_WIDTH+$clog2(M_COUNT),
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter M_BASE = 0,
    parameter M_TOP = 0,
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    parameter UPDATE_TID = 0,
    parameter S_REG_TYPE = 0,
    parameter M_REG_TYPE = 2,
    parameter ARB_TYPE_ROUND_ROBIN = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
    input  wire                             clk,
    input  wire                             rst,
    /*
     * AXI Stream inputs
     */
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [S_COUNT*KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    output wire [S_COUNT-1:0]               s_axis_tready,
    input  wire [S_COUNT-1:0]               s_axis_tlast,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axis_tid,
    input  wire [S_COUNT*S_DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [S_COUNT*USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI Stream outputs
     */
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [M_COUNT*KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire [M_COUNT-1:0]               m_axis_tvalid,
    input  wire [M_COUNT-1:0]               m_axis_tready,
    output wire [M_COUNT-1:0]               m_axis_tlast,
    output wire [M_COUNT*M_ID_WIDTH-1:0]    m_axis_tid,
    output wire [M_COUNT*M_DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [M_COUNT*USER_WIDTH-1:0]    m_axis_tuser
);

    localparam LOG_S_COUNT = $clog2(S_COUNT);
    localparam LOG_M_COUNT = $clog2(M_COUNT);

    // State encoding for Round Robin
    localparam [LOG_S_COUNT:0] STATE_IDLE = 0;
    localparam [LOG_S_COUNT:0] STATE_GRANT = 1;

    // Round Robin counters
    reg [LOG_S_COUNT-1:0] rr_counter;
    wire [LOG_S_COUNT-1:0] rr_next_counter;

    // State registers
    reg [LOG_S_COUNT:0] state;
    reg [LOG_S_COUNT-1:0] grant_index;
    reg [LOG_S_COUNT-1:0] last_grant_index;

    // Output buffers for the currently granted stream
    reg [DATA_WIDTH-1:0] out_tdata;
    reg [KEEP_WIDTH-1:0] out_tkeep;
    reg out_tvalid;
    reg out_tlast;
    reg [S_ID_WIDTH-1:0] out_tid;
    reg [S_DEST_WIDTH-1:0] out_tdest;
    reg [USER_WIDTH-1:0] out_tuser;

    // Arbitration Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rr_counter <= 0;
            state <= STATE_IDLE;
            grant_index <= 0;
            last_grant_index <= 0;
        end else begin
            if (state == STATE_IDLE) begin
                // Check if any input is valid
                if (|s_axis_tvalid) begin
                    state <= STATE_GRANT;
                    // Find the first valid input (lowest index)
                    grant_index <= 0;
                    for (integer i = 0; i < S_COUNT; i = i + 1) begin
                        if (s_axis_tvalid[i]) begin
                            grant_index <= i;
                            break;
                        end
                    end
                end else begin
                    state <= STATE_IDLE;
                end
            end else if (state == STATE_GRANT) begin
                // Check if the granted stream is ready
                if (m_axis_tready[grant_index]) begin
                    // Grant successful, move to next round robin slot
                    rr_counter <= rr_counter + 1;
                    if (rr_counter == S_COUNT) begin
                        rr_counter <= 0;
                    end
                    // Update grant index to the next slot in round robin
                    grant_index <= rr_counter;
                    
                    // Check if the new slot has data
                    if (s_axis_tvalid[grant_index]) begin
                        // Continue granting
                    end else begin
                        // No data in new slot, try to find next valid slot
                        // Simple fallback: scan from current index
                        integer i;
                        for (i = grant_index + 1; i < S_COUNT; i = i + 1) begin
                            if (s_axis_tvalid[i]) begin
                                grant_index <= i;
                                break;
                            end
                        end
                        if (i == S_COUNT) begin
                            // Wrap around
                            for (i = 0; i < grant_index; i = i + 1) begin
                                if (s_axis_tvalid[i]) begin
                                    grant_index <= i;
                                    break;
                                end
                            end
                        end
                    end
                end else begin
                    // Not ready, keep granting same stream
                    // Do nothing, state remains STATE_GRANT, grant_index remains same
                end
            end
        end
    end

    // Data path logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_tvalid <= 1'b0;
            out_tdata <= 0;
            out_tkeep <= 0;
            out_tlast <= 1'b0;
            out_tid <= 0;
            out_tdest <= 0;
            out_tuser <= 0;
            s_axis_tready <= {S_COUNT{1'b0}};
            m_axis_tvalid <= {M_COUNT{1'b0}};
            m_axis_tlast <= {M_COUNT{1'b0}};
            m_axis_tid <= 0;
            m_axis_tdest <= 0;
            m_axis_tuser <= 0;
            m_axis_tdata <= 0;
            m_axis_tkeep <= 0;
        end else begin
            // Update output data from the granted stream
            if (state == STATE_GRANT && m_axis_tready[grant_index]) begin
                out_tvalid <= s_axis_tvalid[grant_index];
                out_tdata <= s_axis_tdata[grant_index*DATA_WIDTH +: DATA_WIDTH];
                out_tkeep <= s_axis_tkeep[grant_index*KEEP_WIDTH +: KEEP_WIDTH];
                out_tlast <= s_axis_tlast[grant_index];
                out_tid <= s_axis_tid[grant_index*S_ID_WIDTH +: S_ID_WIDTH];
                out_tdest <= s_axis_tdest[grant_index*S_DEST_WIDTH +: S_DEST_WIDTH];
                out_tuser <= s_axis_tuser[grant_index*USER_WIDTH +: USER_WIDTH];
            end else begin
                out_tvalid <= 1'b0;
                out_tdata <= 0;
                out_tkeep <= 0;
                out_tlast <= 1'b0;
                out_tid <= 0;
                out_tdest <= 0;
                out_tuser <= 0;
            end

            // Assign output ports
            for (integer i = 0; i < M_COUNT; i = i + 1) begin
                if (i == grant_index) begin
                    m_axis_tvalid[i] <= out_tvalid;
                    m_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH] <= out_tdata;
                    m_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH] <= out_tkeep;
                    m_axis_tlast[i] <= out_tlast;
                    m_axis_tid[i*M_ID_WIDTH +: M_ID_WIDTH] <= out_tid;
                    m_axis_tdest[i*M_DEST_WIDTH +: M_DEST_WIDTH] <= out_tdest;
                    m_axis_tuser[i*USER_WIDTH +: USER_WIDTH] <= out_tuser;
                end else begin
                    m_axis_tvalid[i] <= 1'b0;
                    m_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH] <= 0;
                    m_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH] <= 0;
                    m_axis_tlast[i] <= 1'b0;
                    m_axis_tid[i*M_ID_WIDTH +: M_ID_WIDTH] <= 0;
                    m_axis_tdest[i*M_DEST_WIDTH +: M_DEST_WIDTH] <= 0;
                    m_axis_tuser[i*USER_WIDTH +: USER_WIDTH] <= 0;
                end
            end

            // Assign input ready signals
            for (integer i = 0; i < S_COUNT; i = i + 1) begin
                s_axis_tready[i] <= (state == STATE_GRANT && grant_index == i) ? m_axis_tready[i] : 1'b0;
            end
        end
    end

endmodule
```<|im_end|>
