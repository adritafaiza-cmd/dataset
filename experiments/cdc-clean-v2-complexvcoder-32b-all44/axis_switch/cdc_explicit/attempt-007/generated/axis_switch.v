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
    wire [S_COUNT*DATA_WIDTH-1:0]           arbiter_s_axis_tdata;
    wire [S_COUNT*KEEP_WIDTH-1:0]           arbiter_s_axis_tkeep;
    wire [S_COUNT-1:0]                      arbiter_s_axis_tvalid;
    wire [S_COUNT-1:0]                      arbiter_s_axis_tready;
    wire [S_COUNT-1:0]                      arbiter_s_axis_tlast;
    wire [S_COUNT*S_ID_WIDTH-1:0]           arbiter_s_axis_tid;
    wire [S_COUNT*S_DEST_WIDTH-1:0]         arbiter_s_axis_tdest;
    wire [S_COUNT*USER_WIDTH-1:0]           arbiter_s_axis_tuser;

    wire [M_COUNT*DATA_WIDTH-1:0]           router_m_axis_tdata;
    wire [M_COUNT*KEEP_WIDTH-1:0]           router_m_axis_tkeep;
    wire [M_COUNT-1:0]                      router_m_axis_tvalid;
    wire [M_COUNT-1:0]                      router_m_axis_tready;
    wire [M_COUNT-1:0]                      router_m_axis_tlast;
    wire [M_COUNT*M_ID_WIDTH-1:0]           router_m_axis_tid;
    wire [M_COUNT*M_DEST_WIDTH-1:0]         router_m_axis_tdest;
    wire [M_COUNT*USER_WIDTH-1:0]           router_m_axis_tuser;

    /*
     * AXI Stream arbiter instance
     */
    axis_arbiter #(
        .S_COUNT(S_COUNT),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .S_ID_WIDTH(S_ID_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .S_REG_TYPE(S_REG_TYPE),
        .ARB_TYPE_ROUND_ROBIN(ARB_TYPE_ROUND_ROBIN),
        .ARB_LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
    ) arbiter_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(arbiter_s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tid(s_axis_tid),
        .s_axis_tdest(s_axis_tdest),
        .s_axis_tuser(s_axis_tuser),
        .m_axis_tdata(arbiter_s_axis_tdata),
        .m_axis_tkeep(arbiter_s_axis_tkeep),
        .m_axis_tvalid(arbiter_s_axis_tvalid),
        .m_axis_tready(arbiter_s_axis_tready),
        .m_axis_tlast(arbiter_s_axis_tlast),
        .m_axis_tid(arbiter_s_axis_tid),
        .m_axis_tdest(arbiter_s_axis_tdest),
        .m_axis_tuser(arbiter_s_axis_tuser)
    );

    /*
     * AXI Stream router instance
     */
    axis_router #(
        .M_COUNT(M_COUNT),
        .S_COUNT(S_COUNT),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .S_ID_WIDTH(S_ID_WIDTH),
        .M_ID_WIDTH(M_ID_WIDTH),
        .M_DEST_WIDTH(M_DEST_WIDTH),
        .S_DEST_WIDTH(S_DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .M_BASE(M_BASE),
        .M_TOP(M_TOP),
        .M_CONNECT(M_CONNECT),
        .UPDATE_TID(UPDATE_TID),
        .M_REG_TYPE(M_REG_TYPE)
    ) router_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(arbiter_s_axis_tdata),
        .s_axis_tkeep(arbiter_s_axis_tkeep),
        .s_axis_tvalid(arbiter_s_axis_tvalid),
        .s_axis_tready(arbiter_s_axis_tready),
        .s_axis_tlast(arbiter_s_axis_tlast),
        .s_axis_tid(arbiter_s_axis_tid),
        .s_axis_tdest(arbiter_s_axis_tdest),
        .s_axis_tuser(arbiter_s_axis_tuser),
        .m_axis_tdata(router_m_axis_tdata),
        .m_axis_tkeep(router_m_axis_tkeep),
        .m_axis_tvalid(router_m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(router_m_axis_tlast),
        .m_axis_tid(router_m_axis_tid),
        .m_axis_tdest(router_m_axis_tdest),
        .m_axis_tuser(router_m_axis_tuser)
    );

    /*
     * Assign outputs
     */
    assign s_axis_tready = arbiter_s_axis_tready;
    assign m_axis_tdata = router_m_axis_tdata;
    assign m_axis_tkeep = router_m_axis_tkeep;
    assign m_axis_tvalid = router_m_axis_tvalid;
    assign m_axis_tlast = router_m_axis_tlast;
    assign m_axis_tid = router_m_axis_tid;
    assign m_axis_tdest = router_m_axis_tdest;
    assign m_axis_tuser = router_m_axis_tuser;

endmodule

module axis_arbiter #
(
    parameter S_COUNT = 4,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter S_ID_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter S_REG_TYPE = 0,
    parameter ARB_TYPE_ROUND_ROBIN = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
    input  wire                             clk,
    input  wire                             rst,
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [S_COUNT*KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    output wire [S_COUNT-1:0]               s_axis_tready,
    input  wire [S_COUNT-1:0]               s_axis_tlast,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axis_tid,
    input  wire [S_COUNT*S_DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [S_COUNT*USER_WIDTH-1:0]    s_axis_tuser,
    output wire [DATA_WIDTH-1:0]            m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]            m_axis_tkeep,
    output wire                             m_axis_tvalid,
    input  wire                             m_axis_tready,
    output wire                             m_axis_tlast,
    output wire [S_ID_WIDTH-1:0]            m_axis_tid,
    output wire [S_DEST_WIDTH-1:0]          m_axis_tdest,
    output wire [USER_WIDTH-1:0]            m_axis_tuser
);

    /*
     * Internal signals
     */
    reg  [S_COUNT-1:0]                      valid_mask;
    reg  [$clog2(S_COUNT)-1:0]              grant;
    reg  [$clog2(S_COUNT)-1:0]              next_grant;

    /*
     * Generate valid mask
     */
    always @(*) begin
        valid_mask = s_axis_tvalid;
    end

    /*
     * Round-robin arbiter
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant <= 0;
        end else if (m_axis_tready && m_axis_tvalid) begin
            grant <= next_grant;
        end
    end

    always @(*) begin
        if (ARB_LSB_HIGH_PRIORITY) begin
            next_grant = grant;
            for (integer i = 0; i < S_COUNT; i = i + 1) begin
                if (valid_mask[(grant + i) % S_COUNT]) begin
                    next_grant = (grant + i) % S_COUNT;
                    break;
                end
            end
        end else begin
            next_grant = grant;
            for (integer i = 0; i < S_COUNT; i = i + 1) begin
                if (valid_mask[(grant - i + S_COUNT) % S_COUNT]) begin
                    next_grant = (grant - i + S_COUNT) % S_COUNT;
                    break;
                end
            end
        end
    end

    /*
     * Generate outputs
     */
    assign m_axis_tdata = s_axis_tdata[grant*DATA_WIDTH +: DATA_WIDTH];
    assign m_axis_tkeep = s_axis_tkeep[grant*KEEP_WIDTH +: KEEP_WIDTH];
    assign m_axis_tvalid = valid_mask[grant];
    assign m_axis_tlast = s_axis_tlast[grant];
    assign m_axis_tid = s_axis_tid[grant*S_ID_WIDTH +: S_ID_WIDTH];
    assign m_axis_tdest = s_axis_tdest[grant*S_DEST_WIDTH +: S_DEST_WIDTH];
    assign m_axis_tuser = s_axis_tuser[grant*USER_WIDTH +: USER_WIDTH];

    /*
     * Generate tready
     */
    genvar i;
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_tready
            assign s_axis_tready[i] = (grant == i) && m_axis_tready;
        end
    endgenerate

endmodule

module axis_router #
(
    parameter M_COUNT = 4,
    parameter S_COUNT = 4,
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
    parameter M_REG_TYPE = 2
)
(
    input  wire                             clk,
    input  wire                             rst,
    input  wire [DATA_WIDTH-1:0]            s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]            s_axis_tkeep,
    input  wire                             s_axis_tvalid,
    output wire                             s_axis_tready,
    input  wire                             s_axis_tlast,
    input  wire [S_ID_WIDTH-1:0]            s_axis_tid,
    input  wire [S_DEST_WIDTH-1:0]          s_axis_tdest,
    input  wire [USER_WIDTH-1:0]            s_axis_tuser,
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
    reg  [$clog2(M_COUNT)-1:0]              dest_idx;
    reg  [M_COUNT-1:0]                      valid_mask;
    reg  [M_COUNT-1:0]                      ready_mask;
    reg  [M_COUNT-1:0]                      tvalid_reg;

    /*
     * Generate destination index
     */
    always @(*) begin
        dest_idx = s_axis_tdest[M_DEST_WIDTH+$clog2(M_COUNT)-1:$clog2(M_COUNT)];
    end

    /*
     * Generate valid mask
     */
    always @(*) begin
        valid_mask = 0;
        if (s_axis_tvalid) begin
            for (integer i = 0; i < M_COUNT; i = i + 1) begin
                if (M_CONNECT[i][dest_idx]) begin
                    valid_mask[i] = 1;
                end
            end
        end
    end

    /*
     * Generate tvalid and tready
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tvalid_reg <= 0;
        end else begin
            tvalid_reg <= valid_mask & ~ready_mask;
        end
    end

    always @(*) begin
        s_axis_tready = &((valid_mask & tvalid_reg) | ~valid_mask);
        m_axis_tvalid = valid_mask & tvalid_reg;
    end

    /*
     * Generate outputs
     */
    genvar i;
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_outputs
            assign m_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH] = s_axis_tdata;
            assign m_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH] = s_axis_tkeep;
            assign m_axis_tlast[i] = s_axis_tlast;
            assign m_axis_tid[i*M_ID_WIDTH +: M_ID_WIDTH] = s_axis_tid;
            assign m_axis_tdest[i*M_DEST_WIDTH +: M_DEST_WIDTH] = s_axis_tdest;
            assign m_axis_tuser[i*USER_WIDTH +: USER_WIDTH] = s_axis_tuser;
        end
    endgenerate

    /*
     * Generate ready mask
     */
    always @(*) begin
        ready_mask = 0;
        for (integer i = 0; i < M_COUNT; i = i + 1) begin
            if (m_axis_tready[i]) begin
                ready_mask[i] = 1;
            end
        end
    end

endmodule
