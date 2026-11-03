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
    wire [SIDE_WIDTH-1:0] s_sideband;
    wire [SIDE_WIDTH-1:0] m_sideband;

    // Unpack sidebands
    wire [KEEP_WIDTH-1:0] s_keep;
    wire                   s_last;
    wire [ID_WIDTH-1:0]    s_id;
    wire [DEST_WIDTH-1:0]  s_dest;
    wire [USER_WIDTH-1:0]  s_user;

    wire [KEEP_WIDTH-1:0] m_keep;
    wire                   m_last;
    wire [ID_WIDTH-1:0]    m_id;
    wire [DEST_WIDTH-1:0]  m_dest;
    wire [USER_WIDTH-1:0]  m_user;

    // Pack source sideband
    assign s_sideband = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}})
    };

    // Unpack destination sideband
    assign m_keep = m_sideband[0 +: KEEP_ENABLE ? KEEP_WIDTH : 1];
    assign m_last = m_sideband[KEEP_ENABLE ? KEEP_WIDTH : 0];
    assign m_id   = m_sideband[KEEP_ENABLE ? KEEP_WIDTH : 0] +: (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0);
    assign m_dest = m_sideband[KEEP_ENABLE ? KEEP_WIDTH : 0] + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) +: (DEST_ENABLE ? DEST_WIDTH : 1);
    assign m_user = m_sideband[KEEP_ENABLE ? KEEP_WIDTH : 0] + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) +: (USER_ENABLE ? USER_WIDTH : 1);

    // Correct unpacking with proper offsets
    localparam KEEP_OFF = 0;
    localparam LAST_OFF = KEEP_ENABLE ? KEEP_WIDTH : 0;
    localparam ID_OFF   = LAST_OFF + (LAST_ENABLE ? 1 : 0);
    localparam DEST_OFF = ID_OFF + (ID_ENABLE ? ID_WIDTH : 0);
    localparam USER_OFF = DEST_OFF + (DEST_ENABLE ? DEST_WIDTH : 0);

    assign m_keep = m_sideband[KEEP_OFF +: (KEEP_ENABLE ? KEEP_WIDTH : 1)];
    assign m_last = m_sideband[LAST_OFF];
    assign m_id   = m_sideband[ID_OFF +: (ID_ENABLE ? ID_WIDTH : 1)];
    assign m_dest = m_sideband[DEST_OFF +: (DEST_ENABLE ? DEST_WIDTH : 1)];
    assign m_user = m_sideband[USER_OFF +: (USER_ENABLE ? USER_WIDTH : 1)];

    // Repack for output
    assign m_axis_tkeep  = m_keep;
    assign m_axis_tlast  = m_last;
    assign m_axis_tid    = m_id;
    assign m_axis_tdest  = m_dest;
    assign m_axis_tuser  = m_user;

    // Source domain signals
    reg [ADDR_WIDTH-1:0] s_wr_ptr;
    reg [ADDR_WIDTH-1:0] s_rd_ptr_sync; // synchronized read pointer from m domain
    reg [ADDR_WIDTH-1:0] s_wr_ptr_sync; // synchronized write pointer to m domain

    // Destination domain signals
    reg [ADDR_WIDTH-1:0] m_rd_ptr;
    reg [ADDR_WIDTH-1:0] m_wr_ptr_sync; // synchronized write pointer from s domain
    reg [ADDR_WIDTH-1:0] m_rd_ptr_sync; // synchronized read pointer to s domain

    // RAM storage
    reg [DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [SIDE_WIDTH-1:0] ram_side [0:DEPTH-1];

    // Write enable
    wire s_wr_en = s_axis_tvalid & s_axis_tready;

    // Read enable
    wire m_rd_en = m_axis_tvalid & m_axis_tready;

    // Full/Empty logic
    wire s_full = (s_wr_ptr == s_rd_ptr_sync) && (s_wr_ptr[ADDR_WIDTH] != s_rd_ptr_sync[ADDR_WIDTH]);
    wire m_empty = (m_rd_ptr == m_wr_ptr_sync);

    // tready logic
    wire s_tready_base = !s_full;
    assign s_axis_tready = (DROP_WHEN_FULL || MARK_WHEN_FULL) ? 1'b1 : s_tready_base;

    // tvalid logic
    assign m_axis_tvalid = !m_empty;

    // RAM write
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else begin
            if (s_wr_en) begin
                ram_data[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
                ram_side[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_sideband;
                s_wr_ptr <= s_wr_ptr + 1'b1;
            end
        end
    end

    // RAM read
    wire [ADDR_WIDTH-1:0] m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] m_rd_data;
    wire [SIDE_WIDTH-1:0] m_rd_side;

    assign m_rd_data = ram_data[m_rd_addr];
    assign m_rd_side = ram_side[m_rd_addr];

    assign m_axis_tdata = m_rd_data;
    assign m_sideband   = m_rd_side;

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else begin
            if (m_rd_en) begin
                m_rd_ptr <= m_rd_ptr + 1'b1;
            end
        end
    end

    // CDC: Synchronize write pointer from s domain to m domain
    reg [ADDR_WIDTH:0] s_wr_ptr_sync_r1, s_wr_ptr_sync_r2, s_wr_ptr_sync_r3;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_sync_r1 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_sync_r2 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_sync_r3 <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_sync_r1 <= s_wr_ptr;
            s_wr_ptr_sync_r2 <= s_wr_ptr_sync_r1;
            s_wr_ptr_sync_r3 <= s_wr_ptr_sync_r2;
        end
    end
    assign m_wr_ptr_sync = s_wr_ptr_sync_r3;

    // CDC: Synchronize read pointer from m domain to s domain
    reg [ADDR_WIDTH:0] m_rd_ptr_sync_r1, m_rd_ptr_sync_r2, m_rd_ptr_sync_r3;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_sync_r1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync_r2 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync_r3 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_sync_r1 <= m_rd_ptr;
            m_rd_ptr_sync_r2 <= m_rd_ptr_sync_r1;
            m_rd_ptr_sync_r3 <= m_rd_ptr_sync_r2;
        end
    end
    assign s_rd_ptr_sync = m_rd_ptr_sync_r3;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth = s_wr_ptr - s_rd_ptr_sync;
    wire [PTR_WIDTH-1:0] m_depth = m_wr_ptr_sync - m_rd_ptr;

    assign s_status_depth = s_depth;
    assign m_status_depth = m_depth;

    // Commit depth (same as depth for this simple implementation)
    assign s_status_depth_commit = s_depth;
    assign m_status_depth_commit = m_depth;

    // Status flags
    assign s_status_overflow = 1'b0;
    assign s_status_bad_frame = 1'b0;
    assign s_status_good_frame = 1'b0;
    assign m_status_overflow = 1'b0;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b0;

    // Pause logic
    assign s_pause_ack = 1'b0;
    assign m_pause_ack = 1'b0;

endmodule
