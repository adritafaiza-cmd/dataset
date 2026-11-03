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
    logic [DEPTH-1:0] s_axis_fifo [0:DEPTH-1];
    logic [DEPTH-1:0] m_axis_fifo [0:DEPTH-1];
    logic [DEPTH-1:0] s_axis_read_ptr;
    logic [DEPTH-1:0] m_axis_write_ptr;
    logic [DEPTH-1:0] s_axis_write_ptr_next;
    logic [DEPTH-1:0] m_axis_read_ptr_next;
    logic s_axis_full;
    logic m_axis_empty;
    logic s_axis_overflow;
    logic m_axis_underflow;
    logic s_axis_bad_frame;
    logic m_axis_good_frame;
    logic s_axis_good_frame_next;
    logic m_axis_bad_frame_next;
    logic s_axis_valid_reg;
    logic m_axis_valid_reg;

    // Clock domain crossing for AXI input
    logic [DATA_WIDTH-1:0] s_axis_tdata_reg;
    logic [KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    logic s_axis_tvalid_reg;
    logic s_axis_tlast_reg;
    logic [ID_WIDTH-1:0] s_axis_tid_reg;
    logic [DEST_WIDTH-1:0] s_axis_tdest_reg;
    logic [USER_WIDTH-1:0] s_axis_tuser_reg;

    always_ff @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tvalid_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
                s_axis_tvalid_reg <= s_axis_tvalid;
                s_axis_tlast_reg <= s_axis_tlast;
                s_axis_tid_reg <= s_axis_tid;
                s_axis_tdest_reg <= s_axis_tdest;
                s_axis_tuser_reg <= s_axis_tuser;
            end
        end
    end

    // Clock domain crossing for AXI output
    logic [DATA_WIDTH-1:0] m_axis_tdata_reg;
    logic [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    logic m_axis_tvalid_reg;
    logic m_axis_tlast_reg;
    logic [ID_WIDTH-1:0] m_axis_tid_reg;
    logic [DEST_WIDTH-1:0] m_axis_tdest_reg;
    logic [USER_WIDTH-1:0] m_axis_tuser_reg;

    always_ff @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tdata_reg <= m_axis_tdata;
                m_axis_tkeep_reg <= m_axis_tkeep;
                m_axis_tvalid_reg <= m_axis_tvalid;
                m_axis_tlast_reg <= m_axis_tlast;
                m_axis_tid_reg <= m_axis_tid;
                m_axis_tdest_reg <= m_axis_tdest;
                m_axis_tuser_reg <= m_axis_tuser;
            end
        end
    end

    // FIFO logic for AXI input
    assign s_axis_full = (s_axis_write_ptr == s_axis_read_ptr) && (s_axis_read_ptr != DEPTH-1);
    assign s_axis_overflow = s_axis_full && s_axis_tvalid && !s_axis_tready;
    assign s_axis_bad_frame = s_axis_user && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
    assign s_axis_good_frame = !s_axis_bad_frame;

    always_ff @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_write_ptr <= 0;
            s_axis_valid_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready && !s_axis_full) begin
                s_axis_fifo[s_axis_write_ptr] <= s_axis_tdata_reg;
                if (KEEP_ENABLE) begin
                    s_axis_fifo[s_axis_write_ptr][DATA_WIDTH+KEEP_WIDTH-1:DATA_WIDTH] <= s_axis_tkeep_reg;
                end
                if (LAST_ENABLE) begin
                    s_axis_fifo[s_axis_write_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE-1:DATA_WIDTH+KEEP_WIDTH] <= s_axis_tlast_reg;
                end
                if (ID_ENABLE) begin
                    s_axis_fifo[s_axis_write_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE] <= s_axis_tid_reg;
                end
                if (DEST_ENABLE) begin
                    s_axis_fifo[s_axis_write_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE+DEST_ENABLE-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE] <= s_axis_tdest_reg;
                end
                if (USER_ENABLE) begin
                    s_axis_fifo[s_axis_write_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE+DEST_ENABLE+USER_ENABLE-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE+DEST_ENABLE] <= s_axis_tuser_reg;
                end
                s_axis_write_ptr <= (s_axis_write_ptr + 1) % DEPTH;
                s_axis_valid_reg <= 1;
            end else if (s_axis_valid_reg && m_axis_tready) begin
                s_axis_valid_reg <= 0;
            end
        end
    end

    // FIFO logic for AXI output
    assign m_axis_empty = (m_axis_read_ptr == s_axis_write_ptr);
    assign m_axis_underflow = m_axis_empty && m_axis_tvalid && !m_axis_tready;
    assign m_axis_good_frame_next = m_axis_valid_reg && !m_axis_underflow;
    assign m_axis_bad_frame_next = m_axis_valid_reg && m_axis_underflow;

    always_ff @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_read_ptr <= 0;
            m_axis_valid_reg <= 0;
        end else begin
            if (m_axis_tvalid && m_axis_tready && !m_axis_empty) begin
                m_axis_tdata_reg <= s_axis_fifo[m_axis_read_ptr][DATA_WIDTH-1:0];
                if (KEEP_ENABLE) begin
                    m_axis_tkeep_reg <= s_axis_fifo[m_axis_read_ptr][DATA_WIDTH+KEEP_WIDTH-1:DATA_WIDTH];
                end
                if (LAST_ENABLE) begin
                    m_axis_tlast_reg <= s_axis_fifo[m_axis_read_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE-1:DATA_WIDTH+KEEP_WIDTH];
                end
                if (ID_ENABLE) begin
                    m_axis_tid_reg <= s_axis_fifo[m_axis_read_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE];
                end
                if (DEST_ENABLE) begin
                    m_axis_tdest_reg <= s_axis_fifo[m_axis_read_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE+DEST_ENABLE-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE];
                end
                if (USER_ENABLE) begin
                    m_axis_tuser_reg <= s_axis_fifo[m_axis_read_ptr][DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE+DEST_ENABLE+USER_ENABLE-1:DATA_WIDTH+KEEP_WIDTH+LAST_ENABLE+ID_ENABLE+DEST_ENABLE];
                end
                m_axis_read_ptr <= (m_axis_read_ptr + 1) % DEPTH;
                m_axis_valid_reg <= 1;
            end else if (m_axis_valid_reg && s_axis_tready) begin
                m_axis_valid_reg <= 0;
            end
        end
    end

    // Pause logic
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    // Status signals
    assign s_status_depth = s_axis_write_ptr;
    assign s_status_depth_commit = s_axis_read_ptr;
    assign s_status_overflow = s_axis_overflow;
    assign s_status_bad_frame = s_axis_bad_frame;
    assign s_status_good_frame = s_axis_good_frame;
    assign m_status_depth = m_axis_read_ptr;
    assign m_status_depth_commit = s_axis_write_ptr;
    assign m_status_overflow = m_axis_overflow;
    assign m_status_bad_frame = m_axis_bad_frame;
    assign m_status_good_frame = m_axis_good_frame;

endmodule
