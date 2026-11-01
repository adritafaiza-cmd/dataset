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
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    // Internal signals
    wire [DATA_WIDTH-1:0] ram_data;
    wire [KEEP_WIDTH-1:0] ram_keep;
    wire                   ram_last;
    wire [ID_WIDTH-1:0]    ram_tid;
    wire [DEST_WIDTH-1:0]  ram_tdest;
    wire [USER_WIDTH-1:0]  ram_tuser;

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    wire [ADDR_WIDTH-1:0] w_addr = w_ptr[ADDR_WIDTH-1:0];
    wire [PTR_WIDTH-1:0] w_ptr_next = w_ptr + 1;

    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;
    wire [ADDR_WIDTH-1:0] r_addr = r_ptr[ADDR_WIDTH-1:0];
    wire [PTR_WIDTH-1:0] r_ptr_next = r_ptr + 1;

    // Synchronizers for write pointer to m_clk domain
    reg [PTR_WIDTH-1:0] w_ptr_sync1, w_ptr_sync2, w_ptr_sync3;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            w_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_sync1 <= w_ptr;
            w_ptr_sync2 <= w_ptr_sync1;
            w_ptr_sync3 <= w_ptr_sync2;
        end
    end

    // Synchronizers for read pointer to s_clk domain
    reg [PTR_WIDTH-1:0] r_ptr_sync1, r_ptr_sync2, r_ptr_sync3;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_sync1 <= r_ptr;
            r_ptr_sync2 <= r_ptr_sync1;
            r_ptr_sync3 <= r_ptr_sync2;
        end
    end

    // Depth calculations
    wire [PTR_WIDTH-1:0] depth_s = w_ptr - r_ptr_sync3;
    wire [PTR_WIDTH-1:0] depth_m = w_ptr_sync3 - r_ptr;

    // Full and empty conditions
    wire s_full = (depth_s == DEPTH);
    wire m_empty = (depth_m == 0);

    // Pause logic
    reg s_paused, m_paused;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) s_paused <= 1'b0;
        else if (PAUSE_ENABLE) s_paused <= s_pause_req;
        else s_paused <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) m_paused <= 1'b0;
        else if (PAUSE_ENABLE) m_paused <= m_pause_req;
        else m_paused <= 1'b0;
    end

    assign s_pause_ack = s_paused;
    assign m_pause_ack = m_paused;

    // Write enable
    wire s_write_en = s_axis_tvalid && s_axis_tready && !s_paused;

    // Read enable
    wire m_read_en = m_axis_tvalid && m_axis_tready && !m_paused;

    // tready generation
    wire s_can_accept = !s_full || DROP_WHEN_FULL || MARK_WHEN_FULL;
    assign s_axis_tready = s_can_accept && !s_paused;

    // RAM write
    always @(posedge s_clk) begin
        if (s_write_en) begin
            ram_data <= s_axis_tdata;
            ram_keep <= s_axis_tkeep;
            ram_last <= s_axis_tlast;
            ram_tid <= s_axis_tid;
            ram_tdest <= s_axis_tdest;
            ram_tuser <= s_axis_tuser;
            w_ptr <= w_ptr_next;
        end
    end

    // RAM read
    always @(posedge m_clk) begin
        if (m_read_en) begin
            r_ptr <= r_ptr_next;
        end
    end

    // Output valid
    assign m_axis_tvalid = !m_empty && !m_paused;

    // Output data
    assign m_axis_tdata = ram_data;
    assign m_axis_tkeep = ram_keep;
    assign m_axis_tlast = ram_last;
    assign m_axis_tid = ram_tid;
    assign m_axis_tdest = ram_tdest;
    assign m_axis_tuser = ram_tuser;

    // Status outputs
    assign s_status_depth = depth_s;
    assign s_status_depth_commit = depth_s;
    assign s_status_overflow = 1'b0;
    assign s_status_bad_frame = 1'b0;
    assign s_status_good_frame = 1'b0;

    assign m_status_depth = depth_m;
    assign m_status_depth_commit = depth_m;
    assign m_status_overflow = 1'b0;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b0;

endmodule
