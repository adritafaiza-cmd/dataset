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

    // Internal signal declarations
    wire s_wr_en;
    wire m_rd_en;
    wire s_full;
    wire m_empty;
    wire [S_DATA_WIDTH-1:0] s_wr_data;
    wire [S_KEEP_WIDTH-1:0] s_wr_keep;
    wire s_wr_last;
    wire [ID_WIDTH-1:0] s_wr_id;
    wire [DEST_WIDTH-1:0] s_wr_dest;
    wire [USER_WIDTH-1:0] s_wr_user;

    wire [M_DATA_WIDTH-1:0] m_rd_data;
    wire [M_KEEP_WIDTH-1:0] m_rd_keep;
    wire m_rd_last;
    wire [ID_WIDTH-1:0] m_rd_id;
    wire [DEST_WIDTH-1:0] m_rd_dest;
    wire [USER_WIDTH-1:0] m_rd_user;

    // Write side (s_clk domain)
    reg [PTR_WIDTH-1:0] s_wr_ptr;
    reg [PTR_WIDTH-1:0] s_rd_ptr_sync;
    reg [PTR_WIDTH-1:0] s_rd_ptr_sync1;
    reg [PTR_WIDTH-1:0] s_rd_ptr_sync2;

    // Read side (m_clk domain)
    reg [PTR_WIDTH-1:0] m_rd_ptr;
    reg [PTR_WIDTH-1:0] m_wr_ptr_sync;
    reg [PTR_WIDTH-1:0] m_wr_ptr_sync1;
    reg [PTR_WIDTH-1:0] m_wr_ptr_sync2;

    // RAM storage
    reg [S_DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    // Write address
    wire [ADDR_WIDTH-1:0] s_wr_addr = s_wr_ptr[ADDR_WIDTH-1:0];

    // Read address
    wire [ADDR_WIDTH-1:0] m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];

    // Full/Empty logic
    assign s_full = (s_wr_ptr[PTR_WIDTH-1] != s_rd_ptr_sync2[PTR_WIDTH-1]) &&
                    (s_wr_ptr[ADDR_WIDTH-1:0] == s_rd_ptr_sync2[ADDR_WIDTH-1:0]);
    assign m_empty = (m_rd_ptr == m_wr_ptr_sync2);

    // Handshake logic
    wire s_accept = s_axis_tvalid && s_axis_tready;
    wire m_accept = m_axis_tvalid && m_axis_tready;

    assign s_axis_tready = !s_full;
    assign m_axis_tvalid = !m_empty;

    // Write enable
    assign s_wr_en = s_accept;

    // Read enable
    assign m_rd_en = m_accept;

    // Write data
    assign s_wr_data = s_axis_tdata;
    assign s_wr_keep = s_axis_tkeep;
    assign s_wr_last = s_axis_tlast;
    assign s_wr_id = s_axis_tid;
    assign s_wr_dest = s_axis_tdest;
    assign s_wr_user = s_axis_tuser;

    // Read data
    assign m_rd_data = ram_data[m_rd_addr];
    assign m_rd_keep = ram_keep[m_rd_addr];
    assign m_rd_last = ram_last[m_rd_addr];
    assign m_rd_id = ram_id[m_rd_addr];
    assign m_rd_dest = ram_dest[m_rd_addr];
    assign m_rd_user = ram_user[m_rd_addr];

    // Output assignment
    assign m_axis_tdata = m_rd_data;
    assign m_axis_tkeep = m_rd_keep;
    assign m_axis_tlast = m_rd_last;
    assign m_axis_tid = m_rd_id;
    assign m_axis_tdest = m_rd_dest;
    assign m_axis_tuser = m_rd_user;

    // Pause logic
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    // Status logic
    wire [PTR_WIDTH-1:0] s_depth = s_wr_ptr - s_rd_ptr_sync2;
    wire [PTR_WIDTH-1:0] m_depth = m_wr_ptr_sync2 - m_rd_ptr;

    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;

    // Overflow detection
    reg s_overflow;
    reg m_overflow;
    wire s_overflow_pulse = s_axis_tvalid && s_full;
    wire m_overflow_pulse = m_axis_tvalid && m_empty; // This shouldn't happen, but for safety

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_overflow <= 1'b0;
        else if (s_overflow_pulse)
            s_overflow <= 1'b1;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_overflow <= 1'b0;
        else if (m_overflow_pulse)
            m_overflow <= 1'b1;
    end

    assign s_status_overflow = s_overflow;
    assign m_status_overflow = m_overflow;

    // Frame status (simplified)
    reg s_bad_frame;
    reg s_good_frame;
    reg m_bad_frame;
    reg m_good_frame;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bad_frame <= 1'b0;
            s_good_frame <= 1'b0;
        end else begin
            if (s_accept && s_axis_tlast) begin
                s_good_frame <= 1'b1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bad_frame <= 1'b0;
            m_good_frame <= 1'b0;
        end else begin
            if (m_accept && m_rd_last) begin
                m_good_frame <= 1'b1;
            end
        end
    end

    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
        else if (s_wr_en)
            s_wr_ptr <= s_wr_ptr + 1'b1;
    end

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
        else if (m_rd_en)
            m_rd_ptr <= m_rd_ptr + 1'b1;
    end

    // RAM write
    always @(posedge s_clk) begin
        if (s_wr_en) begin
            ram_data[s_wr_addr] <= s_wr_data;
            ram_keep[s_wr_addr] <= s_wr_keep;
            ram_last[s_wr_addr] <= s_wr_last;
            ram_id[s_wr_addr] <= s_wr_id;
            ram_dest[s_wr_addr] <= s_wr_dest;
            ram_user[s_wr_addr] <= s_wr_user;
        end
    end

    // Synchronizers
    // s_rd_ptr to m_clk domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_rd_ptr_sync <= {PTR_WIDTH{1'b0}};
            s_rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            s_rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            s_rd_ptr_sync <= m_rd_ptr;
            s_rd_ptr_sync1 <= s_rd_ptr_sync;
            s_rd_ptr_sync2 <= s_rd_ptr_sync1;
        end
    end

    // m_wr_ptr to s_clk domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_wr_ptr_sync <= {PTR_WIDTH{1'b0}};
            m_wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            m_wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_wr_ptr_sync <= s_wr_ptr;
            m_wr_ptr_sync1 <= m_wr_ptr_sync;
            m_wr_ptr_sync2 <= m_wr_ptr_sync1;
        end
    end

endmodule
