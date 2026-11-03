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

    // Total sideband width
    localparam SIDE_WIDTH = (KEEP_ENABLE ? KEEP_WIDTH : 0) +
                            (LAST_ENABLE ? 1 : 0) +
                            (ID_ENABLE ? ID_WIDTH : 0) +
                            (DEST_ENABLE ? DEST_WIDTH : 0) +
                            (USER_ENABLE ? USER_WIDTH : 0);

    // Pack sidebands into a single vector for easier handling
    // Order: keep, last, id, dest, user
    wire [SIDE_WIDTH-1:0] s_side;
    wire [SIDE_WIDTH-1:0] m_side;

    // Unpack helper functions via generate or just assign
    // We'll use a packed struct-like approach

    // Source sideband packing
    assign s_side = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}})
    };

    // Destination sideband unpacking
    wire [KEEP_WIDTH-1:0] m_keep;
    wire m_last;
    wire [ID_WIDTH-1:0] m_id;
    wire [DEST_WIDTH-1:0] m_dest;
    wire [USER_WIDTH-1:0] m_user;

    assign m_keep = m_side[KEEP_WIDTH-1:0];
    assign m_last = m_side[KEEP_WIDTH];
    assign m_id = m_side[KEEP_WIDTH + 1 +: ID_WIDTH];
    assign m_dest = m_side[KEEP_WIDTH + 1 + ID_WIDTH +: DEST_WIDTH];
    assign m_user = m_side[KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH +: USER_WIDTH];

    // Total data width for storage
    localparam TOTAL_WIDTH = DATA_WIDTH + SIDE_WIDTH;

    // Storage
    reg [TOTAL_WIDTH-1:0] mem [0:DEPTH-1];

    // Pointers
    reg [PTR_WIDTH-1:0] s_wr_ptr;
    reg [PTR_WIDTH-1:0] m_rd_ptr;

    // Synchronized pointers
    reg [PTR_WIDTH-1:0] s_wr_ptr_sync1, s_wr_ptr_sync2;
    reg [PTR_WIDTH-1:0] m_rd_ptr_sync1, m_rd_ptr_sync2;

    // Depth calculations
    wire [PTR_WIDTH-1:0] s_depth = s_wr_ptr - m_rd_ptr_sync2;
    wire [PTR_WIDTH-1:0] m_depth = m_rd_ptr - s_wr_ptr_sync2;

    // Full/Empty
    wire s_full = (s_wr_ptr[ADDR_WIDTH] == m_rd_ptr_sync2[ADDR_WIDTH]) &&
                  (s_wr_ptr[ADDR_WIDTH-1:0] == m_rd_ptr_sync2[ADDR_WIDTH-1:0]);
    wire m_empty = (m_rd_ptr[ADDR_WIDTH] == s_wr_ptr_sync2[ADDR_WIDTH]) &&
                   (m_rd_ptr[ADDR_WIDTH-1:0] == s_wr_ptr_sync2[ADDR_WIDTH-1:0]);

    // Pause logic
    reg s_pause_active;
    reg m_pause_active;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_pause_active <= 1'b0;
        else if (PAUSE_ENABLE)
            s_pause_active <= s_pause_req;
        else
            s_pause_active <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_pause_active <= 1'b0;
        else if (PAUSE_ENABLE)
            m_pause_active <= m_pause_req;
        else
            m_pause_active <= 1'b0;
    end

    // Synchronize pause acks
    reg s_pause_ack_sync1, s_pause_ack_sync2;
    reg m_pause_ack_sync1, m_pause_ack_sync2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_sync1 <= 1'b0;
            s_pause_ack_sync2 <= 1'b0;
        end else begin
            s_pause_ack_sync1 <= m_pause_active;
            s_pause_ack_sync2 <= s_pause_ack_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_sync1 <= 1'b0;
            m_pause_ack_sync2 <= 1'b0;
        end else begin
            m_pause_ack_sync1 <= s_pause_active;
            m_pause_ack_sync2 <= m_pause_ack_sync1;
        end
    end

    assign s_pause_ack = s_pause_ack_sync2;
    assign m_pause_ack = m_pause_ack_sync2;

    // Write enable
    wire s_write_en = s_axis_tvalid && s_axis_tready && !s_pause_active;

    // Read enable
    wire m_read_en = m_axis_tvalid && m_axis_tready && !m_pause_active;

    // Source ready
    assign s_axis_tready = !s_full && !s_pause_active;

    // Destination valid
    assign m_axis_tvalid = !m_empty && !m_pause_active;

    // Write to memory
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (s_write_en) begin
            mem[s_wr_ptr[ADDR_WIDTH-1:0]] <= {s_axis_tdata, s_side};
            s_wr_ptr <= s_wr_ptr + 1'b1;
        end
    end

    // Read from memory
    wire [TOTAL_WIDTH-1:0] m_data;
    assign m_data = mem[m_rd_ptr[ADDR_WIDTH-1:0]];

    assign m_axis_tdata = m_data[DATA_WIDTH-1:0];
    assign m_axis_tkeep = m_keep;
    assign m_axis_tlast = m_last;
    assign m_axis_tid = m_id;
    assign m_axis_tdest = m_dest;
    assign m_axis_tuser = m_user;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else if (m_read_en) begin
            m_rd_ptr <= m_rd_ptr + 1'b1;
        end
    end

    // Synchronize write pointer to m_clk domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_sync1 <= s_wr_ptr;
            s_wr_ptr_sync2 <= s_wr_ptr_sync1;
        end
    end

    // Synchronize read pointer to s_clk domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_sync1 <= m_rd_ptr;
            m_rd_ptr_sync2 <= m_rd_ptr_sync1;
        end
    end

    // Status outputs
    assign s_status_depth = s_depth[ADDR_WIDTH:0];
    assign s_status_depth_commit = s_depth[ADDR_WIDTH:0];
    assign s_status_overflow = 1'b0;
    assign s_status_bad_frame = 1'b0;
    assign s_status_good_frame = 1'b0;

    assign m_status_depth = m_depth[ADDR_WIDTH:0];
    assign m_status_depth_commit = m_depth[ADDR_WIDTH:0];
    assign m_status_overflow = 1'b0;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b0;

endmodule
