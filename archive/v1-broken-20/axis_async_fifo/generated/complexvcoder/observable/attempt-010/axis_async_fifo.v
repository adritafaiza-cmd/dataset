module axis_async_fifo #(
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

    wire s_axis_tready_reg;
    wire m_axis_tvalid_reg;
    wire m_axis_tready_reg;
    wire s_pause_ack_reg;
    wire m_pause_ack_reg;
    wire [DEPTH-1:0] s_fifo_din;
    wire [DEPTH-1:0] s_fifo_dout;
    wire [DEPTH-1:0] m_fifo_din;
    wire [DEPTH-1:0] m_fifo_dout;
    reg [DEPTH-1:0] s_fifo_rptr;
    reg [DEPTH-1:0] s_fifo_wptr;
    reg [DEPTH-1:0] m_fifo_rptr;
    reg [DEPTH-1:0] m_fifo_wptr;
    reg [DEPTH-1:0] s_fifo_depth;
    reg [DEPTH-1:0] m_fifo_depth;
    reg s_fifo_full;
    reg m_fifo_full;
    reg s_fifo_overflow;
    reg m_fifo_overflow;
    reg s_fifo_bad_frame;
    reg m_fifo_bad_frame;
    reg s_fifo_good_frame;
    reg m_fifo_good_frame;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_fifo_rptr <= 0;
            s_fifo_wptr <= 0;
            s_fifo_full <= 0;
            s_fifo_overflow <= 0;
            s_fifo_bad_frame <= 0;
            s_fifo_good_frame <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                s_fifo_din[s_fifo_wptr] <= s_axis_tdata;
                s_fifo_keep[s_fifo_wptr] <= s_axis_tkeep;
                s_fifo_last[s_fifo_wptr] <= s_axis_tlast;
                s_fifo_id[s_fifo_wptr] <= s_axis_tid;
                s_fifo_dest[s_fifo_wptr] <= s_axis_tdest;
                s_fifo_user[s_fifo_wptr] <= s_axis_tuser;
                s_fifo_wptr <= (s_fifo_wptr + 1) % DEPTH;
                if (s_fifo_wptr == s_fifo_rptr) begin
                    s_fifo_full <= 1;
                end
            end
            if (m_axis_tready) begin
                s_fifo_rptr <= (s_fifo_rptr + 1) % DEPTH;
                s_fifo_full <= 0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_fifo_rptr <= 0;
            m_fifo_wptr <= 0;
            m_fifo_full <= 0;
            m_fifo_overflow <= 0;
            m_fifo_bad_frame <= 0;
            m_fifo_good_frame <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                m_fifo_din[m_fifo_wptr] <= m_axis_tdata;
                m_fifo_keep[m_fifo_wptr] <= m_axis_tkeep;
                m_fifo_last[m_fifo_wptr] <= m_axis_tlast;
                m_fifo_id[m_fifo_wptr] <= m_axis_tid;
                m_fifo_dest[m_fifo_wptr] <= m_axis_tdest;
                m_fifo_user[m_fifo_wptr] <= m_axis_tuser;
                m_fifo_wptr <= (m_fifo_wptr + 1) % DEPTH;
                if (m_fifo_wptr == m_fifo_rptr) begin
                    m_fifo_full <= 1;
                end
            end
            if (s_axis_tready) begin
                m_fifo_rptr <= (m_fifo_rptr + 1) % DEPTH;
                m_fifo_full <= 0;
            end
        end
    end

    assign s_axis_tready = !s_fifo_full;
    assign m_axis_tvalid = !m_fifo_full;
    assign m_axis_tready = m_axis_tready_reg;
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;
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
