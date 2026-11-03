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

    localparam ADDR_WIDTH = $clog2(DEPTH);

    // Internal signals for CDC
    wire [ADDR_WIDTH:0] s_gray_count;
    wire [ADDR_WIDTH:0] m_gray_count;
    wire [ADDR_WIDTH:0] s_gray_count_sync;
    wire [ADDR_WIDTH:0] m_gray_count_sync;

    // FIFO Control signals
    wire [ADDR_WIDTH:0] s_write_addr;
    wire [ADDR_WIDTH:0] m_read_addr;
    wire s_fifo_full;
    wire m_fifo_empty;
    wire s_fifo_almost_full;
    wire m_fifo_almost_empty;

    // FIFO Status signals
    wire [ADDR_WIDTH:0] s_fifo_depth;
    wire [ADDR_WIDTH:0] s_fifo_depth_commit;
    wire s_fifo_overflow;
    wire s_fifo_bad_frame;
    wire s_fifo_good_frame;
    wire [ADDR_WIDTH:0] m_fifo_depth;
    wire [ADDR_WIDTH:0] m_fifo_depth_commit;
    wire m_fifo_overflow;
    wire m_fifo_bad_frame;
    wire m_fifo_good_frame;

    // FIFO RAM signals
    wire [DATA_WIDTH-1:0] fifo_rd_data;
    wire [KEEP_WIDTH-1:0] fifo_rd_keep;
    wire fifo_rd_last;
    wire [ID_WIDTH-1:0] fifo_rd_id;
    wire [DEST_WIDTH-1:0] fifo_rd_dest;
    wire [USER_WIDTH-1:0] fifo_rd_user;

    // Instantiate CDC Gray Code Counters
    cdc_gray_counter #(.WIDTH(ADDR_WIDTH+1)) s_gray_counter (
        .clk(s_clk),
        .rst(s_rst),
        .gray_count(s_gray_count)
    );

    cdc_gray_counter #(.WIDTH(ADDR_WIDTH+1)) m_gray_counter (
        .clk(m_clk),
        .rst(m_rst),
        .gray_count(m_gray_count)
    );

    // Instantiate CDC Gray Code Synchronizers
    cdc_gray_sync #(.WIDTH(ADDR_WIDTH+1)) s_gray_sync (
        .clk_src(s_clk),
        .rst_src(s_rst),
        .gray_count_src(s_gray_count),
        .clk_dst(m_clk),
        .rst_dst(m_rst),
        .gray_count_sync(m_gray_count_sync)
    );

    cdc_gray_sync #(.WIDTH(ADDR_WIDTH+1)) m_gray_sync (
        .clk_src(m_clk),
        .rst_src(m_rst),
        .gray_count_src(m_gray_count),
        .clk_dst(s_clk),
        .rst_dst(s_rst),
        .gray_count_sync(s_gray_count_sync)
    );

    // Instantiate FIFO RAM
    fifo_ram #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH)
    ) data_fifo (
        .wr_clk(s_clk),
        .wr_rst(s_rst),
        .wr_addr(s_write_addr),
        .wr_data(s_axis_tdata),
        .wr_keep(s_axis_tkeep),
        .wr_last(s_axis_tlast),
        .wr_id(s_axis_tid),
        .wr_dest(s_axis_tdest),
        .wr_user(s_axis_tuser),
        .rd_clk(m_clk),
        .rd_rst(m_rst),
        .rd_addr(m_read_addr),
        .rd_data(fifo_rd_data),
        .rd_keep(fifo_rd_keep),
        .rd_last(fifo_rd_last),
        .rd_id(fifo_rd_id),
        .rd_dest(fifo_rd_dest),
        .rd_user(fifo_rd_user)
    );

    // Instantiate FIFO Control for Slave (Write Side)
    fifo_control #(
        .DEPTH(DEPTH),
        .RAM_PIPELINE(RAM_PIPELINE),
        .DROP_WHEN_FULL(DROP_WHEN_FULL),
        .MARK_WHEN_FULL(MARK_WHEN_FULL),
        .PAUSE_ENABLE(PAUSE_ENABLE),
        .FRAME_PAUSE(FRAME_PAUSE)
    ) s_fifo_control (
        .clk(s_clk),
        .rst(s_rst),
        .write_addr(s_write_addr),
        .gray_count_sync(m_gray_count_sync),
        .gray_count(s_gray_count),
        .fifo_full(s_fifo_full),
        .fifo_almost_full(s_fifo_almost_full),
        .tvalid(s_axis_tvalid),
        .tready(s_axis_tready),
        .tlast(s_axis_tlast),
        .pause_req(s_pause_req),
        .pause_ack(s_pause_ack)
    );

    // Instantiate FIFO Control for Master (Read Side)
    fifo_control #(
        .DEPTH(DEPTH),
        .RAM_PIPELINE(RAM_PIPELINE),
        .DROP_WHEN_FULL(0),
        .MARK_WHEN_FULL(0),
        .PAUSE_ENABLE(PAUSE_ENABLE),
        .FRAME_PAUSE(FRAME_PAUSE)
    ) m_fifo_control (
        .clk(m_clk),
        .rst(m_rst),
        .read_addr(m_read_addr),
        .gray_count_sync(s_gray_count_sync),
        .gray_count(m_gray_count),
        .fifo_empty(m_fifo_empty),
        .fifo_almost_empty(m_fifo_almost_empty),
        .tvalid(m_axis_tvalid),
        .tready(m_axis_tready),
        .tlast(fifo_rd_last),
        .pause_req(m_pause_req),
        .pause_ack(m_pause_ack)
    );

    // Instantiate FIFO Status for Slave (Write Side)
    fifo_status #(
        .DEPTH(DEPTH),
        .LAST_ENABLE(LAST_ENABLE),
        .USER_ENABLE(USER_ENABLE),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_BAD_FRAME(DROP_BAD_FRAME)
    ) s_fifo_status (
        .clk(s_clk),
        .rst(s_rst),
        .write_addr(s_write_addr),
        .gray_count_sync(m_gray_count_sync),
        .gray_count(s_gray_count),
        .tvalid(s_axis_tvalid),
        .tlast(s_axis_tlast),
        .tuser(s_axis_tuser),
        .depth(s_fifo_depth),
        .depth_commit(s_fifo_depth_commit),
        .overflow(s_fifo_overflow),
        .bad_frame(s_fifo_bad_frame),
        .good_frame(s_fifo_good_frame)
    );

    // Instantiate FIFO Status for Master (Read Side)
    fifo_status #(
        .DEPTH(DEPTH),
        .LAST_ENABLE(LAST_ENABLE),
        .USER_ENABLE(USER_ENABLE),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_BAD_FRAME(DROP_BAD_FRAME)
    ) m_fifo_status (
        .clk(m_clk),
        .rst(m_rst),
        .write_addr(s_write_addr),
        .gray_count_sync(m_gray_count_sync),
        .gray_count(m_gray_count),
        .tvalid(s_axis_tvalid),
        .tlast(fifo_rd_last),
        .tuser(fifo_rd_user),
        .depth(m_fifo_depth),
        .depth_commit(m_fifo_depth_commit),
        .overflow(m_fifo_overflow),
        .bad_frame(m_fifo_bad_frame),
        .good_frame(m_fifo_good_frame)
    );

    // Assign output signals
    assign m_axis_tdata = fifo_rd_data;
    assign m_axis_tkeep = fifo_rd_keep;
    assign m_axis_tlast = fifo_rd_last;
    assign m_axis_tid = fifo_rd_id;
    assign m_axis_tdest = fifo_rd_dest;
    assign m_axis_tuser = fifo_rd_user;

    assign s_status_depth = s_fifo_depth;
    assign s_status_depth_commit = s_fifo_depth_commit;
    assign s_status_overflow = s_fifo_overflow;
    assign s_status_bad_frame = s_fifo_bad_frame;
    assign s_status_good_frame = s_fifo_good_frame;

    assign m_status_depth = m_fifo_depth;
    assign m_status_depth_commit = m_fifo_depth_commit;
    assign m_status_overflow = m_fifo_overflow;
    assign m_status_bad_frame = m_fifo_bad_frame;
    assign m_status_good_frame = m_fifo_good_frame;

endmodule

// CDC Gray Code Counter
module cdc_gray_counter #
(
    parameter WIDTH = 9
)
(
    input  wire clk,
    input  wire rst,
    output reg [WIDTH-1:0] gray_count
);

    reg [WIDTH-1:0] bin_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bin_count <= 0;
            gray_count <= 0;
        end else begin
            bin_count <= bin_count + 1;
            gray_count <= (bin_count >> 1) ^ bin_count;
        end
    end

endmodule

// CDC Gray Code Synchronizer
module cdc_gray_sync #
(
    parameter WIDTH = 9
)
(
    input  wire clk_src,
    input  wire rst_src,
    input  wire [WIDTH-1:0] gray_count_src,
    input  wire clk_dst,
    input  wire rst_dst,
    output reg [WIDTH-1:0] gray_count_sync
);

    reg [WIDTH-1:0] meta;

    always @(posedge clk_src or posedge rst_src) begin
        if (rst_src) begin
            meta <= 0;
        end else begin
            meta <= gray_count_src;
        end
    end

    always @(posedge clk_dst or posedge rst_dst) begin
        if (rst_dst) begin
            gray_count_sync <= 0;
        end else begin
            gray_count_sync <= meta;
        end
    end

endmodule

// FIFO RAM
module fifo_ram #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = 1,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter USER_WIDTH = 1
)
(
    input  wire wr_clk,
    input  wire wr_rst,
    input  wire [$clog2(DEPTH):0] wr_addr,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire [KEEP_WIDTH-1:0] wr_keep,
    input  wire wr_last,
    input  wire [ID_WIDTH-1:0] wr_id,
    input  wire [DEST_WIDTH-1:0] wr_dest,
    input  wire [USER_WIDTH-1:0] wr_user,
    input  wire rd_clk,
    input  wire rd_rst,
    input  wire [$clog2(DEPTH):0] rd_addr,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire [KEEP_WIDTH-1:0] rd_keep,
    output wire rd_last,
    output wire [ID_WIDTH-1:0] rd_id,
    output wire [DEST_WIDTH-1:0] rd_dest,
    output wire [USER_WIDTH-1:0] rd_user
);

    reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] mem_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] mem_user [0:DEPTH-1];

    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            mem_data <= '{default: 0};
            mem_keep <= '{default: 0};
            mem_last <= '{default: 0};
            mem_id <= '{default: 0};
            mem_dest <= '{default: 0};
            mem_user <= '{default: 0};
        end else begin
            mem_data[wr_addr] <= wr_data;
            mem_keep[wr_addr] <= wr_keep;
            mem_last[wr_addr] <= wr_last;
            mem_id[wr_addr] <= wr_id;
            mem_dest[wr_addr] <= wr_dest;
            mem_user[wr_addr] <= wr_user;
        end
    end

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_data <= 0;
            rd_keep <= 0;
            rd_last <= 0;
            rd_id <= 0;
            rd_dest <= 0;
            rd_user <= 0;
        end else begin
            rd_data <= mem_data[rd_addr];
            rd_keep <= mem_keep[rd_addr];
            rd_last <= mem_last[rd_addr];
            rd_id <= mem_id[rd_addr];
            rd_dest <= mem_dest[rd_addr];
            rd_user <= mem_user[rd_addr];
        end
    end

endmodule

// FIFO Control
module fifo_control #
(
    parameter DEPTH = 4096,
    parameter RAM_PIPELINE = 1,
    parameter DROP_WHEN_FULL = 0,
    parameter MARK_WHEN_FULL = 0,
    parameter PAUSE_ENABLE = 0,
    parameter FRAME_PAUSE = 0
)
(
    input  wire clk,
    input  wire rst,
    output reg [$clog2(DEPTH):0] write_addr,
    input  wire [$clog2(DEPTH):0] gray_count_sync,
    input  wire [$clog2(DEPTH):0] gray_count,
    output wire fifo_full,
    output wire fifo_almost_full,
    input  wire tvalid,
    output reg tready,
    input  wire tlast,
    input  wire pause_req,
    output reg pause_ack
);

    reg [$clog2(DEPTH):0] write_ptr;
    reg [$clog2(DEPTH):0] read_ptr_sync;

    wire [$clog2(DEPTH):0] write_ptr_gray;
    wire [$clog2(DEPTH):0] read_ptr_gray_sync;

    assign write_ptr_gray = (write_ptr >> 1) ^ write_ptr;
    assign read_ptr_gray_sync = gray_count_sync;

    assign fifo_full = (write_ptr_gray == read_ptr_gray_sync + DEPTH);
    assign fifo_almost_full = (write_ptr_gray == read_ptr_gray_sync + DEPTH - 1);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_ptr <= 0;
            read_ptr_sync <= 0;
            tready <= 1;
            pause_ack <= 0;
        end else begin
            read_ptr_sync <= gray_count;

            if (tvalid && tready) begin
                if (!fifo_full) begin
                    write_ptr <= write_ptr + 1;
                end
            end

            if (PAUSE_ENABLE) begin
                if (pause_req && !fifo_full) begin
                    tready <= 0;
                    pause_ack <= 1;
                end else if (tready && !pause_req) begin
                    pause_ack <= 0;
                end
            end else begin
                tready <= !fifo_full;
            end
        end
    end

endmodule

// FIFO Status
module fifo_status #
(
    parameter DEPTH = 4096,
    parameter LAST_ENABLE = 1,
    parameter USER_ENABLE = 1,
    parameter USER_BAD_FRAME_VALUE = 1'b1,
    parameter USER_BAD_FRAME_MASK = 1'b1,
    parameter DROP_BAD_FRAME = 0
)
(
    input  wire clk,
    input  wire rst,
    input  wire [$clog2(DEPTH):0] write_addr,
    input  wire [$clog2(DEPTH):0] gray_count_sync,
    input  wire [$clog2(DEPTH):0] gray_count,
    input  wire tvalid,
    input  wire tlast,
    input  wire [USER_WIDTH-1:0] tuser,
    output reg [$clog2(DEPTH):0] depth,
    output reg [$clog2(DEPTH):0] depth_commit,
    output reg overflow,
    output reg bad_frame,
    output reg good_frame
);

    reg [$clog2(DEPTH):0] write_ptr_gray;
    reg [$clog2(DEPTH):0] read_ptr_gray_sync;
    reg frame_started;
    reg frame_ended;

    assign write_ptr_gray = (write_addr >> 1) ^ write_addr;
    assign read_ptr_gray_sync = gray_count_sync;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            depth <= 0;
            depth_commit <= 0;
            overflow <= 0;
            bad_frame <= 0;
            good_frame <= 0;
            frame_started <= 0;
            frame_ended <= 0;
        end else begin
            if (tvalid) begin
                if (!frame_started) begin
                    frame_started <= 1;
                    frame_ended <= 0;
                end

                if (tlast) begin
                    frame_ended <= 1;
                    frame_started <= 0;
                end

                if (USER_ENABLE && (tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                    bad_frame <= 1;
                end else begin
                    good_frame <= 1;
                end
            end

            if (write_ptr_gray == read_ptr_gray_sync + DEPTH) begin
                overflow <= 1;
            end

            if (write_ptr_gray != read_ptr_gray_sync) begin
                depth <= write_ptr_gray - read_ptr_gray_sync;
            end else begin
                depth <= 0;
            end

            if (tvalid && tready) begin
                depth_commit <= depth;
                overflow <= 0;
                bad_frame <= 0;
                good_frame <= 0;
            end
        end
    end

endmodule
