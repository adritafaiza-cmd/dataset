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

    wire [S_DATA_WIDTH-1:0] s_fifo_data_out;
    wire [S_KEEP_WIDTH-1:0] s_fifo_keep_out;
    wire s_fifo_valid_out;
    wire s_fifo_last_out;
    wire [ID_WIDTH-1:0] s_fifo_id_out;
    wire [DEST_WIDTH-1:0] s_fifo_dest_out;
    wire [USER_WIDTH-1:0] s_fifo_user_out;
    wire m_fifo_ready_in;
    wire [M_DATA_WIDTH-1:0] width_adapter_output_data;
    wire [M_KEEP_WIDTH-1:0] width_adapter_output_keep;
    wire width_adapter_output_valid;
    wire width_adapter_output_last;
    wire [ID_WIDTH-1:0] width_adapter_output_id;
    wire [DEST_WIDTH-1:0] width_adapter_output_dest;
    wire [USER_WIDTH-1:0] width_adapter_output_user;

    fifo #(
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
        .RAM_PIPELINE(RAM_PIPELINE)
    ) s_fifo (
        .data_in(s_axis_tdata),
        .keep_in(s_axis_tkeep),
        .valid_in(s_axis_tvalid),
        .ready_out(s_axis_tready),
        .last_in(s_axis_tlast),
        .id_in(s_axis_tid),
        .dest_in(s_axis_tdest),
        .user_in(s_axis_tuser),
        .clk(s_clk),
        .rst(s_rst),
        .data_out(s_fifo_data_out),
        .keep_out(s_fifo_keep_out),
        .valid_out(s_fifo_valid_out),
        .last_out(s_fifo_last_out),
        .id_out(s_fifo_id_out),
        .dest_out(s_fifo_dest_out),
        .user_out(s_fifo_user_out),
        .depth_commit(s_status_depth_commit),
        .overflow(s_status_overflow),
        .bad_frame(s_status_bad_frame),
        .good_frame(s_status_good_frame)
    );

    width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .USER_BAD_FRAME_VALUE(USER_BAD_FRAME_VALUE),
        .USER_BAD_FRAME_MASK(USER_BAD_FRAME_MASK),
        .DROP_OVERSIZE_FRAME(DROP_OVERSIZE_FRAME),
        .DROP_BAD_FRAME(DROP_BAD_FRAME),
        .DROP_WHEN_FULL(DROP_WHEN_FULL),
        .MARK_WHEN_FULL(MARK_WHEN_FULL),
        .PAUSE_ENABLE(PAUSE_ENABLE)
    ) width_adapter (
        .input_data(s_fifo_data_out),
        .input_keep(s_fifo_keep_out),
        .input_valid(s_fifo_valid_out),
        .input_last(s_fifo_last_out),
        .input_id(s_fifo_id_out),
        .input_dest(s_fifo_dest_out),
        .input_user(s_fifo_user_out),
        .output_ready(m_axis_tready),
        .output_data(width_adapter_output_data),
        .output_keep(width_adapter_output_keep),
        .output_valid(width_adapter_output_valid),
        .output_last(width_adapter_output_last),
        .output_id(width_adapter_output_id),
        .output_dest(width_adapter_output_dest),
        .output_user(width_adapter_output_user),
        .s_pause_req(s_pause_req),
        .s_pause_ack(s_pause_ack),
        .m_pause_req(m_pause_req),
        .m_pause_ack(m_pause_ack)
    );

    fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(M_DATA_WIDTH),
        .KEEP_ENABLE(M_KEEP_ENABLE),
        .KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE)
    ) m_fifo (
        .data_in(width_adapter_output_data),
        .keep_in(width_adapter_output_keep),
        .valid_in(width_adapter_output_valid),
        .ready_out(width_adapter_output_ready),
        .last_in(width_adapter_output_last),
        .id_in(width_adapter_output_id),
        .dest_in(width_adapter_output_dest),
        .user_in(width_adapter_output_user),
        .clk(m_clk),
        .rst(m_rst),
        .data_out(m_axis_tdata),
        .keep_out(m_axis_tkeep),
        .valid_out(m_axis_tvalid),
        .last_out(m_axis_tlast),
        .id_out(m_axis_tid),
        .dest_out(m_axis_tdest),
        .user_out(m_axis_tuser),
        .depth_commit(m_status_depth_commit),
        .overflow(m_status_overflow),
        .bad_frame(m_status_bad_frame),
        .good_frame(m_status_good_frame)
    );

    assign s_status_depth = s_fifo.depth;
    assign m_status_depth = m_fifo.depth;

endmodule
