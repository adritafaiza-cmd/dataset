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

    // Internal signals
    reg [S_COUNT-1:0]                       s_axis_tready_int;
    reg [M_COUNT-1:0]                       m_axis_tvalid_int;
    reg [M_COUNT-1:0]                       m_axis_tready_int;
    reg [S_COUNT-1:0]                       s_axis_tvalid_ff;
    reg [S_COUNT-1:0]                       s_axis_tready_ff;
    reg [S_COUNT-1:0] [DATA_WIDTH-1:0]      s_axis_tdata_ff;
    reg [S_COUNT-1:0] [KEEP_WIDTH-1:0]      s_axis_tkeep_ff;
    reg [S_COUNT-1:0]                       s_axis_tlast_ff;
    reg [S_COUNT-1:0] [S_ID_WIDTH-1:0]      s_axis_tid_ff;
    reg [S_COUNT-1:0] [S_DEST_WIDTH-1:0]    s_axis_tdest_ff;
    reg [S_COUNT-1:0] [USER_WIDTH-1:0]      s_axis_tuser_ff;
    reg [M_COUNT-1:0] [DATA_WIDTH-1:0]      m_axis_tdata_ff;
    reg [M_COUNT-1:0] [KEEP_WIDTH-1:0]      m_axis_tkeep_ff;
    reg [M_COUNT-1:0]                       m_axis_tlast_ff;
    reg [M_COUNT-1:0] [M_ID_WIDTH-1:0]      m_axis_tid_ff;
    reg [M_COUNT-1:0] [M_DEST_WIDTH-1:0]    m_axis_tdest_ff;
    reg [M_COUNT-1:0] [USER_WIDTH-1:0]      m_axis_tuser_ff;
    reg [S_COUNT-1:0]                       req;
    reg [S_COUNT-1:0]                       grant;

    // Register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tvalid_ff <= 0;
            s_axis_tdata_ff <= 0;
            s_axis_tkeep_ff <= 0;
            s_axis_tlast_ff <= 0;
            s_axis_tid_ff <= 0;
            s_axis_tdest_ff <= 0;
            s_axis_tuser_ff <= 0;
        end else begin
            s_axis_tvalid_ff <= s_axis_tvalid;
            s_axis_tdata_ff <= s_axis_tdata;
            s_axis_tkeep_ff <= s_axis_tkeep;
            s_axis_tlast_ff <= s_axis_tlast;
            s_axis_tid_ff <= s_axis_tid;
            s_axis_tdest_ff <= s_axis_tdest;
            s_axis_tuser_ff <= s_axis_tuser;
        end
    end

    // Generate requests
    always @(*) begin
        for (int i = 0; i < S_COUNT; i = i + 1) begin
            req[i] = s_axis_tvalid_ff[i] & s_axis_tready_int[i];
        end
    end

    // Round-robin arbiter
    round_robin_arbiter #(
        .NUM_REQ(S_COUNT),
        .NUM_GRANT(S_COUNT)
    ) u_round_robin_arbiter (
        .clk(clk),
        .rst(rst),
        .req(req),
        .grant(grant)
    );

    // Register outputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tvalid_int <= 0;
            m_axis_tdata_ff <= 0;
            m_axis_tkeep_ff <= 0;
            m_axis_tlast_ff <= 0;
            m_axis_tid_ff <= 0;
            m_axis_tdest_ff <= 0;
            m_axis_tuser_ff <= 0;
        end else begin
            for (int i = 0; i < M_COUNT; i = i + 1) begin
                m_axis_tvalid_int[i] <= 0;
                m_axis_tdata_ff[i] <= 0;
                m_axis_tkeep_ff[i] <= 0;
                m_axis_tlast_ff[i] <= 0;
                m_axis_tid_ff[i] <= 0;
                m_axis_tdest_ff[i] <= 0;
                m_axis_tuser_ff[i] <= 0;
                for (int j = 0; j < S_COUNT; j = j + 1) begin
                    if (grant[j] && (s_axis_tdest_ff[j] >> M_DEST_WIDTH) == i) begin
                        m_axis_tvalid_int[i] <= 1;
                        m_axis_tdata_ff[i] <= s_axis_tdata_ff[j];
                        m_axis_tkeep_ff[i] <= s_axis_tkeep_ff[j];
                        m_axis_tlast_ff[i] <= s_axis_tlast_ff[j];
                        m_axis_tid_ff[i] <= s_axis_tid_ff[j];
                        m_axis_tdest_ff[i] <= s_axis_tdest_ff[j][M_DEST_WIDTH-1:0];
                        m_axis_tuser_ff[i] <= s_axis_tuser_ff[j];
                    end
                end
            end
        end
    end

    // Output assignment
    always @(*) begin
        for (int i = 0; i < S_COUNT; i = i + 1) begin
            s_axis_tready_int[i] = 0;
            for (int j = 0; j < M_COUNT; j = j + 1) begin
                if (grant[i] && (s_axis_tdest_ff[i] >> M_DEST_WIDTH) == j) begin
                    s_axis_tready_int[i] = m_axis_tready[j];
                end
            end
        end
    end

    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tdata = m_axis_tdata_ff;
    assign m_axis_tkeep = m_axis_tkeep_ff;
    assign m_axis_tlast = m_axis_tlast_ff;
    assign m_axis_tid = m_axis_tid_ff;
    assign m_axis_tdest = m_axis_tdest_ff;
    assign m_axis_tuser = m_axis_tuser_ff;

endmodule

module round_robin_arbiter #
(
    parameter NUM_REQ = 4,
    parameter NUM_GRANT = 4
)
(
    input  wire                             clk,
    input  wire                             rst,
    input  wire [NUM_REQ-1:0]               req,
    output reg  [NUM_GRANT-1:0]             grant
);

    reg [$clog2(NUM_REQ)-1:0]               grant_ptr;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_ptr <= 0;
            grant <= 0;
        end else begin
            for (int i = 0; i < NUM_REQ; i = i + 1) begin
                if (req[i]) begin
                    grant <= 0;
                    grant[i] <= 1;
                    grant_ptr <= i;
                    break;
                end
            end
            if (!|req) begin
                grant <= 0;
                grant_ptr <= grant_ptr + 1;
            end
        end
    end

endmodule
