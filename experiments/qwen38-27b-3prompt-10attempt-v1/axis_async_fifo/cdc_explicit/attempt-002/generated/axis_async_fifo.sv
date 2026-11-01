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

    // Concatenated data for storage
    wire [TOTAL_WIDTH-1:0] s_axis_tdata_full;
    wire [TOTAL_WIDTH-1:0] m_axis_tdata_full;

    // Build full data word
    // Order: data, keep, last, id, dest, user
    // We'll use a simple concatenation based on enables
    // For simplicity in this implementation, we'll store them separately in the RAM
    // But for CDC, we need to cross the entire beat atomically.
    // Let's define the storage format.

    // Actually, let's just cross the individual signals using a multi-bit CDC synchronizer
    // for the pointers, and use a RAM for the data.
    // The data is written in s_clk domain and read in m_clk domain.
    // We need to ensure that the data is stable when read.

    // Standard async FIFO architecture:
    // 1. Write pointer in s_clk domain
    // 2. Read pointer in m_clk domain
    // 3. Cross write pointer to m_clk domain (synchronized)
    // 4. Cross read pointer to s_clk domain (synchronized)
    // 5. RAM is dual-port: write in s_clk, read in m_clk

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] s_wr_ptr;
    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:1] m_rd_ptr;

    // Synchronized pointers
    reg [PTR_WIDTH-1:0] s_wr_ptr_m_sync; // Write pointer synchronized to m_clk
    reg [PTR_WIDTH-1:0] m_rd_ptr_s_sync; // Read pointer synchronized to s_clk

    // RAM storage
    // We'll store data and sidebands separately for clarity
    reg [DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    
    // Sideband storage - we'll pack them into a single vector for simplicity
    // Or store separately. Let's store separately.
    
    // For KEEP
    reg [KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    // For LAST
    reg [0:0] ram_last [0:DEPTH-1];
    // For ID
    reg [ID_WIDTH-1:0] ram_id [0:DEPTH-1];
    // For DEST
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    // For USER
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    // Write enable
    wire s_wr_en;
    // Read enable
    wire m_rd_en;

    // Full and empty detection
    wire s_full;
    wire m_empty;

    // Write address
    wire [ADDR_WIDTH-1:0] s_wr_addr;
    // Read address
    wire [ADDR_WIDTH-1:0] m_rd_addr;

    // Assign addresses
    assign s_wr_addr = s_wr_ptr[ADDR_WIDTH-1:0];
    assign m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];

    // Full detection: write pointer has lapped read pointer by DEPTH
    // s_wr_ptr_m_sync is the write pointer as seen in m_clk domain
    // m_rd_ptr is the read pointer in m_clk domain
    // Full when (s_wr_ptr_m_sync - m_rd_ptr) == DEPTH
    // Since pointers are PTR_WIDTH bits, and DEPTH is power of 2,
    // we can check if the upper bits are equal and lower bits differ by DEPTH
    
    // Actually, standard async FIFO full check:
    // Full when write pointer has advanced DEPTH ahead of read pointer
    // s_wr_ptr_m_sync[ADDR_WIDTH:1] == m_rd_ptr[ADDR_WIDTH:1] && 
    // s_wr_ptr_m_sync[0] != m_rd_ptr[0]
    // Wait, that's for DEPTH = 2^ADDR_WIDTH.
    // More generally:
    // Full when (s_wr_ptr_m_sync - m_rd_ptr) == DEPTH
    // Since DEPTH is power of 2, this means the upper bits are equal and the lower bits are different
    // Specifically, s_wr_ptr_m_sync[ADDR_WIDTH:1] == m_rd_ptr[ADDR_WIDTH:1] && 
    // s_wr_ptr_m_sync[0] != m_rd_ptr[0]
    // But this only works if DEPTH = 2^ADDR_WIDTH.
    // For general DEPTH, we need to compare the difference.
    
    // Let's use a simpler approach:
    // Full when the write pointer has lapped the read pointer by exactly DEPTH
    // We can compute the difference in m_clk domain
    
    wire [PTR_WIDTH-1:0] m_depth;
    assign m_depth = s_wr_ptr_m_sync - m_rd_ptr;
    
    assign s_full = (m_depth == DEPTH);
    
    // Empty detection in m_clk domain
    assign m_empty = (s_wr_ptr_m_sync == m_rd_ptr);

    // Write enable: valid and not full (or drop when full)
    wire s_wr_allowed;
    assign s_wr_allowed = s_axis_tvalid && (!s_full || DROP_WHEN_FULL);
    
    assign s_wr_en = s_wr_allowed;

    // Read enable: not empty and ready
    assign m_rd_en = (!m_empty) && m_axis_tready;

    // Write pointer increment
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
        else if (s_wr_en)
            s_wr_ptr <= s_wr_ptr + 1'b1;
    end

    // Read pointer increment
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
        else if (m_rd_en)
            m_rd_ptr <= m_rd_ptr + 1'b1;
    end

    // Synchronize write pointer to m_clk domain
    // Use 2-stage synchronizer for each bit
    reg [PTR_WIDTH-1:0] s_wr_ptr_m_sync1;
    reg [PTR_WIDTH-1:0] s_wr_ptr_m_sync2;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_m_sync1 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_m_sync2 <= {PTR_WIDTH{1'b0}};
        end
        else begin
            s_wr_ptr_m_sync1 <= s_wr_ptr;
            s_wr_ptr_m_sync2 <= s_wr_ptr_m_sync1;
        end
    end
    
    assign s_wr_ptr_m_sync = s_wr_ptr_m_sync2;

    // Synchronize read pointer to s_clk domain
    reg [PTR_WIDTH-1:0] m_rd_ptr_s_sync1;
    reg [PTR_WIDTH-1:0] m_rd_ptr_s_sync2;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_s_sync1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_s_sync2 <= {PTR_WIDTH{1'b0}};
        end
        else begin
            m_rd_ptr_s_sync1 <= m_rd_ptr;
            m_rd_ptr_s_sync2 <= m_rd_ptr_s_sync1;
        end
    end
    
    assign m_rd_ptr_s_sync = m_rd_ptr_s_sync2;

    // RAM write
    always @(posedge s_clk) begin
        if (s_wr_en) begin
            ram_data[s_wr_addr] <= s_axis_tdata;
            if (KEEP_ENABLE)
                ram_keep[s_wr_addr] <= s_axis_tkeep;
            if (LAST_ENABLE)
                ram_last[s_wr_addr] <= s_axis_tlast;
            if (ID_ENABLE)
                ram_id[s_wr_addr] <= s_axis_tid;
            if (DEST_ENABLE)
                ram_dest[s_wr_addr] <= s_axis_tdest;
            if (USER_ENABLE)
                ram_user[s_wr_addr] <= s_axis_tuser;
        end
    end

    // RAM read
    // Read data from RAM
    wire [DATA_WIDTH-1:0] m_rd_data;
    wire [KEEP_WIDTH-1:0] m_rd_keep;
    wire m_rd_last;
    wire [ID_WIDTH-1:0] m_rd_id;
    wire [DEST_WIDTH-1:0] m_rd_dest;
    wire [USER_WIDTH-1:0] m_rd_user;

    assign m_rd_data = ram_data[m_rd_addr];
    assign m_rd_keep = ram_keep[m_rd_addr];
    assign m_rd_last = ram_last[m_rd_addr];
    assign m_rd_id = ram_id[m_rd_addr];
    assign m_rd_dest = ram_dest[m_rd_addr];
    assign m_rd_user = ram_user[m_rd_addr];

    // Output assignment
    assign m_axis_tdata = m_rd_data;
    assign m_axis_tkeep = KEEP_ENABLE ? m_rd_keep : {KEEP_WIDTH{1'b0}};
    assign m_axis_tlast = LAST_ENABLE ? m_rd_last : 1'b0;
    assign m_axis_tid = ID_ENABLE ? m_rd_id : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? m_rd_dest : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? m_rd_user : {USER_WIDTH{1'b0}};

    assign m_axis_tvalid = !m_empty;

    // tready for input
    // tready is high when we can accept more data
    // We can accept if not full, or if drop_when_full is set
    assign s_axis_tready = !s_full || DROP_WHEN_FULL;

    // Pause logic
    // Simple implementation: pause_ack is just the pause_req synchronized
    // For now, let's implement basic pause
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_pause_ack_reg <= 1'b0;
        else
            s_pause_ack_reg <= s_pause_req;
    end
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_pause_ack_reg <= 1'b0;
        else
            m_pause_ack_reg <= m_pause_req;
    end
    
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Status signals
    // Depth in s_clk domain
    wire [PTR_WIDTH-1:0] s_depth;
    assign s_depth = s_wr_ptr - m_rd_ptr_s_sync;
    
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    
    // Depth in m_clk domain
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;

    // Overflow: when write happens while full
    wire s_overflow;
    assign s_overflow = s_axis_tvalid && s_full && !DROP_WHEN_FULL;
    
    // Bad frame and good frame - simplified
    // For now, let's just set these to 0
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = 1'b0;
    assign s_status_good_frame = 1'b0;
    
    assign m_status_overflow = 1'b0;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b0;

endmodule
