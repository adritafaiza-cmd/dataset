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
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    // Internal signals
    wire s_wr_en;
    wire m_rd_en;
    wire s_full;
    wire m_empty;
    wire [PTR_WIDTH-1:0] s_wr_ptr;
    wire [PTR_WIDTH-1:0] m_rd_ptr;
    wire [PTR_WIDTH-1:0] s_wr_ptr_sync;
    wire [PTR_WIDTH-1:0] m_rd_ptr_sync;

    // Pause logic
    wire s_pause_active;
    wire m_pause_active;

    assign s_pause_active = PAUSE_ENABLE ? s_pause_req : 1'b0;
    assign m_pause_active = PAUSE_ENABLE ? m_pause_req : 1'b0;

    assign s_pause_ack = PAUSE_ENABLE ? s_pause_req : 1'b0;
    assign m_pause_ack = PAUSE_ENABLE ? m_pause_req : 1'b0;

    // Write enable: valid and not full and not paused
    assign s_wr_en = s_axis_tvalid && !s_full && !s_pause_active;

    // Read enable: not empty and ready and not paused
    assign m_rd_en = !m_empty && m_axis_tready && !m_pause_active;

    // Synchronous FIFO core
    // We implement a simple dual-port RAM with binary pointers
    reg [S_DATA_WIDTH-1:0] ram [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];

    // Write pointer
    reg [PTR_WIDTH-1:0] s_wr_ptr_reg;
    assign s_wr_ptr = s_wr_ptr_reg;

    // Read pointer
    reg [PTR_WIDTH-1:0] m_rd_ptr_reg;
    assign m_rd_ptr = m_rd_ptr_reg;

    // Write pointer increment
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_wr_ptr_reg <= {PTR_WIDTH{1'b0}};
        else if (s_wr_en)
            s_wr_ptr_reg <= s_wr_ptr_reg + 1'b1;
    end

    // Read pointer increment
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rd_ptr_reg <= {PTR_WIDTH{1'b0}};
        else if (m_rd_en)
            m_rd_ptr_reg <= m_rd_ptr_reg + 1'b1;
    end

    // Write data to RAM
    always @(posedge s_clk) begin
        if (s_wr_en) begin
            ram[s_wr_ptr_reg[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            ram_keep[s_wr_ptr_reg[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
            ram_user[s_wr_ptr_reg[ADDR_WIDTH-1:0]] <= s_axis_tuser;
            ram_id[s_wr_ptr_reg[ADDR_WIDTH-1:0]] <= s_axis_tid;
            ram_dest[s_wr_ptr_reg[ADDR_WIDTH-1:0]] <= s_axis_tdest;
            ram_last[s_wr_ptr_reg[ADDR_WIDTH-1:0]] <= s_axis_tlast;
        end
    end

    // Read data from RAM
    wire [S_DATA_WIDTH-1:0] rd_data;
    wire [S_KEEP_WIDTH-1:0] rd_keep;
    wire [USER_WIDTH-1:0] rd_user;
    wire [ID_WIDTH-1:0] rd_id;
    wire [DEST_WIDTH-1:0] rd_dest;
    wire rd_last;

    assign rd_data = ram[m_rd_ptr_reg[ADDR_WIDTH-1:0]];
    assign rd_keep = ram_keep[m_rd_ptr_reg[ADDR_WIDTH-1:0]];
    assign rd_user = ram_user[m_rd_ptr_reg[ADDR_WIDTH-1:0]];
    assign rd_id = ram_id[m_rd_ptr_reg[ADDR_WIDTH-1:0]];
    assign rd_dest = ram_dest[m_rd_ptr_reg[ADDR_WIDTH-1:0]];
    assign rd_last = ram_last[m_rd_ptr_reg[ADDR_WIDTH-1:0]];

    // Pointer synchronization
    // Synchronize write pointer to m_clk domain
    reg [PTR_WIDTH-1:0] s_wr_ptr_sync_reg [0:2];
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_sync_reg[0] <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_sync_reg[1] <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_sync_reg[2] <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_sync_reg[0] <= s_wr_ptr;
            s_wr_ptr_sync_reg[1] <= s_wr_ptr_sync_reg[0];
            s_wr_ptr_sync_reg[2] <= s_wr_ptr_sync_reg[1];
        end
    end
    assign s_wr_ptr_sync = s_wr_ptr_sync_reg[2];

    // Synchronize read pointer to s_clk domain
    reg [PTR_WIDTH-1:0] m_rd_ptr_sync_reg [0:2];
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_sync_reg[0] <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync_reg[1] <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync_reg[2] <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_sync_reg[0] <= m_rd_ptr;
            m_rd_ptr_sync_reg[1] <= m_rd_ptr_sync_reg[0];
            m_rd_ptr_sync_reg[2] <= m_rd_ptr_sync_reg[1];
        end
    end
    assign m_rd_ptr_sync = m_rd_ptr_sync_reg[2];

    // Full and empty detection
    // Full: write pointer has lapped read pointer by DEPTH
    wire [PTR_WIDTH-1:0] s_wr_ptr_diff;
    wire [PTR_WIDTH-1:0] m_rd_ptr_diff;
    assign s_wr_ptr_diff = s_wr_ptr - m_rd_ptr_sync;
    assign m_rd_ptr_diff = m_rd_ptr - s_wr_ptr_sync;

    assign s_full = (s_wr_ptr_diff == DEPTH);
    assign m_empty = (m_rd_ptr_diff == 0);

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth;
    wire [PTR_WIDTH-1:0] m_depth;
    assign s_depth = s_wr_ptr - m_rd_ptr_sync;
    assign m_depth = m_rd_ptr - s_wr_ptr_sync;

    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;

    // Overflow detection
    reg s_overflow_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_overflow_reg <= 1'b0;
        else if (s_axis_tvalid && s_full)
            s_overflow_reg <= 1'b1;
    end
    assign s_status_overflow = s_overflow_reg;

    // Bad frame detection
    reg s_bad_frame_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_bad_frame_reg <= 1'b0;
        else if (s_wr_en && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
            s_bad_frame_reg <= 1'b1;
    end
    assign s_status_bad_frame = s_bad_frame_reg;

    // Good frame detection
    reg s_good_frame_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_good_frame_reg <= 1'b0;
        else if (s_wr_en && s_axis_tlast && !s_bad_frame_reg)
            s_good_frame_reg <= 1'b1;
    end
    assign s_status_good_frame = s_good_frame_reg;

    // Output side status
    reg m_overflow_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_overflow_reg <= 1'b0;
        else
            m_overflow_reg <= s_overflow_reg;
    end
    assign m_status_overflow = m_overflow_reg;

    reg m_bad_frame_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_bad_frame_reg <= 1'b0;
        else
            m_bad_frame_reg <= s_bad_frame_reg;
    end
    assign m_status_bad_frame = m_bad_frame_reg;

    reg m_good_frame_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_good_frame_reg <= 1'b0;
        else
            m_good_frame_reg <= s_good_frame_reg;
    end
    assign m_status_good_frame = m_good_frame_reg;

    // Width adapter: S_DATA_WIDTH to M_DATA_WIDTH
    // For simplicity, we assume S_DATA_WIDTH == M_DATA_WIDTH or handle basic cases
    // In a real implementation, this would be more complex
    reg [M_DATA_WIDTH-1:0] m_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_tkeep_reg;
    reg m_tlast_reg;
    reg [ID_WIDTH-1:0] m_tid_reg;
    reg [DEST_WIDTH-1:0] m_tdest_reg;
    reg [USER_WIDTH-1:0] m_tuser_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_tdata_reg <= {M_DATA_WIDTH{1'b0}};
            m_tkeep_reg <= {M_KEEP_WIDTH{1'b0}};
            m_tlast_reg <= 1'b0;
            m_tid_reg <= {ID_WIDTH{1'b0}};
            m_tdest_reg <= {DEST_WIDTH{1'b0}};
            m_tuser_reg <= {USER_WIDTH{1'b0}};
        end else if (m_rd_en) begin
            // Simple width conversion: just pass through if widths match
            // For different widths, this would need more logic
            if (S_DATA_WIDTH == M_DATA_WIDTH) begin
                m_tdata_reg <= rd_data;
                m_tkeep_reg <= rd_keep;
            end else begin
                // Basic truncation/padding
                m_tdata_reg <= rd_data[M_DATA_WIDTH-1:0];
                m_tkeep_reg <= rd_keep[M_KEEP_WIDTH-1:0];
            end
            m_tlast_reg <= rd_last;
            m_tid_reg <= rd_id;
            m_tdest_reg <= rd_dest;
            m_tuser_reg <= rd_user;
        end
    end

    assign m_axis_tdata = m_tdata_reg;
    assign m_axis_tkeep = m_tkeep_reg;
    assign m_axis_tvalid = !m_empty;
    assign m_axis_tlast = m_tlast_reg;
    assign m_axis_tid = m_tid_reg;
    assign m_axis_tdest = m_tdest_reg;
    assign m_axis_tuser = m_tuser_reg;

    // Input ready
    assign s_axis_tready = !s_full && !s_pause_active;

endmodule
