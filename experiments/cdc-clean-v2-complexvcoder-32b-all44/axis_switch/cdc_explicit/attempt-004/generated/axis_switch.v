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
    wire [S_COUNT-1:0]                    arb_req;
    wire [S_COUNT-1:0]                    arb_gnt;
    wire [M_COUNT*S_COUNT-1:0]            route_req;
    wire [M_COUNT*S_COUNT-1:0]            route_gnt;

    // Unpack input signals
    wire [S_COUNT-1:0][DATA_WIDTH-1:0]     s_axis_tdata_unpacked;
    wire [S_COUNT-1:0][KEEP_WIDTH-1:0]     s_axis_tkeep_unpacked;
    wire [S_COUNT-1:0][S_ID_WIDTH-1:0]     s_axis_tid_unpacked;
    wire [S_COUNT-1:0][S_DEST_WIDTH-1:0]   s_axis_tdest_unpacked;
    wire [S_COUNT-1:0][USER_WIDTH-1:0]     s_axis_tuser_unpacked;

    // Pack output signals
    wire [M_COUNT-1:0][DATA_WIDTH-1:0]     m_axis_tdata_packed;
    wire [M_COUNT-1:0][KEEP_WIDTH-1:0]     m_axis_tkeep_packed;
    wire [M_COUNT-1:0][M_ID_WIDTH-1:0]     m_axis_tid_packed;
    wire [M_COUNT-1:0][USER_WIDTH-1:0]     m_axis_tuser_packed;
    wire [M_COUNT-1:0]                    m_axis_tlast_packed;

    // Unpack input signals
    genvar i;
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : unpack_inputs
            assign s_axis_tdata_unpacked[i] = s_axis_tdata[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];
            assign s_axis_tkeep_unpacked[i] = s_axis_tkeep[(i+1)*KEEP_WIDTH-1:i*KEEP_WIDTH];
            assign s_axis_tid_unpacked[i]   = s_axis_tid[(i+1)*S_ID_WIDTH-1:i*S_ID_WIDTH];
            assign s_axis_tdest_unpacked[i] = s_axis_tdest[(i+1)*S_DEST_WIDTH-1:i*S_DEST_WIDTH];
            assign s_axis_tuser_unpacked[i] = s_axis_tuser[(i+1)*USER_WIDTH-1:i*USER_WIDTH];
        end
    endgenerate

    // Assign output signals
    genvar j;
    generate
        for (j = 0; j < M_COUNT; j = j + 1) begin : pack_outputs
            assign m_axis_tdata[(j+1)*DATA_WIDTH-1:j*DATA_WIDTH] = m_axis_tdata_packed[j];
            assign m_axis_tkeep[(j+1)*KEEP_WIDTH-1:j*KEEP_WIDTH] = m_axis_tkeep_packed[j];
            assign m_axis_tid[(j+1)*M_ID_WIDTH-1:j*M_ID_WIDTH]   = m_axis_tid_packed[j];
            assign m_axis_tuser[(j+1)*USER_WIDTH-1:j*USER_WIDTH] = m_axis_tuser_packed[j];
            assign m_axis_tlast[j] = m_axis_tlast_packed[j];
        end
    endgenerate

    // Arbitration
    axis_arbiter #(
        .S_COUNT(S_COUNT),
        .M_COUNT(M_COUNT),
        .ARB_TYPE_ROUND_ROBIN(ARB_TYPE_ROUND_ROBIN),
        .ARB_LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
    ) arbiter_inst (
        .clk(clk),
        .rst(rst),
        .req(arb_req),
        .gnt(arb_gnt)
    );

    // Routing
    axis_router #(
        .S_COUNT(S_COUNT),
        .M_COUNT(M_COUNT),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .S_ID_WIDTH(S_ID_WIDTH),
        .M_ID_WIDTH(M_ID_WIDTH),
        .S_DEST_WIDTH(S_DEST_WIDTH),
        .M_DEST_WIDTH(M_DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .M_CONNECT(M_CONNECT)
    ) router_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(s_axis_tdata_unpacked),
        .s_axis_tkeep(s_axis_tkeep_unpacked),
        .s_axis_tvalid(s_axis_tvalid & arb_gnt),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tid(s_axis_tid_unpacked),
        .s_axis_tdest(s_axis_tdest_unpacked),
        .s_axis_tuser(s_axis_tuser_unpacked),
        .m_axis_tdata(m_axis_tdata_packed),
        .m_axis_tkeep(m_axis_tkeep_packed),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast_packed),
        .m_axis_tid(m_axis_tid_packed),
        .m_axis_tdest(m_axis_tdest),
        .m_axis_tuser(m_axis_tuser_packed),
        .req(route_req),
        .gnt(route_gnt)
    );

    // Connect arbitration and routing
    genvar k, l;
    generate
        for (k = 0; k < S_COUNT; k = k + 1) begin : gen_arb_req
            assign arb_req[k] = s_axis_tvalid[k];
        end
        for (l = 0; l < M_COUNT; l = l + 1) begin : gen_route_req
            genvar m;
            generate
                for (m = 0; m < S_COUNT; m = m + 1) begin : gen_route_req_inner
                    assign route_req[l*S_COUNT+m] = arb_gnt[m] & (s_axis_tdest_unpacked[m] == l);
                end
            endgenerate
        end
    endgenerate

    // Generate s_axis_tready signals
    genvar n;
    generate
        for (n = 0; n < S_COUNT; n = n + 1) begin : gen_tready
            assign s_axis_tready[n] = |(route_gnt[n*S_COUNT+:M_COUNT]);
        end
    endgenerate

endmodule

// Arbitration module
module axis_arbiter #(
    parameter S_COUNT = 4,
    parameter M_COUNT = 4,
    parameter ARB_TYPE_ROUND_ROBIN = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
    input  wire                             clk,
    input  wire                             rst,
    input  wire [S_COUNT-1:0]               req,
    output wire [S_COUNT-1:0]               gnt
);

    reg [S_COUNT-1:0]                     gnt_reg;
    reg [S_COUNT-1:0]                     gnt_nxt;
    reg [$clog2(S_COUNT)-1:0]             round_robin_ptr;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            gnt_reg <= {S_COUNT{1'b0}};
            round_robin_ptr <= 0;
        end else begin
            gnt_reg <= gnt_nxt;
            if (|req) begin
                round_robin_ptr <= round_robin_ptr + 1;
            end
        end
    end

    always @(*) begin
        gnt_nxt = {S_COUNT{1'b0}};
        if (|req) begin
            integer i;
            for (i = 0; i < S_COUNT; i = i + 1) begin
                if (req[(round_robin_ptr + i) % S_COUNT]) begin
                    gnt_nxt[(round_robin_ptr + i) % S_COUNT] = 1;
                    break;
                end
            end
        end
    end

    assign gnt = gnt_reg;

endmodule

// Routing module
module axis_router #(
    parameter S_COUNT = 4,
    parameter M_COUNT = 4,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter S_ID_WIDTH = 8,
    parameter M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
    parameter S_DEST_WIDTH = 1,
    parameter M_DEST_WIDTH = 1,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}}
)
(
    input  wire                             clk,
    input  wire                             rst,
    input  wire [S_COUNT-1:0][DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_COUNT-1:0][KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    input  wire [S_COUNT-1:0]               s_axis_tlast,
    input  wire [S_COUNT-1:0][S_ID_WIDTH-1:0] s_axis_tid,
    input  wire [S_COUNT-1:0][S_DEST_WIDTH-1:0] s_axis_tdest,
    input  wire [S_COUNT-1:0][USER_WIDTH-1:0]  s_axis_tuser,
    output wire [M_COUNT-1:0][DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_COUNT-1:0][KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire [M_COUNT-1:0]               m_axis_tvalid,
    input  wire [M_COUNT-1:0]               m_axis_tready,
    output wire [M_COUNT-1:0]               m_axis_tlast,
    output wire [M_COUNT-1:0][M_ID_WIDTH-1:0] m_axis_tid,
    output wire [M_COUNT-1:0][M_DEST_WIDTH-1:0] m_axis_tdest,
    output wire [M_COUNT-1:0][USER_WIDTH-1:0]  m_axis_tuser,
    input  wire [M_COUNT*S_COUNT-1:0]       req,
    output wire [M_COUNT*S_COUNT-1:0]       gnt
);

    reg [M_COUNT*S_COUNT-1:0]             gnt_reg;
    reg [M_COUNT*S_COUNT-1:0]             gnt_nxt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            gnt_reg <= {M_COUNT*S_COUNT{1'b0}};
        end else begin
            gnt_reg <= gnt_nxt;
        end
    end

    always @(*) begin
        integer i, j;
        gnt_nxt = {M_COUNT*S_COUNT{1'b0}};
        for (i = 0; i < M_COUNT; i = i + 1) begin
            for (j = 0; j < S_COUNT; j = j + 1) begin
                if (req[i*S_COUNT+j] & ~gnt_reg[i*S_COUNT+:S_COUNT]) begin
                    gnt_nxt[i*S_COUNT+j] = 1;
                    break;
                end
            end
        end
    end

    assign gnt = gnt_reg;

    genvar k;
    generate
        for (k = 0; k < M_COUNT; k = k + 1) begin : gen_m_axis
            reg [DATA_WIDTH-1:0]            m_axis_tdata_reg;
            reg [KEEP_WIDTH-1:0]            m_axis_tkeep_reg;
            reg                             m_axis_tvalid_reg;
            reg                             m_axis_tlast_reg;
            reg [M_ID_WIDTH-1:0]            m_axis_tid_reg;
            reg [USER_WIDTH-1:0]            m_axis_tuser_reg;

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    m_axis_tdata_reg  <= 0;
                    m_axis_tkeep_reg  <= 0;
                    m_axis_tvalid_reg <= 0;
                    m_axis_tlast_reg  <= 0;
                    m_axis_tid_reg    <= 0;
                    m_axis_tuser_reg  <= 0;
                end else begin
                    if (m_axis_tready[k]) begin
                        m_axis_tvalid_reg <= 0;
                    end
                    genvar l;
                    generate
                        for (l = 0; l < S_COUNT; l = l + 1) begin : gen_s_axis
                            if (gnt[k*S_COUNT+l] & ~m_axis_tvalid_reg) begin
                                m_axis_tdata_reg  <= s_axis_tdata[l];
                                m_axis_tkeep_reg  <= s_axis_tkeep[l];
                                m_axis_tvalid_reg <= s_axis_tvalid[l];
                                m_axis_tlast_reg  <= s_axis_tlast[l];
                                if (ID_ENABLE) begin
                                    m_axis_tid_reg <= {s_axis_tid[l], l};
                                end else begin
                                    m_axis_tid_reg <= 0;
                                end
                                if (USER_ENABLE) begin
                                    m_axis_tuser_reg <= s_axis_tuser[l];
                                end else begin
                                    m_axis_tuser_reg <= 0;
                                end
                            end
                        end
                    endgenerate
                end
            end

            assign m_axis_tdata[k]  = m_axis_tdata_reg;
            assign m_axis_tkeep[k]  = m_axis_tkeep_reg;
            assign m_axis_tvalid[k] = m_axis_tvalid_reg;
            assign m_axis_tlast[k]  = m_axis_tlast_reg;
            assign m_axis_tid[k]    = m_axis_tid_reg;
            assign m_axis_tdest[k]  = k;
            assign m_axis_tuser[k]  = m_axis_tuser_reg;
        end
    endgenerate

endmodule
