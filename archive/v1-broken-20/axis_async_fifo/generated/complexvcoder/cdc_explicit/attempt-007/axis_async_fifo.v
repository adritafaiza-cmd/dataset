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
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
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

    // Internal signals
    logic [DATA_WIDTH-1:0] s_axis_tdata_reg;
    logic [KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    logic s_axis_tvalid_reg;
    logic s_axis_tlast_reg;
    logic [ID_WIDTH-1:0] s_axis_tid_reg;
    logic [DEST_WIDTH-1:0] s_axis_tdest_reg;
    logic [USER_WIDTH-1:0] s_axis_tuser_reg;

    logic m_axis_tdata_reg;
    logic [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    logic m_axis_tvalid_reg;
    logic m_axis_tlast_reg;
    logic [ID_WIDTH-1:0] m_axis_tid_reg;
    logic [DEST_WIDTH-1:0] m_axis_tdest_reg;
    logic [USER_WIDTH-1:0] m_axis_tuser_reg;

    logic [DEPTH-1:0] s_fifo_data;
    logic [DEPTH-1:0] m_fifo_data;

    logic [DEPTH-1:0] s_fifo_valid;
    logic [DEPTH-1:0] m_fifo_valid;

    logic [DEPTH-1:0] s_fifo_ready;
    logic [DEPTH-1:0] m_fifo_ready;

    logic [DEPTH-1:0] s_fifo_depth;
    logic [DEPTH-1:0] m_fifo_depth;

    logic s_fifo_overflow;
    logic m_fifo_overflow;

    logic s_fifo_bad_frame;
    logic m_fifo_bad_frame;

    logic s_fifo_good_frame;
    logic m_fifo_good_frame;

    // FIFOs
    axis_async_fifo_core #(
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
    ) s_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .tdata(s_axis_tdata),
        .tkeep(s_axis_tkeep),
        .tvalid(s_axis_tvalid),
        .tready(s_axis_tready),
        .tlast(s_axis_tlast),
        .tid(s_axis_tid),
        .tdest(s_axis_tdest),
        .tuser(s_axis_tuser),
        .data_out(s_fifo_data),
        .valid_out(s_fifo_valid),
        .ready_out(s_fifo_ready),
        .depth_out(s_fifo_depth),
        .overflow_out(s_fifo_overflow),
        .bad_frame_out(s_fifo_bad_frame),
        .good_frame_out(s_fifo_good_frame)
    );

    axis_async_fifo_core #(
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
    ) m_fifo (
        .clk(m_clk),
        .rst(m_rst),
        .tdata(s_fifo_data),
        .tkeep(s_fifo_valid),
        .tvalid(s_fifo_valid),
        .tready(m_axis_tready),
        .tlast(s_fifo_last),
        .tid(s_fifo_tid),
        .tdest(s_fifo_tdest),
        .tuser(s_fifo_tuser),
        .data_out(m_axis_tdata),
        .valid_out(m_axis_tvalid),
        .ready_out(m_axis_tready),
        .depth_out(m_fifo_depth),
        .overflow_out(m_fifo_overflow),
        .bad_frame_out(m_fifo_bad_frame),
        .good_frame_out(m_fifo_good_frame)
    );

    // Pause control
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    // Status signals
    assign s_status_depth = s_fifo_depth;
    assign s_status_depth_commit = s_fifo_depth;
    assign s_status_overflow = s_fifo_overflow;
    assign s_status_bad_frame = s_fifo_bad_frame;
    assign s_status_good_frame = s_fifo_good_frame;

    assign m_status_depth = m_fifo_depth;
    assign m_status_depth_commit = m_fifo_depth;
    assign m_status_overflow = m_fifo_overflow;
    assign m_status_bad_frame = m_fifo_bad_frame;
    assign m_status_good_frame = m_fifo_good_frame;

endmodule

module axis_async_fifo_core #
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
    input  wire [DATA_WIDTH-1:0]  tdata,
    input  wire [KEEP_WIDTH-1:0]  tkeep,
    input  wire                   tvalid,
    output wire                   tready,
    input  wire                   tlast,
    input  wire [ID_WIDTH-1:0]    tid,
    input  wire [DEST_WIDTH-1:0]  tdest,
    input  wire [USER_WIDTH-1:0]  tuser,
    output wire [DATA_WIDTH-1:0]  data_out,
    output wire [KEEP_WIDTH-1:0]  valid_out,
    output wire                   ready_out,
    output wire                   depth_out,
    output wire                   overflow_out,
    output wire                   bad_frame_out,
    output wire                   good_frame_out
);

    // Internal signals
    logic [DATA_WIDTH-1:0] fifo_data [0:DEPTH-1];
    logic [DEPTH-1:0] fifo_valid;
    logic [DEPTH-1:0] fifo_ready;
    logic [DEPTH-1:0] fifo_depth;
    logic overflow;
    logic bad_frame;
    logic good_frame;

    // FIFO logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_valid <= 0;
            fifo_ready <= 0;
            fifo_depth <= 0;
            overflow <= 0;
            bad_frame <= 0;
            good_frame <= 0;
        end else begin
            if (tvalid && tready) begin
                fifo_data[fifo_depth] <= tdata;
                fifo_valid[fifo_depth] <= tvalid;
                fifo_depth <= fifo_depth + 1;
                if (fifo_depth == DEPTH - 1) begin
                    overflow <= 1;
                end
            end
            if (m_axis_tready) begin
                fifo_depth <= fifo_depth - 1;
                overflow <= 0;
            end
        end
    end

    // Output logic
    assign data_out = fifo_data[0];
    assign valid_out = fifo_valid[0];
    assign ready_out = (fifo_depth < DEPTH);
    assign depth_out = fifo_depth;
    assign overflow_out = overflow;
    assign bad_frame_out = bad_frame;
    assign good_frame_out = good_frame;

endmodule
