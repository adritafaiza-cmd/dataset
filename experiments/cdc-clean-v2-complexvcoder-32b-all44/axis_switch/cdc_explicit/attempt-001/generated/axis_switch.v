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

    wire [S_COUNT-1:0] arbiter_request;
    wire [S_COUNT-1:0] arbiter_grant;
    wire [$clog2(S_COUNT)-1:0] arbiter_winner;

    wire [DATA_WIDTH-1:0] data_selector_data_out;
    wire [KEEP_WIDTH-1:0] data_selector_tkeep_out;
    wire data_selector_tlast_out;
    wire [M_ID_WIDTH-1:0] data_selector_tid_out;
    wire [M_DEST_WIDTH-1:0] data_selector_tdest_out;
    wire [USER_WIDTH-1:0] data_selector_tuser_out;

    // Arbiter instance
    arbiter #(
        .S_COUNT(S_COUNT)
    ) arbiter_inst (
        .clk(clk),
        .rst(rst),
        .request(arbiter_request),
        .grant(arbiter_grant),
        .winner(arbiter_winner)
    );

    // Data Selector instance
    data_selector #(
        .S_COUNT(S_COUNT),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .S_ID_WIDTH(S_ID_WIDTH),
        .M_ID_WIDTH(M_ID_WIDTH),
        .M_DEST_WIDTH(M_DEST_WIDTH),
        .S_DEST_WIDTH(S_DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH)
    ) data_selector_inst (
        .sel(arbiter_winner),
        .data_in(s_axis_tdata),
        .tkeep_in(s_axis_tkeep),
        .tlast_in(s_axis_tlast),
        .tid_in(s_axis_tid),
        .tdest_in(s_axis_tdest),
        .tuser_in(s_axis_tuser),
        .data_out(data_selector_data_out),
        .tkeep_out(data_selector_tkeep_out),
        .tlast_out(data_selector_tlast_out),
        .tid_out(data_selector_tid_out),
        .tdest_out(data_selector_tdest_out),
        .tuser_out(data_selector_tuser_out)
    );

    // Handshake instance
    handshake #(
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .M_ID_WIDTH(M_ID_WIDTH),
        .M_DEST_WIDTH(M_DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH)
    ) handshake_inst (
        .clk(clk),
        .rst(rst),
        .grant(arbiter_grant),
        .data_in(data_selector_data_out),
        .tkeep_in(data_selector_tkeep_out),
        .tlast_in(data_selector_tlast_out),
        .tid_in(data_selector_tid_out),
        .tdest_in(data_selector_tdest_out),
        .tuser_in(data_selector_tuser_out),
        .tready_in(m_axis_tready),
        .data_out(m_axis_tdata),
        .tkeep_out(m_axis_tkeep),
        .tvalid_out(m_axis_tvalid),
        .tlast_out(m_axis_tlast),
        .tid_out(m_axis_tid),
        .tdest_out(m_axis_tdest),
        .tuser_out(m_axis_tuser)
    );

    // Generate request signals for the arbiter
    genvar i;
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_request
            assign arbiter_request[i] = s_axis_tvalid[i];
        end
    endgenerate

    // Generate s_axis_tready signals based on arbiter grant
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_ready
            assign s_axis_tready[i] = arbiter_grant[i];
        end
    endgenerate

endmodule

module arbiter #
(
    parameter S_COUNT = 4
)
(
    input  wire                             clk,
    input  wire                             rst,
    input  wire [S_COUNT-1:0]               request,
    output wire [S_COUNT-1:0]               grant,
    output wire [$clog2(S_COUNT)-1:0]       winner
);

    reg [$clog2(S_COUNT)-1:0] current;
    reg [S_COUNT-1:0] next_grant;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current <= 0;
            next_grant <= 0;
        end else begin
            if (|request) begin
                next_grant <= request;
                current <= (next_grant[current]) ? current : (current + 1);
            end else begin
                next_grant <= 0;
            end
        end
    end

    assign winner = current;
    assign grant = next_grant;

endmodule

module data_selector #
(
    parameter S_COUNT = 4,
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter S_ID_WIDTH = 8,
    parameter M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
    parameter M_DEST_WIDTH = 1,
    parameter S_DEST_WIDTH = M_DEST_WIDTH+$clog2(M_COUNT),
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1
)
(
    input  wire [$clog2(S_COUNT)-1:0]       sel,
    input  wire [S_COUNT*DATA_WIDTH-1:0]    data_in,
    input  wire [S_COUNT*KEEP_WIDTH-1:0]    tkeep_in,
    input  wire [S_COUNT-1:0]               tlast_in,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    tid_in,
    input  wire [S_COUNT*S_DEST_WIDTH-1:0]  tdest_in,
    input  wire [S_COUNT*USER_WIDTH-1:0]    tuser_in,
    output wire [DATA_WIDTH-1:0]            data_out,
    output wire [KEEP_WIDTH-1:0]            tkeep_out,
    output wire                             tlast_out,
    output wire [M_ID_WIDTH-1:0]            tid_out,
    output wire [M_DEST_WIDTH-1:0]          tdest_out,
    output wire [USER_WIDTH-1:0]            tuser_out
);

    assign data_out = data_in[sel*DATA_WIDTH +: DATA_WIDTH];
    assign tkeep_out = tkeep_in[sel*KEEP_WIDTH +: KEEP_WIDTH];
    assign tlast_out = tlast_in[sel];
    assign tid_out = tid_in[sel*S_ID_WIDTH +: S_ID_WIDTH];
    assign tdest_out = tdest_in[sel*S_DEST_WIDTH +: S_DEST_WIDTH];
    assign tuser_out = tuser_in[sel*USER_WIDTH +: USER_WIDTH];

endmodule

module handshake #
(
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
    parameter M_DEST_WIDTH = 1,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1
)
(
    input  wire                             clk,
    input  wire                             rst,
    input  wire [S_COUNT-1:0]               grant,
    input  wire [DATA_WIDTH-1:0]            data_in,
    input  wire [KEEP_WIDTH-1:0]            tkeep_in,
    input  wire                             tlast_in,
    input  wire [M_ID_WIDTH-1:0]            tid_in,
    input  wire [M_DEST_WIDTH-1:0]          tdest_in,
    input  wire [USER_WIDTH-1:0]            tuser_in,
    input  wire [M_COUNT-1:0]               tready_in,
    output wire [DATA_WIDTH-1:0]            data_out,
    output wire [KEEP_WIDTH-1:0]            tkeep_out,
    output wire                             tvalid_out,
    output wire                             tlast_out,
    output wire [M_ID_WIDTH-1:0]            tid_out,
    output wire [M_DEST_WIDTH-1:0]          tdest_out,
    output wire [USER_WIDTH-1:0]            tuser_out
);

    reg [DATA_WIDTH-1:0] data_reg;
    reg [KEEP_WIDTH-1:0] tkeep_reg;
    reg tlast_reg;
    reg [M_ID_WIDTH-1:0] tid_reg;
    reg [M_DEST_WIDTH-1:0] tdest_reg;
    reg [USER_WIDTH-1:0] tuser_reg;
    reg tvalid_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_reg <= 0;
            tkeep_reg <= 0;
            tlast_reg <= 0;
            tid_reg <= 0;
            tdest_reg <= 0;
            tuser_reg <= 0;
            tvalid_reg <= 0;
        end else begin
            if (tready_in[0] && tvalid_reg) begin
                tvalid_reg <= 0;
            end else if (|grant) begin
                data_reg <= data_in;
                tkeep_reg <= tkeep_in;
                tlast_reg <= tlast_in;
                tid_reg <= tid_in;
                tdest_reg <= tdest_in;
                tuser_reg <= tuser_in;
                tvalid_reg <= 1;
            end
        end
    end

    assign data_out = data_reg;
    assign tkeep_out = tkeep_reg;
    assign tlast_out = tlast_reg;
    assign tid_out = tid_reg;
    assign tdest_out = tdest_reg;
    assign tuser_out = tuser_reg;
    assign tvalid_out = tvalid_reg;

endmodule
