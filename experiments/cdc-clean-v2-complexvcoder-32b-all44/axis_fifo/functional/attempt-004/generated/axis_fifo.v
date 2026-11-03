module axis_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter RAM_PIPELINE = 1,
    parameter OUTPUT_FIFO_ENABLE = 0,
    parameter FRAME_FIFO = 0,
    parameter USER_BAD_FRAME_VALUE = 1'b1,
    parameter USER_BAD_FRAME_MASK = 1'b1,
    parameter DROP_OVERSIZE_FRAME = FRAME_FIFO,
    parameter DROP_BAD_FRAME = 0,
    parameter DROP_WHEN_FULL = 0,
    parameter MARK_WHEN_FULL = 0,
    parameter PAUSE_ENABLE = 0,
    parameter FRAME_PAUSE = FRAME_FIFO
)
(
    input  wire                   clk,
    input  wire                   rst,
    /*
     * AXI input
     */
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    /*
     * AXI output
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    /*
     * Pause
     */
    input  wire                   pause_req,
    output wire                   pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    wire [$clog2(DEPTH):0] fifo_core_status_depth;
    wire [$clog2(DEPTH):0] fifo_core_status_depth_commit;
    wire fifo_core_status_overflow;
    wire fifo_core_status_bad_frame;
    wire fifo_core_status_good_frame;

    fifo_core #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE),
        .OUTPUT_FIFO_ENABLE(OUTPUT_FIFO_ENABLE),
        .FRAME_FIFO(FRAME_FIFO),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
        .DROP_BAD_FRAME(DROP_BAD_FRAME),
        .DROP_WHEN_FULL(DROP_WHEN_FULL),
        .MARK_WHEN_FULL(MARK_WHEN_FULL),
        .PAUSE_ENABLE(PAUSE_ENABLE),
        .FRAME_PAUSE(FRAME_PAUSE)
    ) fifo_core_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tid(s_axis_tid),
        .s_axis_tdest(s_axis_tdest),
        .s_axis_tuser(s_axis_tuser),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tid(m_axis_tid),
        .m_axis_tdest(m_axis_tdest),
        .m_axis_tuser(m_axis_tuser),
        .pause_req(pause_req),
        .pause_ack(pause_ack),
        .status_depth(fifo_core_status_depth),
        .status_depth_commit(fifo_core_status_depth_commit),
        .status_overflow(fifo_core_status_overflow),
        .status_bad_frame(fifo_core_status_bad_frame),
        .status_good_frame(fifo_core_status_good_frame)
    );

    assign status_depth = fifo_core_status_depth;
    assign status_depth_commit = fifo_core_status_depth_commit;
    assign status_overflow = fifo_core_status_overflow;
    assign status_bad_frame = fifo_core_status_bad_frame;
    assign status_good_frame = fifo_core_status_good_frame;

endmodule

module fifo_core #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter RAM_PIPELINE = 1,
    parameter OUTPUT_FIFO_ENABLE = 0,
    parameter FRAME_FIFO = 0,
    parameter USER_BAD_FRAME_VALUE = 1'b1,
    parameter USER_BAD_FRAME_MASK = 1'b1,
    parameter DROP_OVERSIZE_FRAME = FRAME_FIFO,
    parameter DROP_BAD_FRAME = 0,
    parameter DROP_WHEN_FULL = 0,
    parameter MARK_WHEN_FULL = 0,
    parameter PAUSE_ENABLE = 0,
    parameter FRAME_PAUSE = FRAME_FIFO
)
(
    input  wire                   clk,
    input  wire                   rst,
    /*
     * AXI input
     */
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    /*
     * AXI output
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    /*
     * Pause
     */
    input  wire                   pause_req,
    output wire                   pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    wire [$clog2(DEPTH):0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray;
    wire [$clog2(DEPTH):0] wr_ptr_next, rd_ptr_next;
    wire full, empty, almost_full, almost_empty;
    wire [DATA_WIDTH-1:0] mem_dout;
    wire [DATA_WIDTH-1:0] mem_din;
    wire [KEEP_WIDTH-1:0] mem_keep_dout;
    wire [KEEP_WIDTH-1:0] mem_keep_din;
    wire mem_tlast_dout;
    wire mem_tlast_din;
    wire [ID_WIDTH-1:0] mem_tid_dout;
    wire [ID_WIDTH-1:0] mem_tid_din;
    wire [DEST_WIDTH-1:0] mem_tdest_dout;
    wire [DEST_WIDTH-1:0] mem_tdest_din;
    wire [USER_WIDTH-1:0] mem_tuser_dout;
    wire [USER_WIDTH-1:0] mem_tuser_din;

    assign mem_din = s_axis_tdata;
    assign mem_keep_din = s_axis_tkeep;
    assign mem_tlast_din = s_axis_tlast;
    assign mem_tid_din = s_axis_tid;
    assign mem_tdest_din = s_axis_tdest;
    assign mem_tuser_din = s_axis_tuser;

    assign m_axis_tdata = mem_dout;
    assign m_axis_tkeep = mem_keep_dout;
    assign m_axis_tlast = mem_tlast_dout;
    assign m_axis_tid = mem_tid_dout;
    assign m_axis_tdest = mem_tdest_dout;
    assign m_axis_tuser = mem_tuser_dout;

    wire wr_en = s_axis_tvalid & s_axis_tready;
    wire rd_en = m_axis_tvalid & m_axis_tready;

    assign s_axis_tready = ~full & ~pause_req;
    assign m_axis_tvalid = ~empty;

    assign pause_ack = pause_req & ~full;

    gray_counter #(.WIDTH($clog2(DEPTH)+1)) wr_gray_counter (
        .clk(clk),
        .rst(rst),
        .en(wr_en),
        .gray(wr_ptr_gray),
        .bin(wr_ptr)
    );

    gray_counter #(.WIDTH($clog2(DEPTH)+1)) rd_gray_counter (
        .clk(clk),
        .rst(rst),
        .en(rd_en),
        .gray(rd_ptr_gray),
        .bin(rd_ptr)
    );

    assign full = (wr_ptr_gray == {~rd_ptr_gray[$clog2(DEPTH)], rd_ptr_gray[$clog2(DEPTH)-1:0]});
    assign empty = (wr_ptr_gray == rd_ptr_gray);

    assign almost_full = (wr_ptr_gray == {rd_ptr_gray[$clog2(DEPTH)], ~rd_ptr_gray[$clog2(DEPTH)-1:0]});
    assign almost_empty = (wr_ptr_gray[$clog2(DEPTH)-1:0] == rd_ptr_gray[$clog2(DEPTH)-1:0]) & (wr_ptr_gray[$clog2(DEPTH)] != rd_ptr_gray[$clog2(DEPTH)]);

    assign wr_ptr_next = wr_en ? (wr_ptr + 1) : wr_ptr;
    assign rd_ptr_next = rd_en ? (rd_ptr + 1) : rd_ptr;

    assign status_depth = wr_ptr - rd_ptr;
    assign status_depth_commit = wr_ptr_next - rd_ptr_next;

    assign status_overflow = full & wr_en;
    assign status_bad_frame = 1'b0; // Placeholder for actual bad frame detection
    assign status_good_frame = 1'b0; // Placeholder for actual good frame detection

    dual_port_ram #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) data_ram (
        .clk(clk),
        .we(wr_en),
        .wa(wr_ptr_next[$clog2(DEPTH)-1:0]),
        .da(mem_din),
        .ra(rd_ptr[$clog2(DEPTH)-1:0]),
        .qa(mem_dout)
    );

    if (KEEP_ENABLE) begin : gen_keep_ram
        dual_port_ram #(
            .DEPTH(DEPTH),
            .DATA_WIDTH(KEEP_WIDTH)
        ) keep_ram (
            .clk(clk),
            .we(wr_en),
            .wa(wr_ptr_next[$clog2(DEPTH)-1:0]),
            .da(mem_keep_din),
            .ra(rd_ptr[$clog2(DEPTH)-1:0]),
            .qa(mem_keep_dout)
        );
    end else begin : gen_keep_constant
        assign mem_keep_dout = {KEEP_WIDTH{1'b1}};
    end

    if (LAST_ENABLE) begin : gen_last_ram
        single_port_ram #(
            .DEPTH(DEPTH)
        ) last_ram (
            .clk(clk),
            .we(wr_en),
            .wa(wr_ptr_next[$clog2(DEPTH)-1:0]),
            .da(mem_tlast_din),
            .ra(rd_ptr[$clog2(DEPTH)-1:0]),
            .qa(mem_tlast_dout)
        );
    end else begin : gen_last_constant
        assign mem_tlast_dout = 1'b0;
    end

    if (ID_ENABLE) begin : gen_id_ram
        dual_port_ram #(
            .DEPTH(DEPTH),
            .DATA_WIDTH(ID_WIDTH)
        ) id_ram (
            .clk(clk),
            .we(wr_en),
            .wa(wr_ptr_next[$clog2(DEPTH)-1:0]),
            .da(mem_tid_din),
            .ra(rd_ptr[$clog2(DEPTH)-1:0]),
            .qa(mem_tid_dout)
        );
    end else begin : gen_id_constant
        assign mem_tid_dout = {ID_WIDTH{1'b0}};
    end

    if (DEST_ENABLE) begin : gen_dest_ram
        dual_port_ram #(
            .DEPTH(DEPTH),
            .DATA_WIDTH(DEST_WIDTH)
        ) dest_ram (
            .clk(clk),
            .we(wr_en),
            .wa(wr_ptr_next[$clog2(DEPTH)-1:0]),
            .da(mem_tdest_din),
            .ra(rd_ptr[$clog2(DEPTH)-1:0]),
            .qa(mem_tdest_dout)
        );
    end else begin : gen_dest_constant
        assign mem_tdest_dout = {DEST_WIDTH{1'b0}};
    end

    if (USER_ENABLE) begin : gen_user_ram
        dual_port_ram #(
            .DEPTH(DEPTH),
            .DATA_WIDTH(USER_WIDTH)
        ) user_ram (
            .clk(clk),
            .we(wr_en),
            .wa(wr_ptr_next[$clog2(DEPTH)-1:0]),
            .da(mem_tuser_din),
            .ra(rd_ptr[$clog2(DEPTH)-1:0]),
            .qa(mem_tuser_dout)
        );
    end else begin : gen_user_constant
        assign mem_tuser_dout = {USER_WIDTH{1'b0}};
    end

endmodule

module gray_counter #
(
    parameter WIDTH = 4
)
(
    input  wire               clk,
    input  wire               rst,
    input  wire               en,
    output wire [WIDTH-1:0]   gray,
    output wire [WIDTH-1:0]   bin
);

    reg [WIDTH-1:0] bin_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bin_reg <= {WIDTH{1'b0}};
        end else if (en) begin
            bin_reg <= bin_reg + 1;
        end
    end

    assign gray = bin_reg ^ (bin_reg >> 1);
    assign bin = bin_reg;

endmodule

module dual_port_ram #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8
)
(
    input  wire                   clk,
    input  wire                   we,
    input  wire [$clog2(DEPTH)-1:0] wa,
    input  wire [DATA_WIDTH-1:0]  da,
    input  wire [$clog2(DEPTH)-1:0] ra,
    output reg  [DATA_WIDTH-1:0]  qa
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (we) begin
            mem[wa] <= da;
        end
    end

    always @(posedge clk) begin
        qa <= mem[ra];
    end

endmodule

module single_port_ram #
(
    parameter DEPTH = 4096
)
(
    input  wire               clk,
    input  wire               we,
    input  wire [$clog2(DEPTH)-1:0] wa,
    input  wire               da,
    input  wire [$clog2(DEPTH)-1:0] ra,
    output reg                qa
);

    reg [DEPTH-1:0] mem;

    always @(posedge clk) begin
        if (we) begin
            mem[wa] <= da;
        end
        qa <= mem[ra];
    end

endmodule
