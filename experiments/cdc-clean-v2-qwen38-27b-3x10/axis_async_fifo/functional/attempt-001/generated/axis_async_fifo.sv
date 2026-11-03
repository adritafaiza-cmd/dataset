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

    // Total width for storage
    localparam TOTAL_WIDTH = DATA_WIDTH + 
                             (KEEP_ENABLE ? KEEP_WIDTH : 0) +
                             (LAST_ENABLE ? 1 : 0) +
                             (ID_ENABLE ? ID_WIDTH : 0) +
                             (DEST_ENABLE ? DEST_WIDTH : 0) +
                             (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    wire [TOTAL_WIDTH-1:0] s_write_data;
    wire [TOTAL_WIDTH-1:0] m_read_data;
    wire [ADDR_WIDTH-1:0] s_write_addr;
    wire [ADDR_WIDTH-1:0] m_read_addr;
    wire s_write_en;
    wire m_read_en;
    wire s_full;
    wire m_empty;
    wire [PTR_WIDTH-1:0] s_wr_ptr;
    wire [PTR_WIDTH-1:0] m_rd_ptr;
    wire [PTR_WIDTH-1:0] s_wr_ptr_sync_m;
    wire [PTR_WIDTH-1:0] m_rd_ptr_sync_s;
    wire [PTR_WIDTH-1:0] s_depth;
    wire [PTR_WIDTH-1:0] m_depth;

    // Frame tracking
    reg s_in_frame;
    reg m_in_frame;
    reg s_frame_overflow;
    reg m_frame_overflow;
    reg s_bad_frame;
    reg m_bad_frame;
    reg s_good_frame;
    reg m_good_frame;
    reg s_overflow_pulse;
    reg m_overflow_pulse;

    // Pause logic
    reg s_paused;
    reg m_paused;
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    // Build write data
    assign s_write_data = {
        (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
        (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
        (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
        (LAST_ENABLE ? s_axis_tlast : 1'b0),
        (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
        s_axis_tdata
    };

    // Extract read data
    wire [DATA_WIDTH-1:0] m_tdata = m_read_data[DATA_WIDTH-1:0];
    wire [KEEP_WIDTH-1:0] m_tkeep = m_read_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) - 1 : DATA_WIDTH];
    wire m_tlast = m_read_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) - 1];
    wire [ID_WIDTH-1:0] m_tid = m_read_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) - 1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)];
    wire [DEST_WIDTH-1:0] m_tdest = m_read_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) - 1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)];
    wire [USER_WIDTH-1:0] m_tuser = m_read_data[TOTAL_WIDTH-1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0)];

    // Assign outputs
    assign m_axis_tdata = m_tdata;
    assign m_axis_tkeep = m_tkeep;
    assign m_axis_tlast = m_tlast;
    assign m_axis_tid = m_tid;
    assign m_axis_tdest = m_tdest;
    assign m_axis_tuser = m_tuser;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth_raw = s_wr_ptr - m_rd_ptr_sync_s;
    wire [PTR_WIDTH-1:0] m_depth_raw = s_wr_ptr_sync_m - m_rd_ptr;

    assign s_status_depth = s_depth_raw;
    assign m_status_depth = m_depth_raw;

    // Commit depth (same as depth for this implementation)
    assign s_status_depth_commit = s_depth_raw;
    assign m_status_depth_commit = m_depth_raw;

    // Full and empty
    assign s_full = (s_depth_raw == DEPTH);
    assign m_empty = (m_depth_raw == 0);

    // Write enable
    wire s_write_allowed = s_axis_tvalid && s_axis_tready;
    assign s_write_en = s_write_allowed;

    // Read enable
    wire m_read_allowed = m_axis_tvalid && m_axis_tready;
    assign m_read_en = m_read_allowed;

    // Pause logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_paused <= 1'b0;
            s_pause_ack_reg <= 1'b0;
        end else begin
            if (PAUSE_ENABLE) begin
                if (s_pause_req && !s_paused) begin
                    s_paused <= 1'b1;
                end else if (!s_pause_req && s_paused) begin
                    s_paused <= 1'b0;
                end
            end else begin
                s_paused <= 1'b0;
            end
            s_pause_ack_reg <= s_paused;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_paused <= 1'b0;
            m_pause_ack_reg <= 1'b0;
        end else begin
            if (PAUSE_ENABLE) begin
                if (m_pause_req && !m_paused) begin
                    m_paused <= 1'b1;
                end else if (!m_pause_req && m_paused) begin
                    m_paused <= 1'b0;
                end
            end else begin
                m_paused <= 1'b0;
            end
            m_pause_ack_reg <= m_paused;
        end
    end

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Tready logic
    wire s_can_accept = !s_full && !s_paused;
    wire m_can_read = !m_empty && !m_paused;

    // Frame tracking for drop/mark when full
    wire s_frame_complete = s_axis_tlast;
    wire m_frame_complete = m_tlast;

    // Overflow detection
    wire s_overflow = s_axis_tvalid && s_full && !DROP_WHEN_FULL && !MARK_WHEN_FULL;
    wire m_overflow = m_axis_tvalid && m_empty; // This shouldn't happen, but for safety

    // Bad frame detection
    wire s_bad_frame_det = USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
    wire m_bad_frame_det = USER_ENABLE && (m_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;

    // Oversize frame detection (simplified: assume frame is oversize if it exceeds DEPTH)
    // For simplicity, we'll track frame size
    reg [PTR_WIDTH-1:0] s_frame_size;
    reg [PTR_WIDTH-1:0] m_frame_size;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_size <= {PTR_WIDTH{1'b0}};
        end else if (s_write_en) begin
            if (s_axis_tlast) begin
                s_frame_size <= {PTR_WIDTH{1'b0}};
            end else begin
                s_frame_size <= s_frame_size + 1'b1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_size <= {PTR_WIDTH{1'b0}};
        end else if (m_read_en) begin
            if (m_tlast) begin
                m_frame_size <= {PTR_WIDTH{1'b0}};
            end else begin
                m_frame_size <= m_frame_size + 1'b1;
            end
        end
    end

    wire s_oversize = s_frame_size >= DEPTH;
    wire m_oversize = m_frame_size >= DEPTH;

    // Drop/mark when full logic
    wire s_drop_when_full = DROP_WHEN_FULL && s_full && s_axis_tvalid;
    wire s_mark_when_full = MARK_WHEN_FULL && s_full && s_axis_tvalid;

    // Tready
    assign s_axis_tready = (DROP_WHEN_FULL || MARK_WHEN_FULL) ? 1'b1 : s_can_accept;

    // Tvalid
    assign m_axis_tvalid = m_can_read;

    // Status pulses
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow_pulse <= 1'b0;
            s_bad_frame <= 1'b0;
            s_good_frame <= 1'b0;
            s_frame_overflow <= 1'b0;
        end else begin
            s_overflow_pulse <= s_overflow;
            if (s_write_en && s_axis_tlast) begin
                if (s_bad_frame_det || (DROP_OVERSIZE_FRAME && s_oversize)) begin
                    s_bad_frame <= 1'b1;
                    s_good_frame <= 1'b0;
                end else begin
                    s_bad_frame <= 1'b0;
                    s_good_frame <= 1'b1;
                end
            end
            if (s_write_en && s_full && !DROP_WHEN_FULL && !MARK_WHEN_FULL) begin
                s_frame_overflow <= 1'b1;
            end else begin
                s_frame_overflow <= 1'b0;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_overflow_pulse <= 1'b0;
            m_bad_frame <= 1'b0;
            m_good_frame <= 1'b0;
            m_frame_overflow <= 1'b0;
        end else begin
            m_overflow_pulse <= m_overflow;
            if (m_read_en && m_tlast) begin
                if (m_bad_frame_det || (DROP_OVERSIZE_FRAME && m_oversize)) begin
                    m_bad_frame <= 1'b1;
                    m_good_frame <= 1'b0;
                end else begin
                    m_bad_frame <= 1'b0;
                    m_good_frame <= 1'b1;
                end
            end
            if (m_read_en && m_empty) begin
                m_frame_overflow <= 1'b1;
            end else begin
                m_frame_overflow <= 1'b0;
            end
        end
    end

    assign s_status_overflow = s_overflow_pulse;
    assign m_status_overflow = m_overflow_pulse;
    assign s_status_bad_frame = s_bad_frame;
    assign m_status_bad_frame = m_bad_frame;
    assign s_status_good_frame = s_good_frame;
    assign m_status_good_frame = m_good_frame;

    // Async FIFO core
    // Write pointer
    reg [PTR_WIDTH-1:0] s_wr_ptr_reg;
    reg [ADDR_WIDTH-1:0] s_wr_addr_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr_reg <= {PTR_WIDTH{1'b0}};
            s_wr_addr_reg <= {ADDR_WIDTH{1'b0}};
        end else if (s_write_en) begin
            s_wr_ptr_reg <= s_wr_ptr_reg + 1'b1;
            s_wr_addr_reg <= s_wr_addr_reg + 1'b1;
        end
    end

    assign s_wr_ptr = s_wr_ptr_reg;
    assign s_write_addr = s_wr_addr_reg;

    // Read pointer
    reg [PTR_WIDTH-1:0] m_rd_ptr_reg;
    reg [ADDR_WIDTH-1:0] m_rd_addr_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr_reg <= {PTR_WIDTH{1'b0}};
            m_rd_addr_reg <= {ADDR_WIDTH{1'b0}};
        end else if (m_read_en) begin
            m_rd_ptr_reg <= m_rd_ptr_reg + 1'b1;
            m_rd_addr_reg <= m_rd_addr_reg + 1'b1;
        end
    end

    assign m_rd_ptr = m_rd_ptr_reg;
    assign m_read_addr = m_rd_addr_reg;

    // Synchronizers
    reg [PTR_WIDTH-1:0] s_wr_ptr_sync_m_r1, s_wr_ptr_sync_m_r2, s_wr_ptr_sync_m_r3;
    reg [PTR_WIDTH-1:0] m_rd_ptr_sync_s_r1, m_rd_ptr_sync_s_r2, m_rd_ptr_sync_s_r3;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_sync_m_r1 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_sync_m_r2 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_sync_m_r3 <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_sync_m_r1 <= s_wr_ptr;
            s_wr_ptr_sync_m_r2 <= s_wr_ptr_sync_m_r1;
            s_wr_ptr_sync_m_r3 <= s_wr_ptr_sync_m_r2;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_sync_s_r1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync_s_r2 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync_s_r3 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_sync_s_r1 <= m_rd_ptr;
            m_rd_ptr_sync_s_r2 <= m_rd_ptr_sync_s_r1;
            m_rd_ptr_sync_s_r3 <= m_rd_ptr_sync_s_r2;
        end
    end

    assign s_wr_ptr_sync_m = s_wr_ptr_sync_m_r3;
    assign m_rd_ptr_sync_s = m_rd_ptr_sync_s_r3;

    // RAM
    reg [TOTAL_WIDTH-1:0] ram [0:DEPTH-1];

    // Write to RAM
    always @(posedge s_clk) begin
        if (s_write_en) begin
            ram[s_write_addr] <= s_write_data;
        end
    end

    // Read from RAM
    reg [TOTAL_WIDTH-1:0] m_read_data_reg;
    reg m_read_data_valid;

    if (RAM_PIPELINE) begin
        // Pipelined read
        reg [ADDR_WIDTH-1:0] m_read_addr_r1;
        reg m_read_en_r1;

        always @(posedge m_clk or posedge m_rst) begin
            if (m_rst) begin
                m_read_addr_r1 <= {ADDR_WIDTH{1'b0}};
                m_read_en_r1 <= 1'b0;
                m_read_data_reg <= {TOTAL_WIDTH{1'b0}};
                m_read_data_valid <= 1'b0;
            end else begin
                m_read_addr_r1 <= m_read_addr;
                m_read_en_r1 <= m_read_en;
                if (m_read_en_r1) begin
                    m_read_data_reg <= ram[m_read_addr_r1];
                    m_read_data_valid <= 1'b1;
                end else begin
                    m_read_data_valid <= 1'b0;
                end
            end
        end

        assign m_read_data = m_read_data_reg;
    end else begin
        // Non-pipelined read
        always @(posedge m_clk or posedge m_rst) begin
            if (m_rst) begin
                m_read_data_reg <= {TOTAL_WIDTH{1'b0}};
                m_read_data_valid <= 1'b0;
            end else begin
                if (m_read_en) begin
                    m_read_data_reg <= ram[m_read_addr];
                    m_read_data_valid <= 1'b1;
                end else begin
                    m_read_data_valid <= 1'b0;
                end
            end
        end

        assign m_read_data = m_read_data_reg;
    end

endmodule
