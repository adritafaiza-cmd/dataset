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

    /*
     * Internal signals
     */
    reg [S_COUNT-1:0]                       s_axis_tready_int;
    reg [M_COUNT-1:0]                       m_axis_tvalid_int;
    reg [S_COUNT*DATA_WIDTH-1:0]            s_axis_tdata_int;
    reg [S_COUNT*KEEP_WIDTH-1:0]            s_axis_tkeep_int;
    reg [S_COUNT-1:0]                       s_axis_tlast_int;
    reg [S_COUNT*S_ID_WIDTH-1:0]            s_axis_tid_int;
    reg [S_COUNT*S_DEST_WIDTH-1:0]          s_axis_tdest_int;
    reg [S_COUNT*USER_WIDTH-1:0]            s_axis_tuser_int;
    reg [M_COUNT*DATA_WIDTH-1:0]            m_axis_tdata_int;
    reg [M_COUNT*KEEP_WIDTH-1:0]            m_axis_tkeep_int;
    reg [M_COUNT-1:0]                       m_axis_tlast_int;
    reg [M_COUNT*M_ID_WIDTH-1:0]            m_axis_tid_int;
    reg [M_COUNT*M_DEST_WIDTH-1:0]          m_axis_tdest_int;
    reg [M_COUNT*USER_WIDTH-1:0]            m_axis_tuser_int;
    reg [S_COUNT-1:0]                       arb_grant;
    reg [S_COUNT-1:0]                       req;
    reg [S_COUNT-1:0]                       grant;
    reg [1:0]                               state;
    reg [1:0]                               next_state;
    reg [$clog2(S_COUNT)-1:0]               round_robin_ptr;

    /*
     * State definitions
     */
    localparam IDLE = 2'b00;
    localparam TRANSFER = 2'b01;

    /*
     * Request generation
     */
    always @(*) begin
        req = s_axis_tvalid;
    end

    /*
     * Round-robin arbiter
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round_robin_ptr <= 0;
            arb_grant <= 0;
        end else begin
            if (|req) begin
                case (state)
                    IDLE: begin
                        round_robin_ptr <= round_robin_ptr + 1;
                        if (req[round_robin_ptr]) begin
                            arb_grant <= 1 << round_robin_ptr;
                            next_state <= TRANSFER;
                        end
                    end
                    TRANSFER: begin
                        if (grant[round_robin_ptr] & s_axis_tlast[round_robin_ptr]) begin
                            arb_grant <= 0;
                            next_state <= IDLE;
                        end
                    end
                endcase
            end else begin
                arb_grant <= 0;
                next_state <= IDLE;
            end
        end
    end

    /*
     * Grant assignment
     */
    always @(*) begin
        grant = arb_grant & req;
    end

    /*
     * State transition
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    /*
     * Input data sampling
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tdata_int <= 0;
            s_axis_tkeep_int <= 0;
            s_axis_tlast_int <= 0;
            s_axis_tid_int <= 0;
            s_axis_tdest_int <= 0;
            s_axis_tuser_int <= 0;
        end else if (|req) begin
            s_axis_tdata_int <= s_axis_tdata;
            s_axis_tkeep_int <= s_axis_tkeep;
            s_axis_tlast_int <= s_axis_tlast;
            s_axis_tid_int <= s_axis_tid;
            s_axis_tdest_int <= s_axis_tdest;
            s_axis_tuser_int <= s_axis_tuser;
        end
    end

    /*
     * Output data routing
     */
    always @(*) begin
        m_axis_tdata_int = 0;
        m_axis_tkeep_int = 0;
        m_axis_tvalid_int = 0;
        m_axis_tlast_int = 0;
        m_axis_tid_int = 0;
        m_axis_tdest_int = 0;
        m_axis_tuser_int = 0;

        for (integer i = 0; i < S_COUNT; i = i + 1) begin
            if (grant[i]) begin
                integer m_dest = s_axis_tdest_int[i*S_DEST_WIDTH +: M_DEST_WIDTH];
                integer m_index = s_axis_tdest_int[i*S_DEST_WIDTH + M_DEST_WIDTH +: $clog2(M_COUNT)];
                integer m_offset = m_index * DATA_WIDTH;
                integer k_offset = m_index * KEEP_WIDTH;
                integer i_offset = i * DATA_WIDTH;
                integer j_offset = i * KEEP_WIDTH;

                m_axis_tdata_int[m_offset +: DATA_WIDTH] = s_axis_tdata_int[i_offset +: DATA_WIDTH];
                m_axis_tkeep_int[k_offset +: KEEP_WIDTH] = s_axis_tkeep_int[j_offset +: KEEP_WIDTH];
                m_axis_tvalid_int[m_index] = 1;
                m_axis_tlast_int[m_index] = s_axis_tlast_int[i];
                m_axis_tid_int[m_index * M_ID_WIDTH +: M_ID_WIDTH] = s_axis_tid_int[i * S_ID_WIDTH +: S_ID_WIDTH];
                m_axis_tdest_int[m_index * M_DEST_WIDTH +: M_DEST_WIDTH] = s_axis_tdest_int[i * S_DEST_WIDTH +: M_DEST_WIDTH];
                m_axis_tuser_int[m_index * USER_WIDTH +: USER_WIDTH] = s_axis_tuser_int[i * USER_WIDTH +: USER_WIDTH];
            end
        end
    end

    /*
     * Output ready signals
     */
    always @(*) begin
        s_axis_tready_int = 0;
        for (integer i = 0; i < S_COUNT; i = i + 1) begin
            integer m_dest = s_axis_tdest_int[i*S_DEST_WIDTH +: M_DEST_WIDTH];
            integer m_index = s_axis_tdest_int[i*S_DEST_WIDTH + M_DEST_WIDTH +: $clog2(M_COUNT)];
            if (grant[i] && m_axis_tready[m_index]) begin
                s_axis_tready_int[i] = 1;
            end
        end
    end

    /*
     * Drive outputs
     */
    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tdata = m_axis_tdata_int;
    assign m_axis_tkeep = m_axis_tkeep_int;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tlast = m_axis_tlast_int;
    assign m_axis_tid = m_axis_tid_int;
    assign m_axis_tdest = m_axis_tdest_int;
    assign m_axis_tuser = m_axis_tuser_int;

endmodule
