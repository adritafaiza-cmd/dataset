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

    /*
     * Internal signals
     */
    wire s_cb_wr_en;
    wire [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] s_cb_din;
    wire s_cb_rd_en;
    wire [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] s_cb_dout;
    wire s_cb_full;
    wire s_cb_empty;
    wire s_cb_almost_full;
    wire s_cb_almost_empty;
    wire [$clog2(DEPTH):0] s_cb_data_count;
    wire s_cb_prog_full;
    wire s_cb_prog_empty;
    wire s_cb_wr_rst_busy;
    wire s_cb_rd_rst_busy;
    wire [$clog2(DEPTH)-1:0] s_cb_addr_gray;

    wire m_cb_wr_en;
    wire [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] m_cb_din;
    wire m_cb_rd_en;
    wire [DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH-1:0] m_cb_dout;
    wire m_cb_full;
    wire m_cb_empty;
    wire m_cb_almost_full;
    wire m_cb_almost_empty;
    wire [$clog2(DEPTH):0] m_cb_data_count;
    wire m_cb_prog_full;
    wire m_cb_prog_empty;
    wire m_cb_wr_rst_busy;
    wire m_cb_rd_rst_busy;
    wire [$clog2(DEPTH)-1:0] m_cb_addr_gray;

    wire s_cb_wr_sync_out;
    wire m_cb_wr_sync_out;
    wire s_cb_full_sync_out;
    wire m_cb_full_sync_out;

    /*
     * Circular buffers
     */
    circular_buffer #(
        .DATA_WIDTH(DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH),
        .DEPTH(DEPTH)
    ) s_cb (
        .clk(s_clk),
        .rst(s_rst),
        .wr_en(s_cb_wr_en),
        .din(s_cb_din),
        .rd_en(s_cb_rd_en),
        .dout(s_cb_dout),
        .full(s_cb_full),
        .empty(s_cb_empty),
        .almost_full(s_cb_almost_full),
        .almost_empty(s_cb_almost_empty),
        .data_count(s_cb_data_count),
        .prog_full(s_cb_prog_full),
        .prog_empty(s_cb_prog_empty),
        .wr_rst_busy(s_cb_wr_rst_busy),
        .rd_rst_busy(s_cb_rd_rst_busy),
        .addr_gray(s_cb_addr_gray)
    );

    circular_buffer #(
        .DATA_WIDTH(DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE*ID_WIDTH+DEST_ENABLE*DEST_WIDTH+USER_ENABLE*USER_WIDTH),
        .DEPTH(DEPTH)
    ) m_cb (
        .clk(m_clk),
        .rst(m_rst),
        .wr_en(m_cb_wr_en),
        .din(m_cb_din),
        .rd_en(m_cb_rd_en),
        .dout(m_cb_dout),
        .full(m_cb_full),
        .empty(m_cb_empty),
        .almost_full(m_cb_almost_full),
        .almost_empty(m_cb_almost_empty),
        .data_count(m_cb_data_count),
        .prog_full(m_cb_prog_full),
        .prog_empty(m_cb_prog_empty),
        .wr_rst_busy(m_cb_wr_rst_busy),
        .rd_rst_busy(m_cb_rd_rst_busy),
        .addr_gray(m_cb_addr_gray)
    );

    /*
     * Cross-clock synchronization
     */
    cross_clock_sync s_cb_wr_sync (
        .clk(m_clk),
        .rst(m_rst),
        .data_in(s_cb_wr_en),
        .data_out(s_cb_wr_sync_out)
    );

    cross_clock_sync m_cb_wr_sync (
        .clk(s_clk),
        .rst(s_rst),
        .data_in(m_cb_wr_en),
        .data_out(m_cb_wr_sync_out)
    );

    cross_clock_sync s_cb_full_sync (
        .clk(m_clk),
        .rst(m_rst),
        .data_in(s_cb_full),
        .data_out(s_cb_full_sync_out)
    );

    cross_clock_sync m_cb_full_sync (
        .clk(s_clk),
        .rst(s_rst),
        .data_in(m_cb_full),
        .data_out(m_cb_full_sync_out)
    );

    /*
     * Connections
     */
    assign s_cb_wr_en = s_axis_tvalid && s_axis_tready;
    assign s_cb_din = {s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser};
    assign s_cb_rd_en = s_cb_wr_sync_out;
    assign m_cb_wr_en = m_axis_tready && m_axis_tvalid;
    assign m_cb_din = s_cb_dout;
    assign m_cb_rd_en = m_axis_tready;
    assign m_axis_tdata = m_cb_dout[DATA_WIDTH-1:0];
    assign m_axis_tkeep = m_cb_dout[DATA_WIDTH+KEEP_WIDTH-1:DATA_WIDTH];
    assign m_axis_tlast = m_cb_dout[DATA_WIDTH+KEEP_WIDTH];
    assign m_axis_tid = m_cb_dout[DATA_WIDTH+KEEP_WIDTH+ID_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+1];
    assign m_axis_tdest = m_cb_dout[DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+1];
    assign m_axis_tuser = m_cb_dout[DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH+1];
    assign m_axis_tvalid = !m_cb_empty;
    assign s_axis_tready = !s_cb_full;

    /*
     * Status outputs
     */
    assign s_status_depth = s_cb_data_count;
    assign s_status_depth_commit = s_cb_data_count;
    assign s_status_overflow = s_cb_full;
    assign s_status_bad_frame = 1'b0; // Not implemented
    assign s_status_good_frame = 1'b0; // Not implemented
    assign m_status_depth = m_cb_data_count;
    assign m_status_depth_commit = m_cb_data_count;
    assign m_status_overflow = m_cb_full;
    assign m_status_bad_frame = 1'b0; // Not implemented
    assign m_status_good_frame = 1'b0; // Not implemented

    /*
     * Pause outputs
     */
    assign s_pause_ack = 1'b0; // Not implemented
    assign m_pause_ack = 1'b0; // Not implemented

endmodule

module circular_buffer #
(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 1024
)
(
    input  wire clk,
    input  wire rst,
    input  wire wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    input  wire rd_en,
    output reg [DATA_WIDTH-1:0] dout,
    output reg full,
    output reg empty,
    output reg almost_full,
    output reg almost_empty,
    output reg [$clog2(DEPTH):0] data_count,
    output reg prog_full,
    output reg prog_empty,
    output reg wr_rst_busy,
    output reg rd_rst_busy,
    output reg [$clog2(DEPTH)-1:0] addr_gray
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 0;
            empty <= 1;
            almost_full <= 0;
            almost_empty <= 1;
            data_count <= 0;
            prog_full <= 0;
            prog_empty <= 1;
            wr_rst_busy <= 0;
            rd_rst_busy <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
            end

            full <= (wr_ptr == {~rd_ptr[ADDR_WIDTH-1:1], rd_ptr[ADDR_WIDTH-1]});
            empty <= (wr_ptr == rd_ptr);
            almost_full <= (wr_ptr == {~rd_ptr[ADDR_WIDTH-1], rd_ptr[ADDR_WIDTH-2:0], rd_ptr[ADDR_WIDTH-1]});
            almost_empty <= (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-2:0], rd_ptr[ADDR_WIDTH-1], rd_ptr[ADDR_WIDTH-1]);
            data_count <= wr_ptr - rd_ptr;
            prog_full <= (wr_ptr == {~rd_ptr[ADDR_WIDTH-1], rd_ptr[ADDR_WIDTH-2:0], rd_ptr[ADDR_WIDTH-1]});
            prog_empty <= (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-2:0], rd_ptr[ADDR_WIDTH-1], rd_ptr[ADDR_WIDTH-1]);
            wr_rst_busy <= 0; // Not implemented
            rd_rst_busy <= 0; // Not implemented
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (rd_en && !empty) begin
            dout <= mem[rd_ptr];
        end
    end

    always @(wr_ptr or rd_ptr) begin
        addr_gray = wr_ptr ^ (wr_ptr >> 1);
    end

endmodule

module cross_clock_sync (
    input  wire clk,
    input  wire rst,
    input  wire data_in,
    output reg  data_out
);

    reg sync_reg1;
    reg sync_reg2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_reg1 <= 1'b0;
            sync_reg2 <= 1'b0;
            data_out <= 1'b0;
        end else begin
            sync_reg1 <= data_in;
            sync_reg2 <= sync_reg1;
            data_out <= sync_reg2;
        end
    end

endmodule
