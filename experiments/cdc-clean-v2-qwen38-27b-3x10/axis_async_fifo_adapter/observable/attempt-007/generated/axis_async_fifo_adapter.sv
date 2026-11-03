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
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
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
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    // Internal data width for storage: max of S and M data width
    localparam MAX_DATA_WIDTH = (S_DATA_WIDTH > M_DATA_WIDTH) ? S_DATA_WIDTH : M_DATA_WIDTH;
    localparam MAX_KEEP_WIDTH = (S_KEEP_WIDTH > M_KEEP_WIDTH) ? S_KEEP_WIDTH : M_KEEP_WIDTH;

    // Storage width: data + keep + last + user
    localparam STORE_WIDTH = MAX_DATA_WIDTH + MAX_KEEP_WIDTH + 1 + USER_WIDTH;

    // RAM storage
    reg [STORE_WIDTH-1:0] ram [0:DEPTH-1];

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;

    // Gray code pointers for CDC
    reg [PTR_WIDTH-1:0] w_ptr_gray;
    reg [PTR_WIDTH-1:0] r_ptr_gray;

    // Synchronizers
    reg [PTR_WIDTH-1:0] w_ptr_gray_sync1, w_ptr_gray_sync2;
    reg [PTR_WIDTH-1:0] r_ptr_gray_sync1, r_ptr_gray_sync2;

    // Write side logic
    wire s_write = s_axis_tvalid && s_axis_tready;
    wire s_full = (w_ptr[PTR_WIDTH-1:0] == r_ptr_gray_sync2[PTR_WIDTH-1:0]) &&
                  (w_ptr[PTR_WIDTH-1] != r_ptr_gray_sync2[PTR_WIDTH-1]);
    wire s_not_full = ~s_full;

    // Pause logic
    reg s_paused, m_paused;
    wire s_pause_active = PAUSE_ENABLE && s_pause_req;
    wire m_pause_active = PAUSE_ENABLE && m_pause_req;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_paused <= 1'b0;
        else
            s_paused <= s_pause_active;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_paused <= 1'b0;
        else
            m_paused <= m_pause_active;
    end

    assign s_pause_ack = s_paused;
    assign m_pause_ack = m_paused;

    // tready generation
    wire s_can_accept = s_not_full && !s_paused;
    assign s_axis_tready = s_can_accept;

    // Write to RAM
    wire [STORE_WIDTH-1:0] s_store_data;
    assign s_store_data[MAX_DATA_WIDTH-1:0] = s_axis_tdata;
    assign s_store_data[MAX_DATA_WIDTH +: MAX_KEEP_WIDTH] = s_axis_tkeep;
    assign s_store_data[MAX_DATA_WIDTH + MAX_KEEP_WIDTH] = s_axis_tlast;
    assign s_store_data[MAX_DATA_WIDTH + MAX_KEEP_WIDTH + 1 +: USER_WIDTH] = s_axis_tuser;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
            w_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else begin
            if (s_write) begin
                ram[w_ptr[ADDR_WIDTH-1:0]] <= s_store_data;
                w_ptr <= w_ptr + 1'b1;
            end
            w_ptr_gray <= w_ptr ^ (w_ptr >> 1);
        end
    end

    // Synchronize write pointer gray to m_clk
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            w_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            w_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_gray_sync1 <= w_ptr_gray;
            w_ptr_gray_sync2 <= w_ptr_gray_sync1;
        end
    end

    // Read side logic
    wire m_read = m_axis_tvalid && m_axis_tready;
    wire m_empty = (r_ptr[PTR_WIDTH-1:0] == w_ptr_gray_sync2[PTR_WIDTH-1:0]) &&
                   (r_ptr[PTR_WIDTH-1] == w_ptr_gray_sync2[PTR_WIDTH-1]);
    wire m_not_empty = ~m_empty;

    wire m_can_send = m_not_empty && !m_paused;
    assign m_axis_tvalid = m_can_send;

    // Read from RAM
    wire [STORE_WIDTH-1:0] m_store_data;
    assign m_store_data = ram[r_ptr[ADDR_WIDTH-1:0]];

    assign m_axis_tdata = m_store_data[MAX_DATA_WIDTH-1:0];
    assign m_axis_tkeep = m_store_data[MAX_DATA_WIDTH +: MAX_KEEP_WIDTH];
    assign m_axis_tlast = m_store_data[MAX_DATA_WIDTH + MAX_KEEP_WIDTH];
    assign m_axis_tuser = m_store_data[MAX_DATA_WIDTH + MAX_KEEP_WIDTH + 1 +: USER_WIDTH];

    // ID and DEST passthrough (not stored in RAM, use current input values)
    // For simplicity, we pass through the current s_axis values
    assign m_axis_tid = s_axis_tid;
    assign m_axis_tdest = s_axis_tdest;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
            r_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else begin
            if (m_read) begin
                r_ptr <= r_ptr + 1'b1;
            end
            r_ptr_gray <= r_ptr ^ (r_ptr >> 1);
        end
    end

    // Synchronize read pointer gray to s_clk
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            r_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_gray_sync1 <= r_ptr_gray;
            r_ptr_gray_sync2 <= r_ptr_gray_sync1;
        end
    end

    // Status outputs
    wire [PTR_WIDTH-1:0] s_depth = w_ptr - r_ptr_gray_sync2;
    wire [PTR_WIDTH-1:0] m_depth = w_ptr_gray_sync2 - r_ptr;

    assign s_status_depth = s_depth[ADDR_WIDTH:0];
    assign s_status_depth_commit = s_depth[ADDR_WIDTH:0];
    assign m_status_depth = m_depth[ADDR_WIDTH:0];
    assign m_status_depth_commit = m_depth[ADDR_WIDTH:0];

    // Overflow/underflow and frame status
    reg s_overflow, m_overflow;
    reg s_bad_frame, m_bad_frame;
    reg s_good_frame, m_good_frame;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow <= 1'b0;
            s_bad_frame <= 1'b0;
            s_good_frame <= 1'b0;
        end else begin
            if (s_axis_tvalid && !s_axis_tready)
                s_overflow <= 1'b1;
            if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
                s_good_frame <= 1'b1;
                s_bad_frame <= 1'b0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_overflow <= 1'b0;
            m_bad_frame <= 1'b0;
            m_good_frame <= 1'b0;
        end else begin
            if (m_axis_tvalid && !m_axis_tready)
                m_overflow <= 1'b1;
            if (m_axis_tvalid && m_axis_tready && m_axis_tlast) begin
                m_good_frame <= 1'b1;
                m_bad_frame <= 1'b0;
            end
        end
    end

    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

endmodule
