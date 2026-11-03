module axis_async_fifo #
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
    /*
     * AXI input
     */
    input  wire                   s_clk,
    input  wire                   s_rst,
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
    input  wire                   m_clk,
    input  wire                   m_rst,
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
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] s_status_depth,
    output wire [$clog2(DEPTH):0] s_status_depth_commit,
    output wire                   s_status_overflow,
    output wire                   s_status_bad_frame,
    output wire                   s_status_good_frame,
    output wire [$clog2(DEPTH):0] m_status_depth,
    output wire [$clog2(DEPTH):0] m_status_depth_commit,
    output wire                   m_status_overflow,
    output wire                   m_status_bad_frame,
    output wire                   m_status_good_frame
);

    wire [DATA_WIDTH-1:0]  fifo_inst_wr_data;
    wire [KEEP_WIDTH-1:0]  fifo_inst_wr_keep;
    wire                   fifo_inst_wr_en;
    wire                   fifo_inst_wr_last;
    wire [ID_WIDTH-1:0]    fifo_inst_wr_tid;
    wire [DEST_WIDTH-1:0]  fifo_inst_wr_dest;
    wire [USER_WIDTH-1:0]  fifo_inst_wr_user;
    wire [DATA_WIDTH-1:0]  fifo_inst_rd_data;
    wire [KEEP_WIDTH-1:0]  fifo_inst_rd_keep;
    wire                   fifo_inst_rd_valid;
    wire                   fifo_inst_rd_last;
    wire [ID_WIDTH-1:0]    fifo_inst_rd_tid;
    wire [DEST_WIDTH-1:0]  fifo_inst_rd_dest;
    wire [USER_WIDTH-1:0]  fifo_inst_rd_user;
    wire                   fifo_inst_rd_en;
    wire [$clog2(DEPTH):0] fifo_inst_wr_depth;
    wire [$clog2(DEPTH):0] fifo_inst_rd_depth;

    assign fifo_inst_wr_data  = s_axis_tdata;
    assign fifo_inst_wr_keep  = KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b1}};
    assign fifo_inst_wr_en    = s_axis_tvalid && s_axis_tready;
    assign fifo_inst_wr_last  = LAST_ENABLE ? s_axis_tlast : 1'b0;
    assign fifo_inst_wr_tid   = ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}};
    assign fifo_inst_wr_dest  = DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
    assign fifo_inst_wr_user  = USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};
    assign fifo_inst_rd_en    = m_axis_tready && m_axis_tvalid;

    assign s_axis_tready      = !fifo_inst_wr_full;
    assign m_axis_tdata       = fifo_inst_rd_data;
    assign m_axis_tkeep       = fifo_inst_rd_keep;
    assign m_axis_tvalid      = fifo_inst_rd_valid;
    assign m_axis_tlast       = fifo_inst_rd_last;
    assign m_axis_tid         = fifo_inst_rd_tid;
    assign m_axis_tdest       = fifo_inst_rd_dest;
    assign m_axis_tuser       = fifo_inst_rd_user;

    assign s_pause_ack        = 1'b0;
    assign m_pause_ack        = 1'b0;

    assign s_status_depth     = fifo_inst_wr_depth;
    assign s_status_depth_commit = fifo_inst_wr_depth;
    assign s_status_overflow  = fifo_inst_wr_full;
    assign s_status_bad_frame = 1'b0;
    assign s_status_good_frame = 1'b0;

    assign m_status_depth     = fifo_inst_rd_depth;
    assign m_status_depth_commit = fifo_inst_rd_depth;
    assign m_status_overflow  = 1'b0;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b0;

    wire fifo_inst_wr_full;
    wire fifo_inst_wr_empty;

    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE),
        .OUTPUT_FIFO_ENABLE(OUTPUT_FIFO_ENABLE)
    ) fifo_inst (
        .wr_clk(s_clk),
        .wr_rst(s_rst),
        .rd_clk(m_clk),
        .rd_rst(m_rst),
        .wr_data(fifo_inst_wr_data),
        .wr_keep(fifo_inst_wr_keep),
        .wr_en(fifo_inst_wr_en),
        .wr_last(fifo_inst_wr_last),
        .wr_tid(fifo_inst_wr_tid),
        .wr_dest(fifo_inst_wr_dest),
        .wr_user(fifo_inst_wr_user),
        .rd_data(fifo_inst_rd_data),
        .rd_keep(fifo_inst_rd_keep),
        .rd_valid(fifo_inst_rd_valid),
        .rd_last(fifo_inst_rd_last),
        .rd_tid(fifo_inst_rd_tid),
        .rd_dest(fifo_inst_rd_dest),
        .rd_user(fifo_inst_rd_user),
        .rd_en(fifo_inst_rd_en),
        .wr_full(fifo_inst_wr_full),
        .wr_empty(fifo_inst_wr_empty),
        .wr_depth(fifo_inst_wr_depth),
        .rd_depth(fifo_inst_rd_depth)
    );

endmodule

module async_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = 1,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter USER_WIDTH = 1,
    parameter RAM_PIPELINE = 1,
    parameter OUTPUT_FIFO_ENABLE = 0
)
(
    input  wire                   wr_clk,
    input  wire                   wr_rst,
    input  wire                   rd_clk,
    input  wire                   rd_rst,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    input  wire [KEEP_WIDTH-1:0]  wr_keep,
    input  wire                   wr_en,
    input  wire                   wr_last,
    input  wire [ID_WIDTH-1:0]    wr_tid,
    input  wire [DEST_WIDTH-1:0]  wr_dest,
    input  wire [USER_WIDTH-1:0]  wr_user,
    output wire [DATA_WIDTH-1:0]  rd_data,
    output wire [KEEP_WIDTH-1:0]  rd_keep,
    output wire                   rd_valid,
    output wire                   rd_last,
    output wire [ID_WIDTH-1:0]    rd_tid,
    output wire [DEST_WIDTH-1:0]  rd_dest,
    output wire [USER_WIDTH-1:0]  rd_user,
    input  wire                   rd_en,
    output wire                   wr_full,
    output wire                   wr_empty,
    output wire [$clog2(DEPTH):0] wr_depth,
    output wire [$clog2(DEPTH):0] rd_depth
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray;
    reg [ADDR_WIDTH:0] rd_ptr_gray;

    reg [DATA_WIDTH-1:0] mem_data [DEPTH-1:0];
    reg [KEEP_WIDTH-1:0] mem_keep [DEPTH-1:0];
    reg                  mem_last [DEPTH-1:0];
    reg [ID_WIDTH-1:0]   mem_tid [DEPTH-1:0];
    reg [DEST_WIDTH-1:0] mem_dest [DEPTH-1:0];
    reg [USER_WIDTH-1:0] mem_user [DEPTH-1:0];

    reg [ADDR_WIDTH:0] wr_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] rd_ptr_gray_nxt;

    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !wr_full) begin
            mem_data[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
            mem_keep[wr_ptr[ADDR_WIDTH-1:0]] <= wr_keep;
            mem_last[wr_ptr[ADDR_WIDTH-1:0]] <= wr_last;
            mem_tid[wr_ptr[ADDR_WIDTH-1:0]] <= wr_tid;
            mem_dest[wr_ptr[ADDR_WIDTH-1:0]] <= wr_dest;
            mem_user[wr_ptr[ADDR_WIDTH-1:0]] <= wr_user;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr_gray_nxt;
        end
    end

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en && rd_valid) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= rd_ptr_gray_nxt;
        end
    end

    always @(*) begin
        wr_ptr_gray_nxt = wr_ptr ^ (wr_ptr >> 1);
    end

    always @(*) begin
        rd_ptr_gray_nxt = rd_ptr ^ (rd_ptr >> 1);
    end

    assign wr_full = (wr_ptr_gray == {~rd_ptr_gray_nxt[ADDR_WIDTH], rd_ptr_gray_nxt[ADDR_WIDTH-1:0]});
    assign wr_empty = (wr_ptr_gray == rd_ptr_gray);

    assign rd_data = mem_data[rd_ptr[ADDR_WIDTH-1:0]];
    assign rd_keep = mem_keep[rd_ptr[ADDR_WIDTH-1:0]];
    assign rd_last = mem_last[rd_ptr[ADDR_WIDTH-1:0]];
    assign rd_tid = mem_tid[rd_ptr[ADDR_WIDTH-1:0]];
    assign rd_dest = mem_dest[rd_ptr[ADDR_WIDTH-1:0]];
    assign rd_user = mem_user[rd_ptr[ADDR_WIDTH-1:0]];

    assign rd_valid = !wr_empty;
    assign wr_depth = wr_ptr - rd_ptr;
    assign rd_depth = wr_ptr - rd_ptr;

endmodule
