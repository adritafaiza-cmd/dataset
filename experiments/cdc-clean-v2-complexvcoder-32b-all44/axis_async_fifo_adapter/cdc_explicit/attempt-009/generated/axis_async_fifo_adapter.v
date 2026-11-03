module axis_async_fifo_adapter #
(
    parameter DEPTH = 4096,
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH>8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH+7)/8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH>8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH+7)/8),
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
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [S_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI output
     */
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
    /*
     * Pause
     */
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0]   s_status_depth,
    output wire [$clog2(DEPTH):0]   s_status_depth_commit,
    output wire                     s_status_overflow,
    output wire                     s_status_bad_frame,
    output wire                     s_status_good_frame,
    output wire [$clog2(DEPTH):0]   m_status_depth,
    output wire [$clog2(DEPTH):0]   m_status_depth_commit,
    output wire                     m_status_overflow,
    output wire                     m_status_bad_frame,
    output wire                     m_status_good_frame
);

    /*
     * Internal signals
     */
    wire [S_DATA_WIDTH+S_KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:0] fifo_wr_data;
    wire fifo_full;
    wire [M_DATA_WIDTH+M_KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:0] fifo_rd_data;
    wire fifo_empty;
    wire [$clog2(DEPTH):0] s_fifo_depth;
    wire [$clog2(DEPTH):0] m_fifo_depth;

    /*
     * Asynchronous FIFO instance
     */
    axis_async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(S_DATA_WIDTH+S_KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH+USER_WIDTH)
    ) fifo_inst (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .data_wr(fifo_wr_data),
        .wr_en(s_axis_tvalid & ~fifo_full),
        .full(fifo_full),
        .data_rd(fifo_rd_data),
        .rd_en(m_axis_tready & m_axis_tvalid),
        .empty(fifo_empty),
        .depth(s_fifo_depth),
        .depth_commit(s_fifo_depth),
        .overflow(s_status_overflow),
        .underflow(),
        .status_depth(s_status_depth),
        .status_depth_commit(s_status_depth_commit),
        .status_good_frame(s_status_good_frame),
        .status_bad_frame(s_status_bad_frame)
    );

    /*
     * Width adapter instance
     */
    width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_ENABLE(S_KEEP_ENABLE),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_ENABLE(M_KEEP_ENABLE),
        .M_KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH)
    ) adapter_inst (
        .s_clk(m_clk),
        .s_rst(m_rst),
        .s_axis_tdata(fifo_rd_data[M_DATA_WIDTH-1:0]),
        .s_axis_tkeep(fifo_rd_data[M_DATA_WIDTH+M_KEEP_WIDTH-1:M_DATA_WIDTH]),
        .s_axis_tvalid(~fifo_empty),
        .s_axis_tlast(fifo_rd_data[M_DATA_WIDTH+M_KEEP_WIDTH]),
        .s_axis_tid(fifo_rd_data[M_DATA_WIDTH+M_KEEP_WIDTH+1+ID_WIDTH-1:M_DATA_WIDTH+M_KEEP_WIDTH+1]),
        .s_axis_tdest(fifo_rd_data[M_DATA_WIDTH+M_KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH-1:M_DATA_WIDTH+M_KEEP_WIDTH+1+ID_WIDTH]),
        .s_axis_tuser(fifo_rd_data[M_DATA_WIDTH+M_KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:M_DATA_WIDTH+M_KEEP_WIDTH+1+ID_WIDTH+DEST_WIDTH]),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tid(m_axis_tid),
        .m_axis_tdest(m_axis_tdest),
        .m_axis_tuser(m_axis_tuser)
    );

    /*
     * FIFO write data packing
     */
    assign fifo_wr_data = {s_axis_tuser, s_axis_tdest, s_axis_tid, s_axis_tlast, s_axis_tdata, s_axis_tkeep};

    /*
     * AXI handshake signals
     */
    assign s_axis_tready = ~fifo_full;
    assign m_status_depth = m_fifo_depth;
    assign m_status_depth_commit = m_fifo_depth;
    assign m_status_overflow = 1'b0;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b0;

    /*
     * Pause signals
     */
    assign s_pause_ack = 1'b0;
    assign m_pause_ack = 1'b0;

endmodule

/*
 * Asynchronous FIFO module
 */
module axis_async_fifo #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 32
)
(
    input  wire                     clk_wr,
    input  wire                     rst_wr,
    input  wire                     clk_rd,
    input  wire                     rst_rd,
    input  wire [DATA_WIDTH-1:0]    data_wr,
    input  wire                     wr_en,
    output wire                     full,
    output wire [DATA_WIDTH-1:0]    data_rd,
    input  wire                     rd_en,
    output wire                     empty,
    output wire [$clog2(DEPTH):0]   depth,
    output wire [$clog2(DEPTH):0]   depth_commit,
    output wire                     overflow,
    output wire                     underflow,
    output wire [$clog2(DEPTH):0]   status_depth,
    output wire [$clog2(DEPTH):0]   status_depth_commit,
    output wire                     status_good_frame,
    output wire                     status_bad_frame
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] wr_ptr_gray_d, rd_ptr_gray_d;
    reg [ADDR_WIDTH:0] depth_reg, depth_commit_reg;
    reg overflow_reg, underflow_reg;

    /*
     * Write pointer logic
     */
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && ~full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= data_wr;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
        end
    end

    /*
     * Read pointer logic
     */
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en && ~empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
        end
    end

    /*
     * Gray code synchronization
     */
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            wr_ptr_gray_sync <= 0;
            wr_ptr_gray_d <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
            wr_ptr_gray_d <= wr_ptr_gray_sync;
        end
    end

    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            rd_ptr_gray_sync <= 0;
            rd_ptr_gray_d <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
            rd_ptr_gray_d <= rd_ptr_gray_sync;
        end
    end

    /*
     * Depth calculation
     */
    assign depth = wr_ptr - rd_ptr_gray_d;
    assign depth_commit = wr_ptr_gray_d - rd_ptr;

    /*
     * Full and empty flags
     */
    assign full = (wr_ptr_gray == {wr_ptr_gray_d[ADDR_WIDTH], ~wr_ptr_gray_d[ADDR_WIDTH-1:0]});
    assign empty = (rd_ptr_gray == {rd_ptr_gray_d[ADDR_WIDTH], ~rd_ptr_gray_d[ADDR_WIDTH-1:0]});

    /*
     * Output data
     */
    assign data_rd = mem[rd_ptr[ADDR_WIDTH-1:0]];

    /*
     * Status signals
     */
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            overflow_reg <= 0;
        end else if (wr_en && full) begin
            overflow_reg <= 1;
        end else begin
            overflow_reg <= 0;
        end
    end

    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            underflow_reg <= 0;
        end else if (rd_en && empty) begin
            underflow_reg <= 1;
        end else begin
            underflow_reg <= 0;
        end
    end

    assign overflow = overflow_reg;
    assign underflow = underflow_reg;
    assign status_depth = depth;
    assign status_depth_commit = depth_commit;
    assign status_good_frame = 1'b0;
    assign status_bad_frame = 1'b0;

endmodule

/*
 * Width adapter module
 */
module width_adapter #(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH>8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH+7)/8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH>8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1
)
(
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [S_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    input  wire                     m_axis_tready,
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser
);

    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg s_axis_tvalid_reg;
    reg s_axis_tlast_reg;
    reg [ID_WIDTH-1:0] s_axis_tid_reg;
    reg [DEST_WIDTH-1:0] s_axis_tdest_reg;
    reg [USER_WIDTH-1:0] s_axis_tuser_reg;
    reg [S_DATA_WIDTH-1:0] data_shift_reg;
    reg [S_KEEP_WIDTH-1:0] keep_shift_reg;
    reg [$clog2(S_DATA_WIDTH/M_DATA_WIDTH)-1:0] shift_cnt;
    reg tvalid_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tvalid_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
            data_shift_reg <= 0;
            keep_shift_reg <= 0;
            shift_cnt <= 0;
            tvalid_reg <= 0;
        end else if (s_axis_tvalid && (shift_cnt == 0)) begin
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tkeep_reg <= s_axis_tkeep;
            s_axis_tvalid_reg <= s_axis_tvalid;
            s_axis_tlast_reg <= s_axis_tlast;
            s_axis_tid_reg <= s_axis_tid;
            s_axis_tdest_reg <= s_axis_tdest;
            s_axis_tuser_reg <= s_axis_tuser;
            data_shift_reg <= s_axis_tdata;
            keep_shift_reg <= s_axis_tkeep;
            shift_cnt <= $clog2(S_DATA_WIDTH/M_DATA_WIDTH) - 1;
            tvalid_reg <= 1;
        end else if (tvalid_reg && m_axis_tready) begin
            data_shift_reg <= {data_shift_reg[S_DATA_WIDTH-M_DATA_WIDTH-1:0], M_DATA_WIDTH'(0)};
            keep_shift_reg <= {keep_shift_reg[S_KEEP_WIDTH-M_KEEP_WIDTH-1:0], M_KEEP_WIDTH'(0)};
            shift_cnt <= shift_cnt - 1;
            if (shift_cnt == 0) begin
                tvalid_reg <= 0;
            end
        end
    end

    assign m_axis_tdata = data_shift_reg[M_DATA_WIDTH-1:0];
    assign m_axis_tkeep = keep_shift_reg[M_KEEP_WIDTH-1:0];
    assign m_axis_tvalid = tvalid_reg;
    assign m_axis_tlast = s_axis_tlast_reg;
    assign m_axis_tid = s_axis_tid_reg;
    assign m_axis_tdest = s_axis_tdest_reg;
    assign m_axis_tuser = s_axis_tuser_reg;

endmodule
