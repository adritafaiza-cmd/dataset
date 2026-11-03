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

// Define the width of the data and control signals
localparam DATA_WIDTH_ALL = DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE * ID_WIDTH + DEST_ENABLE * DEST_WIDTH + USER_ENABLE * USER_WIDTH;

// Define the width of the RAM address
localparam ADDR_WIDTH = $clog2(DEPTH);

// Define the signals for the input and output FIFOs
reg [DATA_WIDTH_ALL-1:0] s_fifo_data;
reg [ADDR_WIDTH-1:0] s_fifo_wr_addr;
reg [ADDR_WIDTH-1:0] s_fifo_rd_addr;
reg s_fifo_empty;
reg s_fifo_full;
reg s_fifo_overflow;

reg [DATA_WIDTH_ALL-1:0] m_fifo_data;
reg [ADDR_WIDTH-1:0] m_fifo_wr_addr;
reg [ADDR_WIDTH-1:0] m_fifo_rd_addr;
reg m_fifo_empty;
reg m_fifo_full;
reg m_fifo_overflow;

// Define the signals for the clock domain crossing
reg [ADDR_WIDTH-1:0] s_fifo_depth;
reg [ADDR_WIDTH-1:0] m_fifo_depth;
reg s_fifo_depth_valid;
reg m_fifo_depth_valid;

// Define the signals for the pause and status
reg s_pause;
reg m_pause;
reg s_status_overflow_reg;
reg s_status_bad_frame_reg;
reg s_status_good_frame_reg;
reg m_status_overflow_reg;
reg m_status_bad_frame_reg;
reg m_status_good_frame_reg;

// Input FIFO
always @(posedge s_clk) begin
    if (s_rst) begin
        s_fifo_wr_addr <= 0;
        s_fifo_rd_addr <= 0;
        s_fifo_empty <= 1;
        s_fifo_full <= 0;
        s_fifo_overflow <= 0;
    end else begin
        if (s_axis_tvalid && !s_fifo_full) begin
            s_fifo_data[s_fifo_wr_addr] <= {s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser};
            if (s_fifo_wr_addr == DEPTH - 1) begin
                s_fifo_wr_addr <= 0;
            end else begin
                s_fifo_wr_addr <= s_fifo_wr_addr + 1;
            end
            if (s_fifo_empty) begin
                s_fifo_empty <= 0;
            end
            if (s_fifo_wr_addr == s_fifo_rd_addr) begin
                s_fifo_full <= 1;
            end
        end
        if (s_axis_tready && !s_fifo_empty) begin
            if (s_fifo_rd_addr == DEPTH - 1) begin
                s_fifo_rd_addr <= 0;
            end else begin
                s_fifo_rd_addr <= s_fifo_rd_addr + 1;
            end
            if (s_fifo_full) begin
                s_fifo_full <= 0;
            end
            if (s_fifo_rd_addr == s_fifo_wr_addr) begin
                s_fifo_empty <= 1;
            end
        end
        if (s_fifo_overflow) begin
            s_fifo_overflow <= 0;
        end
    end
end

// Output FIFO
always @(posedge m_clk) begin
    if (m_rst) begin
        m_fifo_wr_addr <= 0;
        m_fifo_rd_addr <= 0;
        m_fifo_empty <= 1;
        m_fifo_full <= 0;
        m_fifo_overflow <= 0;
    end else begin
        if (m_axis_tready && !m_fifo_empty) begin
            if (m_fifo_rd_addr == DEPTH - 1) begin
                m_fifo_rd_addr <= 0;
            end else begin
                m_fifo_rd_addr <= m_fifo_rd_addr + 1;
            end
            if (m_fifo_full) begin
                m_fifo_full <= 0;
            end
            if (m_fifo_rd_addr == m_fifo_wr_addr) begin
                m_fifo_empty <= 1;
            end
        end
        if (m_fifo_overflow) begin
            m_fifo_overflow <= 0;
        end
    end
end

// Clock domain crossing
always @(posedge s_clk) begin
    if (s_rst) begin
        s_fifo_depth <= 0;
        s_fifo_depth_valid <= 0;
    end else begin
        if (s_axis_tvalid && !s_fifo_full) begin
            s_fifo_depth <= s_fifo_wr_addr - s_fifo_rd_addr;
            s_fifo_depth_valid <= 1;
        end
        if (!s_axis_tvalid && s_fifo_empty) begin
            s_fifo_depth_valid <= 0;
        end
    end
end

always @(posedge m_clk) begin
    if (m_rst) begin
        m_fifo_depth <= 0;
        m_fifo_depth_valid <= 0;
    end else begin
        if (m_axis_tready && !m_fifo_empty) begin
            m_fifo_depth <= m_fifo_wr_addr - m_fifo_rd_addr;
            m_fifo_depth_valid <= 1;
        end
        if (!m_axis_tready && m_fifo_empty) begin
            m_fifo_depth_valid <= 0;
        end
    end
end

// Pause and status
always @(posedge s_clk) begin
    if (s_rst) begin
        s_pause <= 0;
        s_status_overflow_reg <= 0;
        s_status_bad_frame_reg <= 0;
        s_status_good_frame_reg <= 0;
    end else begin
        if (s_pause_req) begin
            s_pause <= 1;
        end
        if (s_axis_tvalid && s_fifo_full) begin
            s_status_overflow_reg <= 1;
        end
        if (s_axis_tvalid && s_axis_tlast && s_axis_tuser[USER_BAD_FRAME_VALUE]) begin
            s_status_bad_frame_reg <= 1;
        end
        if (s_axis_tvalid && s_axis_tlast && !s_axis_tuser[USER_BAD_FRAME_VALUE]) begin
            s_status_good_frame_reg <= 1;
        end
    end
end

always @(posedge m_clk) begin
    if (m_rst) begin
        m_pause <= 0;
        m_status_overflow_reg <= 0;
        m_status_bad_frame_reg <= 0;
        m_status_good_frame_reg <= 0;
    end else begin
        if (m_pause_req) begin
            m_pause <= 1;
        end
        if (m_axis_tready && m_fifo_full) begin
            m_status_overflow_reg <= 1;
        end
        if (m_axis_tready && m_axis_tlast && m_axis_tuser[USER_BAD_FRAME_VALUE]) begin
            m_status_bad_frame_reg <= 1;
        end
        if (m_axis_tready && m_axis_tlast && !m_axis_tuser[USER_BAD_FRAME_VALUE]) begin
            m_status_good_frame_reg <= 1;
        end
    end
end

// Assign outputs
assign s_axis_tready = !s_fifo_full && !s_pause;
assign m_axis_tvalid = !m_fifo_empty;
assign m_axis_tdata = m_fifo_data[m_fifo_rd_addr][DATA_WIDTH-1:0];
assign m_axis_tkeep = m_fifo_data[m_fifo_rd_addr][DATA_WIDTH+KEEP_WIDTH-1:DATA_WIDTH];
assign m_axis_tlast = m_fifo_data[m_fifo_rd_addr][DATA_WIDTH+KEEP_WIDTH];
assign m_axis_tid = m_fifo_data[m_fifo_rd_addr][DATA_WIDTH+KEEP_WIDTH+ID_WIDTH-1:DATA_WIDTH+KEEP_WIDTH];
assign m_axis_tdest = m_fifo_data[m_fifo_rd_addr][DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+ID_WIDTH];
assign m_axis_tuser = m_fifo_data[m_fifo_rd_addr][DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH-1:DATA_WIDTH+KEEP_WIDTH+ID_WIDTH+DEST_WIDTH];
assign s_pause_ack = s_pause;
assign m_pause_ack = m_pause;
assign s_status_depth = s_fifo_depth;
assign s_status_depth_commit = s_fifo_depth;
assign s_status_overflow = s_status_overflow_reg;
assign s_status_bad_frame = s_status_bad_frame_reg;
assign s_status_good_frame = s_status_good_frame_reg;
assign m_status_depth = m_fifo_depth;
assign m_status_depth_commit = m_fifo_depth;
assign m_status_overflow = m_status_overflow_reg;
assign m_status_bad_frame = m_status_bad_frame_reg;
assign m_status_good_frame = m_status_good_frame_reg;

// Assign input FIFO data
always @(posedge s_clk) begin
    if (s_axis_tvalid && !s_fifo_full) begin
        s_fifo_data[s_fifo_wr_addr] <= {s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser};
    end
end

// Assign output FIFO data
always @(posedge m_clk) begin
    if (m_axis_tready && !m_fifo_empty) begin
        m_fifo_data[m_fifo_rd_addr] <= s_fifo_data[s_fifo_rd_addr];
    end
end

endmodule
