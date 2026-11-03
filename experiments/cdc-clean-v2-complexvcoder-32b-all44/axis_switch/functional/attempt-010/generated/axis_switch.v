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
    wire [S_COUNT-1:0]                      s_axis_tready_i;
    wire [M_COUNT-1:0]                      m_axis_tvalid_i;
    wire [$clog2(S_COUNT)-1:0]              selected_input;
    wire [S_COUNT-1:0]                      grant;
    wire [S_COUNT-1:0]                      request;
    reg  [$clog2(S_COUNT)-1:0]              round_robin_counter;

    /*
     * Generate request signals based on valid and ready
     */
    genvar i;
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_request
            assign request[i] = s_axis_tvalid[i] & s_axis_tready_i[i];
        end
    endgenerate

    /*
     * Round Robin Arbiter
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round_robin_counter <= 0;
        end else if (|request) begin
            for (int j = 0; j < S_COUNT; j = j + 1) begin
                if (request[(round_robin_counter + j) % S_COUNT]) begin
                    round_robin_counter <= (round_robin_counter + j) % S_COUNT;
                    break;
                end
            end
        end
    end

    /*
     * Grant signals
     */
    always @(*) begin
        grant = 0;
        if (|request) begin
            grant[round_robin_counter] = 1;
        end
    end

    /*
     * Selected input
     */
    always @(*) begin
        selected_input = 0;
        for (int k = 0; k < S_COUNT; k = k + 1) begin
            if (grant[k]) begin
                selected_input = k;
            end
        end
    end

    /*
     * Output assignments
     */
    genvar j;
    generate
        for (j = 0; j < M_COUNT; j = j + 1) begin : gen_outputs
            reg [DATA_WIDTH-1:0]              m_axis_tdata_reg;
            reg [KEEP_WIDTH-1:0]              m_axis_tkeep_reg;
            reg                               m_axis_tvalid_reg;
            reg                               m_axis_tlast_reg;
            reg [M_ID_WIDTH-1:0]              m_axis_tid_reg;
            reg [M_DEST_WIDTH-1:0]            m_axis_tdest_reg;
            reg [USER_WIDTH-1:0]              m_axis_tuser_reg;

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    m_axis_tdata_reg  <= 0;
                    m_axis_tkeep_reg  <= 0;
                    m_axis_tvalid_reg <= 0;
                    m_axis_tlast_reg  <= 0;
                    m_axis_tid_reg    <= 0;
                    m_axis_tdest_reg  <= 0;
                    m_axis_tuser_reg  <= 0;
                end else if (grant[selected_input] && (s_axis_tdest[selected_input*S_DEST_WIDTH +: M_DEST_WIDTH] == j)) begin
                    m_axis_tdata_reg  <= s_axis_tdata[selected_input*DATA_WIDTH +: DATA_WIDTH];
                    m_axis_tkeep_reg  <= s_axis_tkeep[selected_input*KEEP_WIDTH +: KEEP_WIDTH];
                    m_axis_tvalid_reg <= 1;
                    m_axis_tlast_reg  <= s_axis_tlast[selected_input];
                    m_axis_tid_reg    <= s_axis_tid[selected_input*S_ID_WIDTH +: S_ID_WIDTH];
                    m_axis_tdest_reg  <= s_axis_tdest[selected_input*S_DEST_WIDTH +: M_DEST_WIDTH];
                    m_axis_tuser_reg  <= s_axis_tuser[selected_input*USER_WIDTH +: USER_WIDTH];
                end else if (m_axis_tready[j]) begin
                    m_axis_tvalid_reg <= 0;
                end
            end

            assign m_axis_tdata[j*DATA_WIDTH +: DATA_WIDTH]  = m_axis_tdata_reg;
            assign m_axis_tkeep[j*KEEP_WIDTH +: KEEP_WIDTH]  = m_axis_tkeep_reg;
            assign m_axis_tvalid[j]                          = m_axis_tvalid_reg;
            assign m_axis_tlast[j]                           = m_axis_tlast_reg;
            assign m_axis_tid[j*M_ID_WIDTH +: M_ID_WIDTH]    = m_axis_tid_reg;
            assign m_axis_tdest[j*M_DEST_WIDTH +: M_DEST_WIDTH] = m_axis_tdest_reg;
            assign m_axis_tuser[j*USER_WIDTH +: USER_WIDTH]  = m_axis_tuser_reg;
        end
    endgenerate

    /*
     * Input ready assignments
     */
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_ready
            assign s_axis_tready[i] = s_axis_tready_i[i];
        end
    endgenerate

    /*
     * Input ready generation
     */
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_input_ready
            wire [M_COUNT-1:0] dest_matches;
            assign dest_matches = s_axis_tdest[i*S_DEST_WIDTH +: M_DEST_WIDTH] == (M_COUNT)'(M_CONNECT[i]);

            assign s_axis_tready_i[i] = grant[i] & m_axis_tready[dest_matches];
        end
    endgenerate

endmodule
