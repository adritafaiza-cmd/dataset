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

    // Internal signals for FIFO
    wire [S_DATA_WIDTH-1:0]         fifo_write_data;
    wire [S_KEEP_WIDTH-1:0]         fifo_write_keep;
    wire                            fifo_write_valid;
    wire                            fifo_write_ready;
    wire                            fifo_write_last;
    wire [ID_WIDTH-1:0]             fifo_write_id;
    wire [DEST_WIDTH-1:0]           fifo_write_dest;
    wire [USER_WIDTH-1:0]           fifo_write_user;

    wire [M_DATA_WIDTH-1:0]         fifo_read_data;
    wire [M_KEEP_WIDTH-1:0]         fifo_read_keep;
    wire                            fifo_read_valid;
    wire                            fifo_read_ready;
    wire                            fifo_read_last;
    wire [ID_WIDTH-1:0]             fifo_read_id;
    wire [DEST_WIDTH-1:0]           fifo_read_dest;
    wire [USER_WIDTH-1:0]           fifo_read_user;

    wire [$clog2(DEPTH):0]          fifo_write_depth;
    wire [$clog2(DEPTH):0]          fifo_write_depth_commit;
    wire                            fifo_write_overflow;
    wire                            fifo_write_bad_frame;
    wire                            fifo_write_good_frame;

    wire [$clog2(DEPTH):0]          fifo_read_depth;
    wire [$clog2(DEPTH):0]          fifo_read_depth_commit;
    wire                            fifo_read_overflow;
    wire                            fifo_read_bad_frame;
    wire                            fifo_read_good_frame;

    wire                            fifo_write_pause_req;
    wire                            fifo_write_pause_ack;
    wire                            fifo_read_pause_req;
    wire                            fifo_read_pause_ack;

    // FIFO instance
    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(S_DATA_WIDTH),
        .KEEP_ENABLE(S_KEEP_ENABLE),
        .KEEP_WIDTH(S_KEEP_WIDTH),
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
    ) async_fifo_inst (
        .write_clk(s_clk),
        .write_rst(s_rst),
        .read_clk(m_clk),
        .read_rst(m_rst),
        .write_data(s_axis_tdata),
        .write_keep(s_axis_tkeep),
        .write_valid(s_axis_tvalid),
        .write_ready(fifo_write_ready),
        .write_last(s_axis_tlast),
        .write_id(s_axis_tid),
        .write_dest(s_axis_tdest),
        .write_user(s_axis_tuser),
        .read_data(fifo_read_data),
        .read_keep(fifo_read_keep),
        .read_valid(fifo_read_valid),
        .read_ready(m_axis_tready),
        .read_last(fifo_read_last),
        .read_id(fifo_read_id),
        .read_dest(fifo_read_dest),
        .read_user(fifo_read_user),
        .write_pause_req(s_pause_req),
        .write_pause_ack(fifo_write_pause_ack),
        .read_pause_req(m_pause_req),
        .read_pause_ack(fifo_read_pause_ack),
        .write_depth(fifo_write_depth),
        .write_depth_commit(fifo_write_depth_commit),
        .write_overflow(fifo_write_overflow),
        .write_bad_frame(fifo_write_bad_frame),
        .write_good_frame(fifo_write_good_frame),
        .read_depth(fifo_read_depth),
        .read_depth_commit(fifo_read_depth_commit),
        .read_overflow(fifo_read_overflow),
        .read_bad_frame(fifo_read_bad_frame),
        .read_good_frame(fifo_read_good_frame)
    );

    // Connect FIFO outputs to AXI outputs
    assign m_axis_tdata = fifo_read_data;
    assign m_axis_tkeep = fifo_read_keep;
    assign m_axis_tvalid = fifo_read_valid;
    assign m_axis_tlast = fifo_read_last;
    assign m_axis_tid = fifo_read_id;
    assign m_axis_tdest = fifo_read_dest;
    assign m_axis_tuser = fifo_read_user;

    // Connect FIFO inputs to AXI inputs
    assign s_axis_tready = fifo_write_ready;

    // Connect pause signals
    assign s_pause_ack = fifo_write_pause_ack;
    assign m_pause_ack = fifo_read_pause_ack;

    // Connect status signals
    assign s_status_depth = fifo_write_depth;
    assign s_status_depth_commit = fifo_write_depth_commit;
    assign s_status_overflow = fifo_write_overflow;
    assign s_status_bad_frame = fifo_write_bad_frame;
    assign s_status_good_frame = fifo_write_good_frame;

    assign m_status_depth = fifo_read_depth;
    assign m_status_depth_commit = fifo_read_depth_commit;
    assign m_status_overflow = fifo_read_overflow;
    assign m_status_bad_frame = fifo_read_bad_frame;
    assign m_status_good_frame = fifo_read_good_frame;

endmodule

module async_fifo #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = 0,
    parameter KEEP_WIDTH = 1,
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
    input  wire                     write_clk,
    input  wire                     write_rst,
    input  wire                     read_clk,
    input  wire                     read_rst,
    input  wire [DATA_WIDTH-1:0]    write_data,
    input  wire [KEEP_WIDTH-1:0]    write_keep,
    input  wire                     write_valid,
    output wire                     write_ready,
    input  wire                     write_last,
    input  wire [ID_WIDTH-1:0]      write_id,
    input  wire [DEST_WIDTH-1:0]    write_dest,
    input  wire [USER_WIDTH-1:0]    write_user,
    output wire [DATA_WIDTH-1:0]    read_data,
    output wire [KEEP_WIDTH-1:0]    read_keep,
    output wire                     read_valid,
    input  wire                     read_ready,
    output wire                     read_last,
    output wire [ID_WIDTH-1:0]      read_id,
    output wire [DEST_WIDTH-1:0]    read_dest,
    output wire [USER_WIDTH-1:0]    read_user,
    input  wire                     write_pause_req,
    output wire                     write_pause_ack,
    input  wire                     read_pause_req,
    output wire                     read_pause_ack,
    output wire [$clog2(DEPTH):0]   write_depth,
    output wire [$clog2(DEPTH):0]   write_depth_commit,
    output wire                     write_overflow,
    output wire                     write_bad_frame,
    output wire                     write_good_frame,
    output wire [$clog2(DEPTH):0]   read_depth,
    output wire [$clog2(DEPTH):0]   read_depth_commit,
    output wire                     read_overflow,
    output wire                     read_bad_frame,
    output wire                     read_good_frame
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH:0] write_ptr;
    reg [ADDR_WIDTH:0] read_ptr;
    reg [ADDR_WIDTH:0] read_ptr_gray;
    reg [ADDR_WIDTH:0] read_ptr_gray_sync;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    reg [ID_WIDTH-1:0] id_mem [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] dest_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_mem [0:DEPTH-1];
    reg last_mem [0:DEPTH-1];

    reg [ADDR_WIDTH:0] write_depth_reg;
    reg [ADDR_WIDTH:0] read_depth_reg;

    reg write_full;
    reg read_empty;

    reg write_pause;
    reg read_pause;

    // Write side
    always @(posedge write_clk or posedge write_rst) begin
        if (write_rst) begin
            write_ptr <= 0;
            write_depth_reg <= 0;
            write_full <= 0;
        end else if (write_valid && write_ready) begin
            write_ptr <= write_ptr + 1;
            if (write_ptr == DEPTH - 1)
                write_full <= 1;
            else if (write_ptr == DEPTH - 2)
                write_full <= 0;
            write_depth_reg <= write_depth_reg + 1;
        end
    end

    // Write data to memory
    always @(posedge write_clk) begin
        if (write_valid && write_ready) begin
            mem[write_ptr] <= write_data;
            keep_mem[write_ptr] <= write_keep;
            last_mem[write_ptr] <= write_last;
            if (ID_ENABLE)
                id_mem[write_ptr] <= write_id;
            if (DEST_ENABLE)
                dest_mem[write_ptr] <= write_dest;
            if (USER_ENABLE)
                user_mem[write_ptr] <= write_user;
        end
    end

    // Read side
    always @(posedge read_clk or posedge read_rst) begin
        if (read_rst) begin
            read_ptr <= 0;
            read_depth_reg <= 0;
            read_empty <= 1;
        end else if (read_valid && read_ready) begin
            read_ptr <= read_ptr + 1;
            if (read_ptr == DEPTH - 1)
                read_empty <= 1;
            else if (read_ptr == DEPTH - 2)
                read_empty <= 0;
            read_depth_reg <= read_depth_reg - 1;
        end
    end

    // Binary to Gray conversion for read pointer
    always @(posedge write_clk or posedge write_rst) begin
        if (write_rst)
            read_ptr_gray_sync <= 0;
        else
            read_ptr_gray_sync <= read_ptr_gray;
    end

    assign read_ptr_gray = (read_ptr >> 1) ^ read_ptr;

    // Read data from memory
    reg [ADDR_WIDTH:0] read_ptr_gray_sync_d1;
    reg [ADDR_WIDTH:0] read_ptr_gray_sync_d2;

    always @(posedge read_clk or posedge read_rst) begin
        if (read_rst) begin
            read_ptr_gray_sync_d1 <= 0;
            read_ptr_gray_sync_d2 <= 0;
        end else begin
            read_ptr_gray_sync_d1 <= read_ptr_gray_sync;
            read_ptr_gray_sync_d2 <= read_ptr_gray_sync_d1;
        end
    end

    wire [ADDR_WIDTH:0] read_ptr_gray_sync_d2_bin;
    assign read_ptr_gray_sync_d2_bin = (read_ptr_gray_sync_d2 >> 1) ^ read_ptr_gray_sync_d2;

    assign read_data = mem[read_ptr_gray_sync_d2_bin];
    assign read_keep = keep_mem[read_ptr_gray_sync_d2_bin];
    assign read_last = last_mem[read_ptr_gray_sync_d2_bin];
    assign read_id = (ID_ENABLE) ? id_mem[read_ptr_gray_sync_d2_bin] : {ID_WIDTH{1'b0}};
    assign read_dest = (DEST_ENABLE) ? dest_mem[read_ptr_gray_sync_d2_bin] : {DEST_WIDTH{1'b0}};
    assign read_user = (USER_ENABLE) ? user_mem[read_ptr_gray_sync_d2_bin] : {USER_WIDTH{1'b0}};

    // Ready signals
    assign write_ready = !write_full;
    assign read_valid = !read_empty;

    // Pause signals
    assign write_pause_ack = write_pause;
    assign read_pause_ack = read_pause;

    // Status signals
    assign write_depth = write_depth_reg;
    assign read_depth = read_depth_reg;
    assign write_depth_commit = write_depth_reg;
    assign read_depth_commit = read_depth_reg;
    assign write_overflow = write_full;
    assign read_overflow = read_empty;
    assign write_bad_frame = 0;
    assign write_good_frame = 0;
    assign read_bad_frame = 0;
    assign read_good_frame = 0;

endmodule
