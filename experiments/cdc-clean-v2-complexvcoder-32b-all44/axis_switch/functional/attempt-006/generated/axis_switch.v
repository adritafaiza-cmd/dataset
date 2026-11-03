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

    wire [S_COUNT-1:0] [DATA_WIDTH-1:0]   s_axis_tdata_vec;
    wire [S_COUNT-1:0] [KEEP_WIDTH-1:0]   s_axis_tkeep_vec;
    wire [S_COUNT-1:0]                    s_axis_tvalid_vec;
    wire [S_COUNT-1:0]                    s_axis_tready_vec;
    wire [S_COUNT-1:0]                    s_axis_tlast_vec;
    wire [S_COUNT-1:0] [S_ID_WIDTH-1:0]   s_axis_tid_vec;
    wire [S_COUNT-1:0] [S_DEST_WIDTH-1:0] s_axis_tdest_vec;
    wire [S_COUNT-1:0] [USER_WIDTH-1:0]   s_axis_tuser_vec;

    wire [M_COUNT-1:0] [DATA_WIDTH-1:0]   m_axis_tdata_vec;
    wire [M_COUNT-1:0] [KEEP_WIDTH-1:0]   m_axis_tkeep_vec;
    wire [M_COUNT-1:0]                    m_axis_tvalid_vec;
    wire [M_COUNT-1:0]                    m_axis_tready_vec;
    wire [M_COUNT-1:0]                    m_axis_tlast_vec;
    wire [M_COUNT-1:0] [M_ID_WIDTH-1:0]   m_axis_tid_vec;
    wire [M_COUNT-1:0] [M_DEST_WIDTH-1:0] m_axis_tdest_vec;
    wire [M_COUNT-1:0] [USER_WIDTH-1:0]   m_axis_tuser_vec;

    genvar i, j;
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_s_axis_vec
            assign s_axis_tdata_vec[i] = s_axis_tdata[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];
            assign s_axis_tkeep_vec[i] = s_axis_tkeep[(i+1)*KEEP_WIDTH-1:i*KEEP_WIDTH];
            assign s_axis_tvalid_vec[i] = s_axis_tvalid[i];
            assign s_axis_tlast_vec[i] = s_axis_tlast[i];
            assign s_axis_tid_vec[i] = s_axis_tid[(i+1)*S_ID_WIDTH-1:i*S_ID_WIDTH];
            assign s_axis_tdest_vec[i] = s_axis_tdest[(i+1)*S_DEST_WIDTH-1:i*S_DEST_WIDTH];
            assign s_axis_tuser_vec[i] = s_axis_tuser[(i+1)*USER_WIDTH-1:i*USER_WIDTH];
        end
        for (j = 0; j < M_COUNT; j = j + 1) begin : gen_m_axis_vec
            assign m_axis_tdata[(j+1)*DATA_WIDTH-1:j*DATA_WIDTH] = m_axis_tdata_vec[j];
            assign m_axis_tkeep[(j+1)*KEEP_WIDTH-1:j*KEEP_WIDTH] = m_axis_tkeep_vec[j];
            assign m_axis_tvalid[j] = m_axis_tvalid_vec[j];
            assign m_axis_tlast[j] = m_axis_tlast_vec[j];
            assign m_axis_tid[(j+1)*M_ID_WIDTH-1:j*M_ID_WIDTH] = m_axis_tid_vec[j];
            assign m_axis_tdest[(j+1)*M_DEST_WIDTH-1:j*M_DEST_WIDTH] = m_axis_tdest_vec[j];
            assign m_axis_tuser[(j+1)*USER_WIDTH-1:j*USER_WIDTH] = m_axis_tuser_vec[j];
        end
    endgenerate

    reg [S_COUNT-1:0] [S_DEST_WIDTH-1:0] dest_reg;
    reg [S_COUNT-1:0] [M_COUNT-1:0] req;
    reg [M_COUNT-1:0] [S_COUNT-1:0] grant;
    reg [M_COUNT-1:0] [S_COUNT-1:0] grant_d;

    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_req
            assign req[i] = {M_COUNT{s_axis_tvalid_vec[i] & M_CONNECT[i]}};
        end
    endgenerate

    genvar k;
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin : gen_arb
            for (j = 0; j < M_COUNT; j = j + 1) begin : gen_rr_arb
                rr_arbiter #(.S_COUNT(S_COUNT)) rr_arbiter_inst (
                    .clk(clk),
                    .rst(rst),
                    .req(req[j]),
                    .grant(grant[j]),
                    .grant_d(grant_d[j])
                );
            end
        end else begin : gen_priority_arb
            for (j = 0; j < M_COUNT; j = j + 1) begin : gen_prio_arb
                priority_arbiter #(.S_COUNT(S_COUNT)) priority_arbiter_inst (
                    .clk(clk),
                    .rst(rst),
                    .req(req[j]),
                    .grant(grant[j]),
                    .grant_d(grant_d[j])
                );
            end
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_d <= {M_COUNT{S_COUNT{1'b0}}};
        end else begin
            grant_d <= grant;
        end
    end

    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_s_axis_tready
            assign s_axis_tready[i] = grant[dest_reg[i]][i];
        end
    endgenerate

    generate
        for (j = 0; j < M_COUNT; j = j + 1) begin : gen_m_axis_assign
            reg [S_COUNT-1:0] [DATA_WIDTH-1:0]   data_reg;
            reg [S_COUNT-1:0] [KEEP_WIDTH-1:0]   keep_reg;
            reg [S_COUNT-1:0]                    valid_reg;
            reg [S_COUNT-1:0]                    last_reg;
            reg [S_COUNT-1:0] [S_ID_WIDTH-1:0]   tid_reg;
            reg [S_COUNT-1:0] [USER_WIDTH-1:0]   user_reg;

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    data_reg  <= {S_COUNT{DATA_WIDTH{1'b0}}};
                    keep_reg  <= {S_COUNT{KEEP_WIDTH{1'b0}}};
                    valid_reg <= {S_COUNT{1'b0}};
                    last_reg  <= {S_COUNT{1'b0}};
                    tid_reg   <= {S_COUNT{S_ID_WIDTH{1'b0}}};
                    user_reg  <= {S_COUNT{USER_WIDTH{1'b0}}};
                end else begin
                    for (k = 0; k < S_COUNT; k = k + 1) begin
                        if (grant[j][k]) begin
                            data_reg[k]  <= s_axis_tdata_vec[k];
                            keep_reg[k]  <= s_axis_tkeep_vec[k];
                            valid_reg[k] <= s_axis_tvalid_vec[k];
                            last_reg[k]  <= s_axis_tlast_vec[k];
                            tid_reg[k]   <= s_axis_tid_vec[k];
                            user_reg[k]  <= s_axis_tuser_vec[k];
                        end
                    end
                end
            end

            reg [S_COUNT-1:0] [M_ID_WIDTH-1:0] tid_m;
            reg [S_COUNT-1:0] [M_DEST_WIDTH-1:0] dest_m;

            generate
                for (i = 0; i < S_COUNT; i = i + 1) begin : gen_tid_dest
                    assign tid_m[i] = {tid_reg[i], i[S_ID_WIDTH-1:0]};
                    assign dest_m[i] = s_axis_tdest_vec[i][M_DEST_WIDTH-1:0];
                end
            endgenerate

            reg [S_COUNT-1:0] [DATA_WIDTH-1:0]   data_sel;
            reg [S_COUNT-1:0] [KEEP_WIDTH-1:0]   keep_sel;
            reg [S_COUNT-1:0]                    valid_sel;
            reg [S_COUNT-1:0]                    last_sel;
            reg [S_COUNT-1:0] [M_ID_WIDTH-1:0]   tid_sel;
            reg [S_COUNT-1:0] [USER_WIDTH-1:0]   user_sel;

            generate
                for (i = 0; i < S_COUNT; i = i + 1) begin : gen_sel
                    assign data_sel[i]  = grant_d[j][i] ? data_reg[i] : {DATA_WIDTH{1'b0}};
                    assign keep_sel[i]  = grant_d[j][i] ? keep_reg[i] : {KEEP_WIDTH{1'b0}};
                    assign valid_sel[i] = grant_d[j][i] ? valid_reg[i] : 1'b0;
                    assign last_sel[i]  = grant_d[j][i] ? last_reg[i] : 1'b0;
                    assign tid_sel[i]   = grant_d[j][i] ? tid_m[i] : {M_ID_WIDTH{1'b0}};
                    assign user_sel[i]  = grant_d[j][i] ? user_reg[i] : {USER_WIDTH{1'b0}};
                end
            endgenerate

            reg [DATA_WIDTH-1:0]   data_out;
            reg [KEEP_WIDTH-1:0]   keep_out;
            reg                    valid_out;
            reg                    last_out;
            reg [M_ID_WIDTH-1:0]   tid_out;
            reg [USER_WIDTH-1:0]   user_out;

            priority_encoder #(.WIDTH(S_COUNT)) priority_encoder_inst (
                .in(valid_sel),
                .out(valid_out),
                .addr()
            );

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    data_out  <= {DATA_WIDTH{1'b0}};
                    keep_out  <= {KEEP_WIDTH{1'b0}};
                    valid_out <= 1'b0;
                    last_out  <= 1'b0;
                    tid_out   <= {M_ID_WIDTH{1'b0}};
                    user_out  <= {USER_WIDTH{1'b0}};
                end else if (valid_out) begin
                    data_out  <= data_sel[valid_out];
                    keep_out  <= keep_sel[valid_out];
                    valid_out <= valid_sel[valid_out];
                    last_out  <= last_sel[valid_out];
                    tid_out   <= tid_sel[valid_out];
                    user_out  <= user_sel[valid_out];
                end
            end

            assign m_axis_tdata_vec[j] = data_out;
            assign m_axis_tkeep_vec[j] = keep_out;
            assign m_axis_tvalid_vec[j] = valid_out;
            assign m_axis_tlast_vec[j] = last_out;
            assign m_axis_tid_vec[j] = tid_out;
            assign m_axis_tdest_vec[j] = dest_m[valid_out];
            assign m_axis_tuser_vec[j] = user_out;
        end
    endgenerate

endmodule

module rr_arbiter #
(
    parameter S_COUNT = 4
)
(
    input  wire                 clk,
    input  wire                 rst,
    input  wire [S_COUNT-1:0]   req,
    output wire [S_COUNT-1:0]   grant,
    output wire [S_COUNT-1:0]   grant_d
);

    reg [S_COUNT-1:0] grant_reg;
    reg [S_COUNT-1:0] grant_d_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= {S_COUNT{1'b0}};
            grant_d_reg <= {S_COUNT{1'b0}};
        end else begin
            grant_reg <= {grant_reg[S_COUNT-2:0], grant_reg[S_COUNT-1]};
            grant_d_reg <= grant_reg;
        end
    end

    assign grant = grant_reg & req;
    assign grant_d = grant_d_reg;

endmodule

module priority_arbiter #
(
    parameter S_COUNT = 4
)
(
    input  wire                 clk,
    input  wire                 rst,
    input  wire [S_COUNT-1:0]   req,
    output wire [S_COUNT-1:0]   grant,
    output wire [S_COUNT-1:0]   grant_d
);

    reg [S_COUNT-1:0] grant_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= {S_COUNT{1'b0}};
        end else begin
            grant_reg <= req;
        end
    end

    assign grant = grant_reg & req;
    assign grant_d = grant_reg;

endmodule

module priority_encoder #
(
    parameter WIDTH = 4
)
(
    input  wire [WIDTH-1:0]   in,
    output wire [WIDTH-1:0]   out,
    output wire [$clog2(WIDTH):0] addr
);

    generate
        if (WIDTH == 1) begin : gen_width_1
            assign out = in;
            assign addr = in;
        end else begin : gen_width_gt_1
            wire [WIDTH/2-1:0] in_low;
            wire [WIDTH/2-1:0] in_high;
            wire [WIDTH/2-1:0] out_low;
            wire [WIDTH/2-1:0] out_high;
            wire [$clog2(WIDTH/2):0] addr_low;
            wire [$clog2(WIDTH/2):0] addr_high;

            assign in_low = in[WIDTH/2-1:0];
            assign in_high = in[WIDTH-1:WIDTH/2];

            priority_encoder #(.WIDTH(WIDTH/2)) priority_encoder_low_inst (
                .in(in_low),
                .out(out_low),
                .addr(addr_low)
            );

            priority_encoder #(.WIDTH(WIDTH/2)) priority_encoder_high_inst (
                .in(in_high),
                .out(out_high),
                .addr(addr_high)
            );

            assign out = {out_high, out_low};
            assign addr = in_high ? {1'b1, addr_high} : {1'b0, addr_low};
        end
    endgenerate

endmodule
