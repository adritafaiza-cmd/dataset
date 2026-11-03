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

    localparam PTR_WIDTH = $clog2(DEPTH);
    localparam DEPTH_MASK = DEPTH - 1;
    localparam S_BYTES = (S_DATA_WIDTH + 7) / 8;
    localparam M_BYTES = (M_DATA_WIDTH + 7) / 8;
    localparam S_KEEP_W = S_KEEP_ENABLE ? S_KEEP_WIDTH : 1;
    localparam M_KEEP_W = M_KEEP_ENABLE ? M_KEEP_WIDTH : 1;
    localparam ID_W = ID_ENABLE ? ID_WIDTH : 1;
    localparam DEST_W = DEST_ENABLE ? DEST_WIDTH : 1;
    localparam USER_W = USER_ENABLE ? USER_WIDTH : 1;

    // Source domain
    reg [PTR_WIDTH:0] s_wr_ptr;
    reg [PTR_WIDTH:0] s_rd_ptr_sync;
    reg [S_DATA_WIDTH-1:0] s_ram [0:DEPTH-1];
    reg [S_KEEP_W-1:0] s_ram_keep [0:DEPTH-1];
    reg s_ram_tlast [0:DEPTH-1];
    reg [ID_W-1:0] s_ram_tid [0:DEPTH-1];
    reg [DEST_W-1:0] s_ram_tdest [0:DEPTH-1];
    reg [USER_W-1:0] s_ram_tuser [0:DEPTH-1];

    wire s_wr_en = s_axis_tvalid & s_axis_tready;
    wire s_full = (s_wr_ptr - s_rd_ptr_sync) == DEPTH;
    wire s_empty = (s_wr_ptr == s_rd_ptr_sync);

    assign s_axis_tready = !s_full;

    // Destination domain
    reg [PTR_WIDTH:0] m_rd_ptr;
    reg [PTR_WIDTH:0] m_wr_ptr_sync;
    reg [M_DATA_WIDTH-1:0] m_ram [0:DEPTH-1];
    reg [M_KEEP_W-1:0] m_ram_keep [0:DEPTH-1];
    reg m_ram_tlast [0:DEPTH-1];
    reg [ID_W-1:0] m_ram_tid [0:DEPTH-1];
    reg [DEST_W-1:0] m_ram_tdest [0:DEPTH-1];
    reg [USER_W-1:0] m_ram_tuser [0:DEPTH-1];

    wire m_rd_en = m_axis_tvalid & m_axis_tready;
    wire m_full = (m_wr_ptr_sync - m_rd_ptr) == DEPTH;
    wire m_empty = (m_wr_ptr_sync == m_rd_ptr);

    assign m_axis_tvalid = !m_empty;

    // CDC: s_wr_ptr -> m domain
    reg [PTR_WIDTH:0] s_wr_ptr_m1, s_wr_ptr_m2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_m1 <= {({PTR_WIDTH+1}{1'b0})};
            s_wr_ptr_m2 <= {({PTR_WIDTH+1}{1'b0})};
        end else begin
            s_wr_ptr_m1 <= s_wr_ptr;
            s_wr_ptr_m2 <= s_wr_ptr_m1;
        end
    end
    assign m_wr_ptr_sync = s_wr_ptr_m2;

    // CDC: m_rd_ptr -> s domain
    reg [PTR_WIDTH:0] m_rd_ptr_s1, m_rd_ptr_s2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_s1 <= {({PTR_WIDTH+1}{1'b0})};
            m_rd_ptr_s2 <= {({PTR_WIDTH+1}{1'b0})};
        end else begin
            m_rd_ptr_s1 <= m_rd_ptr;
            m_rd_ptr_s2 <= m_rd_ptr_s1;
        end
    end
    assign s_rd_ptr_sync = m_rd_ptr_s2;

    // Source write
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {({PTR_WIDTH+1}{1'b0})};
        end else if (s_wr_en) begin
            s_ram[s_wr_ptr[PTR_WIDTH-1:0]] <= s_axis_tdata;
            if (S_KEEP_ENABLE) s_ram_keep[s_wr_ptr[PTR_WIDTH-1:0]] <= s_axis_tkeep;
            s_ram_tlast[s_wr_ptr[PTR_WIDTH-1:0]] <= s_axis_tlast;
            if (ID_ENABLE) s_ram_tid[s_wr_ptr[PTR_WIDTH-1:0]] <= s_axis_tid;
            if (DEST_ENABLE) s_ram_tdest[s_wr_ptr[PTR_WIDTH-1:0]] <= s_axis_tdest;
            if (USER_ENABLE) s_ram_tuser[s_wr_ptr[PTR_WIDTH-1:0]] <= s_axis_tuser;
            s_wr_ptr <= s_wr_ptr + 1'b1;
        end
    end

    // Destination read
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {({PTR_WIDTH+1}{1'b0})};
        end else if (m_rd_en) begin
            m_rd_ptr <= m_rd_ptr + 1'b1;
        end
    end

    // Destination output
    assign m_axis_tdata = m_ram[m_rd_ptr[PTR_WIDTH-1:0]];
    assign m_axis_tkeep = M_KEEP_ENABLE ? m_ram_keep[m_rd_ptr[PTR_WIDTH-1:0]] : {M_KEEP_W{1'b1}};
    assign m_axis_tlast = m_ram_tlast[m_rd_ptr[PTR_WIDTH-1:0]];
    assign m_axis_tid = ID_ENABLE ? m_ram_tid[m_rd_ptr[PTR_WIDTH-1:0]] : {ID_W{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? m_ram_tdest[m_rd_ptr[PTR_WIDTH-1:0]] : {DEST_W{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? m_ram_tuser[m_rd_ptr[PTR_WIDTH-1:0]] : {USER_W{1'b0}};

    // Pause
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    // Status
    assign s_status_depth = s_wr_ptr - s_rd_ptr_sync;
    assign s_status_depth_commit = s_wr_ptr - s_rd_ptr_sync;
    assign s_status_overflow = 1'b0;
    assign s_status_bad_frame = 1'b0;
    assign s_status_good_frame = 1'b0;

    assign m_status_depth = m_wr_ptr_sync - m_rd_ptr;
    assign m_status_depth_commit = m_wr_ptr_sync - m_rd_ptr;
    assign m_status_overflow = 1'b0;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b0;

endmodule
