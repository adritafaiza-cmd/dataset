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

    // Internal signal widths
    localparam TOTAL_WIDTH = DATA_WIDTH + SIDE_WIDTH;

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

    // Assign sideband signals
    assign s_keep = KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}};
    assign s_last = LAST_ENABLE ? s_axis_tlast : 1'b0;
    assign s_id   = ID_ENABLE   ? s_axis_tid   : {ID_WIDTH{1'b0}};
    assign s_dest = DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
    assign s_user = USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};

    // Pack sideband
    assign s_sideband = {
        (USER_ENABLE ? s_user : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_dest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE   ? s_id   : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_last : 1'b0),
        (KEEP_ENABLE ? s_keep : {KEEP_WIDTH{1'b0}})
    };

    // Unpack m_sideband
    assign m_keep = KEEP_ENABLE ? m_sideband[0 +: KEEP_WIDTH] : {KEEP_WIDTH{1'b0}};
    assign m_last = LAST_ENABLE ? m_sideband[KEEP_WIDTH +: 1] : 1'b0;
    assign m_id   = ID_ENABLE   ? m_sideband[KEEP_WIDTH + (LAST_ENABLE?1:0) +: ID_WIDTH] : {ID_WIDTH{1'b0}};
    assign m_dest = DEST_ENABLE ? m_sideband[KEEP_WIDTH + (LAST_ENABLE?1:0) + (ID_ENABLE?ID_WIDTH:0) +: DEST_WIDTH] : {DEST_WIDTH{1'b0}};
    assign m_user = USER_ENABLE ? m_sideband[KEEP_WIDTH + (LAST_ENABLE?1:0) + (ID_ENABLE?ID_WIDTH:0) + (DEST_ENABLE?DEST_WIDTH:0) +: USER_WIDTH] : {USER_WIDTH{1'b0}};

    // Output sideband assignment
    assign m_axis_tkeep  = m_keep;
    assign m_axis_tlast  = m_last;
    assign m_axis_tid    = m_id;
    assign m_axis_tdest  = m_dest;
    assign m_axis_tuser  = m_user;

    // ---------------------------------------------------------------------------
    // Source Domain (s_clk)
    // ---------------------------------------------------------------------------

    reg [PTR_WIDTH-1:0] s_wr_ptr;
    reg [PTR_WIDTH-1:0] s_rd_ptr_sync; // Synchronized read pointer from m domain

    // RAM storage
    reg [TOTAL_WIDTH-1:0] ram [0:DEPTH-1];

    // Write enable
    wire s_wr_en;
    wire s_full;
    wire s_empty;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth_raw;
    assign s_depth_raw = s_wr_ptr - s_rd_ptr_sync;

    // Full condition: pointers differ only in MSB
    assign s_full = (s_wr_ptr[ADDR_WIDTH] != s_rd_ptr_sync[ADDR_WIDTH]) &&
                    (s_wr_ptr[ADDR_WIDTH-1:0] == s_rd_ptr_sync[ADDR_WIDTH-1:0]);

    // Empty condition: pointers equal
    assign s_empty = (s_wr_ptr == s_rd_ptr_sync);

    // Write enable logic
    wire s_accept;
    assign s_accept = s_axis_tvalid && s_axis_tready;

    // tready logic
    wire s_tready_internal;
    assign s_tready_internal = !s_full;

    // Pause logic
    wire s_pause_active;
    assign s_pause_active = PAUSE_ENABLE ? s_pause_ack : 1'b0;

    // Final tready
    assign s_axis_tready = s_tready_internal && !s_pause_active;

    // Write to RAM
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (s_accept) begin
            ram[s_wr_ptr[ADDR_WIDTH-1:0]] <= {s_axis_tdata, s_sideband};
            s_wr_ptr <= s_wr_ptr + 1'b1;
        end
    end

    // ---------------------------------------------------------------------------
    // Destination Domain (m_clk)
    // ---------------------------------------------------------------------------

    reg [PTR_WIDTH-1:0] m_rd_ptr;
    reg [PTR_WIDTH-1:0] m_wr_ptr_sync; // Synchronized write pointer from s domain

    // Read enable
    wire m_rd_en;
    wire m_full;
    wire m_empty;

    // Depth calculation
    wire [PTR_WIDTH-1:0] m_depth_raw;
    assign m_depth_raw = m_wr_ptr_sync - m_rd_ptr;

    // Full condition
    assign m_full = (m_wr_ptr_sync[ADDR_WIDTH] != m_rd_ptr[ADDR_WIDTH]) &&
                    (m_wr_ptr_sync[ADDR_WIDTH-1:0] == m_rd_ptr[ADDR_WIDTH-1:0]);

    // Empty condition
    assign m_empty = (m_wr_ptr_sync == m_rd_ptr);

    // Read enable logic
    wire m_accept;
    assign m_accept = m_axis_tvalid && m_axis_tready;

    // tvalid logic
    wire m_tvalid_internal;
    assign m_tvalid_internal = !m_empty;

    // Pause logic
    wire m_pause_active;
    assign m_pause_active = PAUSE_ENABLE ? m_pause_ack : 1'b0;

    // Final tvalid
    assign m_axis_tvalid = m_tvalid_internal && !m_pause_active;

    // Read from RAM
    wire [TOTAL_WIDTH-1:0] m_ram_data;
    assign m_ram_data = ram[m_rd_ptr[ADDR_WIDTH-1:0]];

    // Unpack data
    assign m_axis_tdata = m_ram_data[DATA_WIDTH-1:0];
    assign m_sideband   = m_ram_data[TOTAL_WIDTH-1:DATA_WIDTH];

    // Update read pointer
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else if (m_accept) begin
            m_rd_ptr <= m_rd_ptr + 1'b1;
        end
    end

    // ---------------------------------------------------------------------------
    // CDC: Synchronize write pointer to m domain
    // ---------------------------------------------------------------------------

    reg [PTR_WIDTH-1:0] wr_ptr_sync_r1;
    reg [PTR_WIDTH-1:0] wr_ptr_sync_r2;
    reg [PTR_WIDTH-1:0] wr_ptr_sync_r3;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wr_ptr_sync_r1 <= {PTR_WIDTH{1'b0}};
            wr_ptr_sync_r2 <= {PTR_WIDTH{1'b0}};
            wr_ptr_sync_r3 <= {PTR_WIDTH{1'b0}};
        end else begin
            wr_ptr_sync_r1 <= s_wr_ptr;
            wr_ptr_sync_r2 <= wr_ptr_sync_r1;
            wr_ptr_sync_r3 <= wr_ptr_sync_r2;
        end
    end

    assign m_wr_ptr_sync = wr_ptr_sync_r3;

    // ---------------------------------------------------------------------------
    // CDC: Synchronize read pointer to s domain
    // ---------------------------------------------------------------------------

    reg [PTR_WIDTH-1:0] rd_ptr_sync_r1;
    reg [PTR_WIDTH-1:0] rd_ptr_sync_r2;
    reg [PTR_WIDTH-1:0] rd_ptr_sync_r3;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rd_ptr_sync_r1 <= {PTR_WIDTH{1'b0}};
            rd_ptr_sync_r2 <= {PTR_WIDTH{1'b0}};
            rd_ptr_sync_r3 <= {PTR_WIDTH{1'b0}};
        end else begin
            rd_ptr_sync_r1 <= m_rd_ptr;
            rd_ptr_sync_r2 <= rd_ptr_sync_r1;
            rd_ptr_sync_r3 <= rd_ptr_sync_r2;
        end
    end

    assign s_rd_ptr_sync = rd_ptr_sync_r3;

    // ---------------------------------------------------------------------------
    // Status Signals
    // ---------------------------------------------------------------------------

    // Depth outputs
    assign s_status_depth = s_depth_raw;
    assign m_status_depth = m_depth_raw;

    // Depth commit (same as depth for this implementation)
    assign s_status_depth_commit = s_depth_raw;
    assign m_status_depth_commit = m_depth_raw;

    // Overflow: write when full
    wire s_overflow_pulse;
    assign s_overflow_pulse = s_accept && s_full;

    reg s_overflow_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow_reg <= 1'b0;
        end else if (s_overflow_pulse) begin
            s_overflow_reg <= 1'b1;
        end
    end

    assign s_status_overflow = s_overflow_reg;

    // Bad frame: oversize frame (more than DEPTH beats in a frame)
    // For simplicity, we track frame length
    reg [ADDR_WIDTH:0] s_frame_len;
    reg s_in_frame;

    wire s_frame_start;
    assign s_frame_start = s_accept && !s_in_frame;

    wire s_frame_end;
    assign s_frame_end = s_accept && s_in_frame && s_last;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_len <= {ADDR_WIDTH+1{1'b0}};
            s_in_frame <= 1'b0;
        end else if (s_accept) begin
            if (s_frame_start) begin
                s_frame_len <= 1'b1;
                s_in_frame <= 1'b1;
            end else if (s_in_frame) begin
                if (s_frame_end) begin
                    s_in_frame <= 1'b0;
                end else begin
                    s_frame_len <= s_frame_len + 1'b1;
                end
            end
        end
    end

    wire s_bad_frame_pulse;
    assign s_bad_frame_pulse = s_frame_end && (s_frame_len > DEPTH);

    reg s_bad_frame_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bad_frame_reg <= 1'b0;
        end else if (s_bad_frame_pulse) begin
            s_bad_frame_reg <= 1'b1;
        end
    end

    assign s_status_bad_frame = s_bad_frame_reg;

    // Good frame: frame completed without error
    reg s_good_frame_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_good_frame_reg <= 1'b0;
        end else if (s_frame_end && !s_bad_frame_pulse) begin
            s_good_frame_reg <= 1'b1;
        end
    end

    assign s_status_good_frame = s_good_frame_reg;

    // M domain status (simplified - same logic mirrored)
    assign m_status_overflow = 1'b0;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b0;

    // ---------------------------------------------------------------------------
    // Pause Acknowledgment
    // ---------------------------------------------------------------------------

    // Simple pause acknowledgment: ack when request is stable
    reg s_pause_ack_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            s_pause_ack_reg <= s_pause_req;
        end else begin
            s_pause_ack_reg <= 1'b0;
        end
    end

    assign s_pause_ack = s_pause_ack_reg;

    reg m_pause_ack_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            m_pause_ack_reg <= m_pause_req;
        end else begin
            m_pause_ack_reg <= 1'b0;
        end
    end

    assign m_pause_ack = m_pause_ack_reg;

endmodule
