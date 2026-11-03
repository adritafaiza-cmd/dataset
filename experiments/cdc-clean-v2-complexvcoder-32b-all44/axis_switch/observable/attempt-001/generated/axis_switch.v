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
    wire [S_COUNT-1:0]                      grant;
    wire [M_COUNT*DATA_WIDTH-1:0]           m_axis_tdata_out;
    wire [M_COUNT*KEEP_WIDTH-1:0]           m_axis_tkeep_out;
    wire [M_COUNT-1:0]                      m_axis_tvalid_out;
    wire [M_COUNT-1:0]                      m_axis_tlast_out;
    wire [M_COUNT*M_ID_WIDTH-1:0]           m_axis_tid_out;
    wire [M_COUNT*M_DEST_WIDTH-1:0]         m_axis_tdest_out;
    wire [M_COUNT*USER_WIDTH-1:0]           m_axis_tuser_out;

    /*
     * Instantiate the arbiter
     */
    arbiter #(
        .S_COUNT(S_COUNT),
        .M_COUNT(M_COUNT)
    ) arbiter_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_tvalid(s_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .grant(grant)
    );

    /*
     * Connect s_axis_tready to grant
     */
    assign s_axis_tready = grant;

    /*
     * Route the selected input stream to the appropriate output stream
     */
    genvar i, j;
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_outputs
            reg [DATA_WIDTH-1:0]            m_axis_tdata_reg;
            reg [KEEP_WIDTH-1:0]            m_axis_tkeep_reg;
            reg                             m_axis_tvalid_reg;
            reg                             m_axis_tlast_reg;
            reg [M_ID_WIDTH-1:0]            m_axis_tid_reg;
            reg [M_DEST_WIDTH-1:0]          m_axis_tdest_reg;
            reg [USER_WIDTH-1:0]            m_axis_tuser_reg;

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    m_axis_tdata_reg <= 0;
                    m_axis_tkeep_reg <= 0;
                    m_axis_tvalid_reg <= 0;
                    m_axis_tlast_reg <= 0;
                    m_axis_tid_reg <= 0;
                    m_axis_tdest_reg <= 0;
                    m_axis_tuser_reg <= 0;
                end else begin
                    for (j = 0; j < S_COUNT; j = j + 1) begin
                        if (grant[j] && s_axis_tvalid[j] && (s_axis_tdest[j*S_DEST_WIDTH +: M_DEST_WIDTH] == i)) begin
                            m_axis_tdata_reg <= s_axis_tdata[j*DATA_WIDTH +: DATA_WIDTH];
                            m_axis_tkeep_reg <= s_axis_tkeep[j*KEEP_WIDTH +: KEEP_WIDTH];
                            m_axis_tvalid_reg <= s_axis_tvalid[j];
                            m_axis_tlast_reg <= s_axis_tlast[j];
                            m_axis_tid_reg <= s_axis_tid[j*S_ID_WIDTH +: M_ID_WIDTH];
                            m_axis_tdest_reg <= s_axis_tdest[j*S_DEST_WIDTH +: M_DEST_WIDTH];
                            m_axis_tuser_reg <= s_axis_tuser[j*USER_WIDTH +: USER_WIDTH];
                        end
                    end
                    if (m_axis_tvalid_reg && !m_axis_tready[i]) begin
                        m_axis_tvalid_reg <= m_axis_tvalid_reg;
                    end else begin
                        m_axis_tvalid_reg <= 0;
                    end
                end
            end

            assign m_axis_tdata_out[i*DATA_WIDTH +: DATA_WIDTH] = m_axis_tdata_reg;
            assign m_axis_tkeep_out[i*KEEP_WIDTH +: KEEP_WIDTH] = m_axis_tkeep_reg;
            assign m_axis_tvalid_out[i] = m_axis_tvalid_reg;
            assign m_axis_tlast_out[i] = m_axis_tlast_reg;
            assign m_axis_tid_out[i*M_ID_WIDTH +: M_ID_WIDTH] = m_axis_tid_reg;
            assign m_axis_tdest_out[i*M_DEST_WIDTH +: M_DEST_WIDTH] = m_axis_tdest_reg;
            assign m_axis_tuser_out[i*USER_WIDTH +: USER_WIDTH] = m_axis_tuser_reg;
        end
    endgenerate

    /*
     * Connect the output signals
     */
    assign m_axis_tdata = m_axis_tdata_out;
    assign m_axis_tkeep = m_axis_tkeep_out;
    assign m_axis_tvalid = m_axis_tvalid_out;
    assign m_axis_tlast = m_axis_tlast_out;
    assign m_axis_tid = m_axis_tid_out;
    assign m_axis_tdest = m_axis_tdest_out;
    assign m_axis_tuser = m_axis_tuser_out;

endmodule

module arbiter #
(
    parameter S_COUNT = 4,
    parameter M_COUNT = 4
)
(
    input  wire                             clk,
    input  wire                             rst,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    input  wire [M_COUNT-1:0]               m_axis_tready,
    output wire [S_COUNT-1:0]               grant
);

    /*
     * Internal signals
     */
    reg [S_COUNT-1:0]                       request;
    reg [S_COUNT-1:0]                       grant_reg;
    reg [$clog2(S_COUNT)-1:0]               grant_ptr;

    /*
     * Generate requests based on s_axis_tvalid
     */
    assign request = s_axis_tvalid;

    /*
     * Round-robin arbiter logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= 0;
            grant_ptr <= 0;
        end else begin
            if (|request) begin
                reg [S_COUNT-1:0] next_grant;
                reg [$clog2(S_COUNT)-1:0] next_ptr;

                next_grant = 0;
                next_ptr = grant_ptr;

                for (int i = 0; i < S_COUNT; i = i + 1) begin
                    if (request[next_ptr] && !grant_reg[next_ptr]) begin
                        next_grant[next_ptr] = 1;
                        break;
                    end
                    next_ptr = (next_ptr + 1) % S_COUNT;
                end

                grant_reg <= next_grant;
                grant_ptr <= next_ptr;
            end else begin
                grant_reg <= 0;
            end
        end
    end

    assign grant = grant_reg;

endmodule
