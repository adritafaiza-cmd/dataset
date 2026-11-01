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
    wire [S_DATA_WIDTH-1:0] s_wr_data;
    wire [S_KEEP_WIDTH-1:0] s_wr_keep;
    wire s_wr_last;
    wire [ID_WIDTH-1:0] s_wr_id;
    wire [DEST_WIDTH-1:0] s_wr_dest;
    wire [USER_WIDTH-1:0] s_wr_user;
    wire s_wr_en;
    wire s_full;
    wire s_empty;
    wire [PTR_WIDTH-1:0] s_wr_ptr;
    wire [PTR_WIDTH-1:0] s_rd_ptr_s;

    wire [M_DATA_WIDTH-1:0] m_rd_data;
    wire [M_KEEP_WIDTH-1:0] m_rd_keep;
    wire m_rd_last;
    wire [ID_WIDTH-1:0] m_rd_id;
    wire [DEST_WIDTH-1:0] m_rd_dest;
    wire [USER_WIDTH-1:0] m_rd_user;
    wire m_rd_en;
    wire m_full;
    wire m_empty;
    wire [PTR_WIDTH-1:0] m_rd_ptr;
    wire [PTR_WIDTH-1:0] m_wr_ptr_m;

    // Pause logic
    wire s_pause_active;
    wire m_pause_active;

    // Status logic
    wire s_overflow_pulse;
    wire s_bad_frame_pulse;
    wire s_good_frame_pulse;
    wire m_overflow_pulse;
    wire m_bad_frame_pulse;
    wire m_good_frame_pulse;

    // Synchronous reset generation
    reg s_rst_sync_0, s_rst_sync_1;
    reg m_rst_sync_0, m_rst_sync_1;
    wire s_rst_sync;
    wire m_rst_sync;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rst_sync_0 <= 1'b1;
            s_rst_sync_1 <= 1'b1;
        end else begin
            s_rst_sync_0 <= 1'b0;
            s_rst_sync_1 <= s_rst_sync_0;
        end
    end
    assign s_rst_sync = s_rst_sync_1;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rst_sync_0 <= 1'b1;
            m_rst_sync_1 <= 1'b1;
        end else begin
            m_rst_sync_0 <= 1'b0;
            m_rst_sync_1 <= m_rst_sync_0;
        end
    end
    assign m_rst_sync = m_rst_sync_1;

    // Pause active signals
    assign s_pause_active = PAUSE_ENABLE ? s_pause_req : 1'b0;
    assign m_pause_active = PAUSE_ENABLE ? m_pause_req : 1'b0;

    // Write enable for S side
    assign s_wr_en = s_axis_tvalid && s_axis_tready && !s_pause_active;

    // Read enable for M side
    assign m_rd_en = m_axis_tvalid && m_axis_tready && !m_pause_active;

    // S side ready
    assign s_axis_tready = !s_full && !s_pause_active;

    // M side valid
    assign m_axis_tvalid = !m_empty && !m_pause_active;

    // Pause ack
    assign s_pause_ack = PAUSE_ENABLE ? s_pause_req : 1'b0;
    assign m_pause_ack = PAUSE_ENABLE ? m_pause_req : 1'b0;

    // Write data
    assign s_wr_data = s_axis_tdata;
    assign s_wr_keep = S_KEEP_ENABLE ? s_axis_tkeep : {S_KEEP_WIDTH{1'b1}};
    assign s_wr_last = s_axis_tlast;
    assign s_wr_id = ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}};
    assign s_wr_dest = DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
    assign s_wr_user = USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};

    // Read data
    assign m_axis_tdata = m_rd_data;
    assign m_axis_tkeep = M_KEEP_ENABLE ? m_rd_keep : {M_KEEP_WIDTH{1'b1}};
    assign m_axis_tlast = m_rd_last;
    assign m_axis_tid = ID_ENABLE ? m_rd_id : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? m_rd_dest : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? m_rd_user : {USER_WIDTH{1'b0}};

    // Status depth
    wire [PTR_WIDTH-1:0] s_depth_raw;
    wire [PTR_WIDTH-1:0] m_depth_raw;
    assign s_depth_raw = s_wr_ptr - s_rd_ptr_s;
    assign m_depth_raw = m_wr_ptr_m - m_rd_ptr;

    assign s_status_depth = s_depth_raw[$clog2(DEPTH):0];
    assign s_status_depth_commit = s_depth_raw[$clog2(DEPTH):0];
    assign m_status_depth = m_depth_raw[$clog2(DEPTH):0];
    assign m_status_depth_commit = m_depth_raw[$clog2(DEPTH):0];

    // Overflow/Bad/Good frame pulses
    assign s_overflow_pulse = s_axis_tvalid && s_full && !s_pause_active;
    assign m_overflow_pulse = m_axis_tvalid && m_full && !m_pause_active;

    // Bad frame detection (simplified: check user bad frame value)
    wire s_bad_frame;
    wire m_bad_frame;
    assign s_bad_frame = USER_ENABLE && (s_wr_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
    assign m_bad_frame = USER_ENABLE && (m_rd_user & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;

    assign s_bad_frame_pulse = s_wr_en && s_bad_frame;
    assign m_bad_frame_pulse = m_rd_en && m_bad_frame;

    assign s_good_frame_pulse = s_wr_en && s_wr_last && !s_bad_frame;
    assign m_good_frame_pulse = m_rd_en && m_rd_last && !m_bad_frame;

    // Status latches
    reg s_status_overflow_reg;
    reg s_status_bad_frame_reg;
    reg s_status_good_frame_reg;
    reg m_status_overflow_reg;
    reg m_status_bad_frame_reg;
    reg m_status_good_frame_reg;

    always @(posedge s_clk or posedge s_rst_sync) begin
        if (s_rst_sync) begin
            s_status_overflow_reg <= 1'b0;
            s_status_bad_frame_reg <= 1'b0;
            s_status_good_frame_reg <= 1'b0;
        end else begin
            if (s_overflow_pulse) s_status_overflow_reg <= 1'b1;
            if (s_bad_frame_pulse) s_status_bad_frame_reg <= 1'b1;
            if (s_good_frame_pulse) s_status_good_frame_reg <= 1'b1;
        end
    end

    always @(posedge m_clk or posedge m_rst_sync) begin
        if (m_rst_sync) begin
            m_status_overflow_reg <= 1'b0;
            m_status_bad_frame_reg <= 1'b0;
            m_status_good_frame_reg <= 1'b0;
        end else begin
            if (m_overflow_pulse) m_status_overflow_reg <= 1'b1;
            if (m_bad_frame_pulse) m_status_bad_frame_reg <= 1'b1;
            if (m_good_frame_pulse) m_status_good_frame_reg <= 1'b1;
        end
    end

    assign s_status_overflow = s_status_overflow_reg;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;
    assign m_status_overflow = m_status_overflow_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

    // Async FIFO with width adapter
    // S side: write pointer
    reg [PTR_WIDTH-1:0] s_wr_ptr_reg;
    reg [ADDR_WIDTH-1:0] s_wr_addr_reg;
    reg [S_DATA_WIDTH-1:0] s_wr_data_reg;
    reg [S_KEEP_WIDTH-1:0] s_wr_keep_reg;
    reg s_wr_last_reg;
    reg [ID_WIDTH-1:0] s_wr_id_reg;
    reg [DEST_WIDTH-1:0] s_wr_dest_reg;
    reg [USER_WIDTH-1:0] s_wr_user_reg;

    // M side: read pointer
    reg [PTR_WIDTH-1:0] m_rd_ptr_reg;
    reg [ADDR_WIDTH-1:0] m_rd_addr_reg;
    reg [M_DATA_WIDTH-1:0] m_rd_data_reg;
    reg [M_KEEP_WIDTH-1:0] m_rd_keep_reg;
    reg m_rd_last_reg;
    reg [ID_WIDTH-1:0] m_rd_id_reg;
    reg [DEST_WIDTH-1:0] m_rd_dest_reg;
    reg [USER_WIDTH-1:0] m_rd_user_reg;

    // CDC: S write pointer to M
    reg [PTR_WIDTH-1:0] s_wr_ptr_m_0, s_wr_ptr_m_1, s_wr_ptr_m_2;
    // CDC: M read pointer to S
    reg [PTR_WIDTH-1:0] m_rd_ptr_s_0, m_rd_ptr_s_1, m_rd_ptr_s_2;

    always @(posedge s_clk or posedge s_rst_sync) begin
        if (s_rst_sync) begin
            s_wr_ptr_reg <= {PTR_WIDTH{1'b0}};
            s_wr_addr_reg <= {ADDR_WIDTH{1'b0}};
            s_wr_data_reg <= {S_DATA_WIDTH{1'b0}};
            s_wr_keep_reg <= {S_KEEP_WIDTH{1'b0}};
            s_wr_last_reg <= 1'b0;
            s_wr_id_reg <= {ID_WIDTH{1'b0}};
            s_wr_dest_reg <= {DEST_WIDTH{1'b0}};
            s_wr_user_reg <= {USER_WIDTH{1'b0}};
        end else if (s_wr_en) begin
            s_wr_data_reg <= s_wr_data;
            s_wr_keep_reg <= s_wr_keep;
            s_wr_last_reg <= s_wr_last;
            s_wr_id_reg <= s_wr_id;
            s_wr_dest_reg <= s_wr_dest;
            s_wr_user_reg <= s_wr_user;
            s_wr_addr_reg <= s_wr_addr_reg + 1'b1;
            s_wr_ptr_reg <= s_wr_ptr_reg + 1'b1;
        end
    end

    always @(posedge m_clk or posedge m_rst_sync) begin
        if (m_rst_sync) begin
            m_rd_ptr_reg <= {PTR_WIDTH{1'b0}};
            m_rd_addr_reg <= {ADDR_WIDTH{1'b0}};
            m_rd_data_reg <= {M_DATA_WIDTH{1'b0}};
            m_rd_keep_reg <= {M_KEEP_WIDTH{1'b0}};
            m_rd_last_reg <= 1'b0;
            m_rd_id_reg <= {ID_WIDTH{1'b0}};
            m_rd_dest_reg <= {DEST_WIDTH{1'b0}};
            m_rd_user_reg <= {USER_WIDTH{1'b0}};
        end else if (m_rd_en) begin
            m_rd_addr_reg <= m_rd_addr_reg + 1'b1;
            m_rd_ptr_reg <= m_rd_ptr_reg + 1'b1;
        end
    end

    // CDC synchronizers
    always @(posedge m_clk or posedge m_rst_sync) begin
        if (m_rst_sync) begin
            s_wr_ptr_m_0 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_m_1 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_m_2 <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_m_0 <= s_wr_ptr_reg;
            s_wr_ptr_m_1 <= s_wr_ptr_m_0;
            s_wr_ptr_m_2 <= s_wr_ptr_m_1;
        end
    end

    always @(posedge s_clk or posedge s_rst_sync) begin
        if (s_rst_sync) begin
            m_rd_ptr_s_0 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_s_1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_s_2 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_s_0 <= m_rd_ptr_reg;
            m_rd_ptr_s_1 <= m_rd_ptr_s_0;
            m_rd_ptr_s_2 <= m_rd_ptr_s_1;
        end
    end

    assign s_rd_ptr_s = m_rd_ptr_s_2;
    assign m_wr_ptr_m = s_wr_ptr_m_2;

    // Full/Empty
    assign s_full = (s_wr_ptr_reg - s_rd_ptr_s) == DEPTH;
    assign m_empty = (m_rd_ptr_reg == m_wr_ptr_m);
    assign m_full = (m_wr_ptr_m - m_rd_ptr_reg) == DEPTH;

    // RAM storage
    reg [S_DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    // Write to RAM
    always @(posedge s_clk or posedge s_rst_sync) begin
        if (s_rst_sync) begin
            // No action needed for RAM
        end else if (s_wr_en) begin
            ram_data[s_wr_addr_reg] <= s_wr_data;
            ram_keep[s_wr_addr_reg] <= s_wr_keep;
            ram_last[s_wr_addr_reg] <= s_wr_last;
            ram_id[s_wr_addr_reg] <= s_wr_id;
            ram_dest[s_wr_addr_reg] <= s_wr_dest;
            ram_user[s_wr_addr_reg] <= s_wr_user;
        end
    end

    // Read from RAM (in M clock domain)
    wire [ADDR_WIDTH-1:0] m_rd_addr = m_rd_addr_reg;
    wire [S_DATA_WIDTH-1:0] ram_rd_data = ram_data[m_rd_addr];
    wire [S_KEEP_WIDTH-1:0] ram_rd_keep = ram_keep[m_rd_addr];
    wire ram_rd_last = ram_last[m_rd_addr];
    wire [ID_WIDTH-1:0] ram_rd_id = ram_id[m_rd_addr];
    wire [DEST_WIDTH-1:0] ram_rd_dest = ram_dest[m_rd_addr];
    wire [USER_WIDTH-1:0] ram_rd_user = ram_user[m_rd_addr];

    // Width adapter: S_DATA_WIDTH to M_DATA_WIDTH
    // For simplicity, assume S_DATA_WIDTH == M_DATA_WIDTH or direct mapping
    // If widths differ, we need a more complex adapter. Here we assume direct mapping.
    assign m_rd_data = ram_rd_data[M_DATA_WIDTH-1:0];
    assign m_rd_keep = ram_rd_keep[M_KEEP_WIDTH-1:0];
    assign m_rd_last = ram_rd_last;
    assign m_rd_id = ram_rd_id;
    assign m_rd_dest = ram_rd_dest;
    assign m_rd_user = ram_rd_user;

endmodule
