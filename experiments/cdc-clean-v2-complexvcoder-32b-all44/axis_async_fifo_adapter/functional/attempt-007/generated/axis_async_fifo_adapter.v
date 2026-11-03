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

localparam ADDR_WIDTH = $clog2(DEPTH);

// FIFO control signals
reg [ADDR_WIDTH:0] s_wr_ptr, s_wr_ptr_gray, s_wr_ptr_gray_nxt, s_wr_ptr_gray_r;
reg [ADDR_WIDTH:0] m_rd_ptr, m_rd_ptr_gray, m_rd_ptr_gray_nxt, m_rd_ptr_gray_r;
reg [ADDR_WIDTH:0] s_wr_ptr_gray_sync, m_rd_ptr_gray_sync;

// FIFO data signals
reg [S_DATA_WIDTH-1:0] fifo_data [0:DEPTH-1];
reg [S_KEEP_WIDTH-1:0] fifo_keep [0:DEPTH-1];
reg [USER_WIDTH-1:0] fifo_user [0:DEPTH-1];
reg fifo_tlast [0:DEPTH-1];
reg [ID_WIDTH-1:0] fifo_tid [0:DEPTH-1];
reg [DEST_WIDTH-1:0] fifo_tdest [0:DEPTH-1];

// FIFO status signals
wire s_fifo_full, s_fifo_empty, m_fifo_empty;
wire [$clog2(DEPTH):0] s_fifo_depth, m_fifo_depth;

// Handshake signals
reg s_axis_tready_r, m_axis_tvalid_r, m_axis_tvalid_nxt, m_axis_tready_r;

// Status signals
reg s_status_overflow_r, s_status_bad_frame_r, s_status_good_frame_r;
reg m_status_overflow_r, m_status_bad_frame_r, m_status_good_frame_r;

// Gray code conversion
function [ADDR_WIDTH:0] bin2gray;
    input [ADDR_WIDTH:0] bin;
    begin
        bin2gray = bin ^ (bin >> 1);
    end
endfunction

// Binary code conversion
function [ADDR_WIDTH:0] gray2bin;
    input [ADDR_WIDTH:0] gray;
    reg [ADDR_WIDTH:0] bin;
    integer i;
    begin
        bin = gray;
        for (i = ADDR_WIDTH-1; i > 0; i = i - 1)
            bin[i] = bin[i] ^ bin[i-1];
        gray2bin = bin;
    end
endfunction

// Synchronous FIFO write pointer update
always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_wr_ptr <= 0;
        s_wr_ptr_gray_r <= 0;
    end else begin
        if (s_axis_tvalid && s_axis_tready_r && !s_fifo_full) begin
            s_wr_ptr <= s_wr_ptr + 1;
            s_wr_ptr_gray_r <= bin2gray(s_wr_ptr + 1);
        end
    end
end

// Synchronous FIFO read pointer update
always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_rd_ptr <= 0;
        m_rd_ptr_gray_r <= 0;
    end else begin
        if (m_axis_tvalid_r && m_axis_tready_r) begin
            m_rd_ptr <= m_rd_ptr + 1;
            m_rd_ptr_gray_r <= bin2gray(m_rd_ptr + 1);
        end
    end
end

// Gray code synchronization
always @(posedge s_clk or posedge s_rst) begin
    if (s_rst)
        s_wr_ptr_gray_sync <= 0;
    else
        s_wr_ptr_gray_sync <= m_rd_ptr_gray_r;
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst)
        m_rd_ptr_gray_sync <= 0;
    else
        m_rd_ptr_gray_sync <= s_wr_ptr_gray_r;
end

// FIFO depth calculation
assign s_fifo_depth = s_wr_ptr - gray2bin(s_wr_ptr_gray_sync);
assign m_fifo_depth = gray2bin(m_rd_ptr_gray_sync) - m_rd_ptr;

// FIFO full and empty flags
assign s_fifo_full = (s_fifo_depth == DEPTH);
assign m_fifo_empty = (m_fifo_depth == 0);

// Handshake logic
assign s_axis_tready = s_axis_tready_r & !s_fifo_full;
assign m_axis_tvalid = m_axis_tvalid_r & !m_fifo_empty;

always @(posedge s_clk or posedge s_rst) begin
    if (s_rst)
        s_axis_tready_r <= 0;
    else
        s_axis_tready_r <= s_axis_tvalid & !s_fifo_full;
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst)
        m_axis_tvalid_r <= 0;
    else
        m_axis_tvalid_r <= m_axis_tvalid_nxt;
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst)
        m_axis_tvalid_nxt <= 0;
    else if (m_axis_tready_r)
        m_axis_tvalid_nxt <= m_axis_tvalid_r & !m_fifo_empty;
end

// FIFO write logic
always @(posedge s_clk) begin
    if (s_axis_tvalid && s_axis_tready_r && !s_fifo_full) begin
        fifo_data[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
        fifo_keep[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
        fifo_user[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
        fifo_tlast[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
        fifo_tid[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
        fifo_tdest[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
    end
end

// FIFO read logic
assign m_axis_tdata = fifo_data[m_rd_ptr[ADDR_WIDTH-1:0]];
assign m_axis_tkeep = fifo_keep[m_rd_ptr[ADDR_WIDTH-1:0]];
assign m_axis_tuser = fifo_user[m_rd_ptr[ADDR_WIDTH-1:0]];
assign m_axis_tlast = fifo_tlast[m_rd_ptr[ADDR_WIDTH-1:0]];
assign m_axis_tid = fifo_tid[m_rd_ptr[ADDR_WIDTH-1:0]];
assign m_axis_tdest = fifo_tdest[m_rd_ptr[ADDR_WIDTH-1:0]];

// Status logic
always @(posedge s_clk or posedge s_rst) begin
    if (s_rst) begin
        s_status_overflow_r <= 0;
        s_status_bad_frame_r <= 0;
        s_status_good_frame_r <= 0;
    end else begin
        // Implement status logic as per requirements
        s_status_overflow_r <= s_status_overflow_r | (s_axis_tvalid && s_axis_tready_r && s_fifo_full);
        s_status_bad_frame_r <= s_status_bad_frame_r | (s_axis_tvalid && s_axis_tready_r && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
        s_status_good_frame_r <= s_status_good_frame_r | (s_axis_tvalid && s_axis_tready_r && !s_status_bad_frame_r);
    end
end

always @(posedge m_clk or posedge m_rst) begin
    if (m_rst) begin
        m_status_overflow_r <= 0;
        m_status_bad_frame_r <= 0;
        m_status_good_frame_r <= 0;
    end else begin
        // Implement status logic as per requirements
        m_status_overflow_r <= m_status_overflow_r | (m_axis_tvalid_r && m_axis_tready_r && m_fifo_full);
        m_status_bad_frame_r <= m_status_bad_frame_r | (m_axis_tvalid_r && m_axis_tready_r && (m_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);
        m_status_good_frame_r <= m_status_good_frame_r | (m_axis_tvalid_r && m_axis_tready_r && !m_status_bad_frame_r);
    end
end

// Pause logic
assign s_pause_ack = 1'b0; // Placeholder, implement pause logic as per requirements
assign m_pause_ack = 1'b0; // Placeholder, implement pause logic as per requirements

// Status outputs
assign s_status_depth = s_fifo_depth;
assign s_status_depth_commit = s_fifo_depth;
assign s_status_overflow = s_status_overflow_r;
assign s_status_bad_frame = s_status_bad_frame_r;
assign s_status_good_frame = s_status_good_frame_r;

assign m_status_depth = m_fifo_depth;
assign m_status_depth_commit = m_fifo_depth;
assign m_status_overflow = m_status_overflow_r;
assign m_status_bad_frame = m_status_bad_frame_r;
assign m_status_good_frame = m_status_good_frame_r;

endmodule
