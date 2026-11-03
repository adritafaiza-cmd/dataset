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
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
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
    wire [PTR_WIDTH-1:0] s_wr_ptr;
    wire [PTR_WIDTH-1:0] m_rd_ptr;
    wire [PTR_WIDTH-1:0] s_wr_ptr_sync;
    wire [PTR_WIDTH-1:0] m_rd_ptr_sync;

    // Write side (s_clk domain)
    wire s_wr_en_internal = s_axis_tvalid & s_axis_tready;
    assign s_wr_en = s_wr_en_internal;

    // Read side (m_clk domain)
    wire m_rd_en_internal = m_axis_tvalid & m_axis_tready;
    assign m_rd_en = m_rd_en_internal;

    // Async FIFO core
    async_fifo_core #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(S_DATA_WIDTH),
        .KEEP_ENABLE(S_KEEP_ENABLE),
        .KEEP_WIDTH(S_KEEP_WIDTH),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH)
    ) u_async_fifo (
        .wr_clk(s_clk),
        .wr_rst(s_rst),
        .wr_en(s_wr_en),
        .wr_data(s_axis_tdata),
        .wr_keep(s_axis_tkeep),
        .wr_tlast(s_axis_tlast),
        .wr_tid(s_axis_tid),
        .wr_tdest(s_axis_tdest),
        .wr_tuser(s_axis_tuser),
        .full(s_full),
        .wr_ptr(s_wr_ptr),
        .rd_clk(m_clk),
        .rd_rst(m_rst),
        .rd_en(m_rd_en),
        .rd_data(m_axis_tdata),
        .rd_keep(m_axis_tkeep),
        .rd_tlast(m_axis_tlast),
        .rd_tid(m_axis_tid),
        .rd_tdest(m_axis_tdest),
        .rd_tuser(m_axis_tuser),
        .empty(m_empty),
        .rd_ptr(m_rd_ptr)
    );

    // Pointer synchronization
    // S domain: sync m_rd_ptr
    reg [PTR_WIDTH-1:0] m_rd_ptr_sync_r1, m_rd_ptr_sync_r2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_sync_r1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_sync_r2 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_sync_r1 <= m_rd_ptr;
            m_rd_ptr_sync_r2 <= m_rd_ptr_sync_r1;
        end
    end
    assign s_wr_ptr_sync = m_rd_ptr_sync_r2;

    // M domain: sync s_wr_ptr
    reg [PTR_WIDTH-1:0] s_wr_ptr_sync_r1, s_wr_ptr_sync_r2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_sync_r1 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_sync_r2 <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_sync_r1 <= s_wr_ptr;
            s_wr_ptr_sync_r2 <= s_wr_ptr_sync_r1;
        end
    end
    assign m_rd_ptr_sync = s_wr_ptr_sync_r2;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth_diff = s_wr_ptr - m_rd_ptr_sync_r2;
    wire [PTR_WIDTH-1:0] m_depth_diff = s_wr_ptr_sync_r2 - m_rd_ptr;

    assign s_status_depth = s_depth_diff;
    assign m_status_depth = m_depth_diff;

    // Commit depth (same as depth for this implementation)
    assign s_status_depth_commit = s_depth_diff;
    assign m_status_depth_commit = m_depth_diff;

    // Ready signals
    wire s_pause_active = PAUSE_ENABLE ? s_pause_req : 1'b0;
    wire m_pause_active = PAUSE_ENABLE ? m_pause_req : 1'b0;

    assign s_axis_tready = !s_full & !s_pause_active;
    assign m_axis_tvalid = !m_empty & !m_pause_active;

    // Pause ack
    assign s_pause_ack = PAUSE_ENABLE ? s_pause_req : 1'b0;
    assign m_pause_ack = PAUSE_ENABLE ? m_pause_req : 1'b0;

    // Status flags
    reg s_overflow_r, m_overflow_r;
    reg s_bad_frame_r, m_bad_frame_r;
    reg s_good_frame_r, m_good_frame_r;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow_r <= 1'b0;
            s_bad_frame_r <= 1'b0;
            s_good_frame_r <= 1'b0;
        end else begin
            if (s_wr_en & s_full) begin
                s_overflow_r <= 1'b1;
            end
            if (s_wr_en & s_axis_tlast) begin
                s_good_frame_r <= 1'b1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_overflow_r <= 1'b0;
            m_bad_frame_r <= 1'b0;
            m_good_frame_r <= 1'b0;
        end else begin
            if (m_rd_en & m_empty) begin
                m_overflow_r <= 1'b0; // Underflow not expected, but clear
            end
            if (m_rd_en & m_axis_tlast) begin
                m_good_frame_r <= 1'b1;
            end
        end
    end

    assign s_status_overflow = s_overflow_r;
    assign m_status_overflow = m_overflow_r;
    assign s_status_bad_frame = s_bad_frame_r;
    assign m_status_bad_frame = m_bad_frame_r;
    assign s_status_good_frame = s_good_frame_r;
    assign m_status_good_frame = m_good_frame_r;

endmodule

module async_fifo_core #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = 0,
    parameter KEEP_WIDTH = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 0,
    parameter USER_WIDTH = 1
) (
    input  wire                     wr_clk,
    input  wire                     wr_rst,
    input  wire                     wr_en,
    input  wire [DATA_WIDTH-1:0]    wr_data,
    input  wire [KEEP_WIDTH-1:0]    wr_keep,
    input  wire                     wr_tlast,
    input  wire [ID_WIDTH-1:0]      wr_tid,
    input  wire [DEST_WIDTH-1:0]    wr_tdest,
    input  wire [USER_WIDTH-1:0]    wr_tuser,
    output wire                     full,
    output wire [$clog2(DEPTH):0]   wr_ptr,
    input  wire                     rd_clk,
    input  wire                     rd_rst,
    input  wire                     rd_en,
    output wire [DATA_WIDTH-1:0]    rd_data,
    output wire [KEEP_WIDTH-1:0]    rd_keep,
    output wire                     rd_tlast,
    output wire [ID_WIDTH-1:0]      rd_tid,
    output wire [DEST_WIDTH-1:0]    rd_tdest,
    output wire [USER_WIDTH-1:0]    rd_tuser,
    output wire                     empty,
    output wire [$clog2(DEPTH):0]   rd_ptr
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    // RAM storage
    reg [DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg                  ram_tlast [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   ram_tid [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_tdest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_tuser [0:DEPTH-1];

    // Write pointer
    reg [PTR_WIDTH-1:0] wr_ptr_r;
    assign wr_ptr = wr_ptr_r;

    // Read pointer
    reg [PTR_WIDTH-1:0] rd_ptr_r;
    assign rd_ptr = rd_ptr_r;

    // Synchronized pointers
    reg [PTR_WIDTH-1:0] wr_ptr_sync_r1, wr_ptr_sync_r2;
    reg [PTR_WIDTH-1:0] rd_ptr_sync_r1, rd_ptr_sync_r2;

    // Write domain: sync read pointer
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_ptr_sync_r1 <= {PTR_WIDTH{1'b0}};
            wr_ptr_sync_r2 <= {PTR_WIDTH{1'b0}};
        end else begin
            wr_ptr_sync_r1 <= rd_ptr_r;
            wr_ptr_sync_r2 <= wr_ptr_sync_r1;
        end
    end

    // Read domain: sync write pointer
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_ptr_sync_r1 <= {PTR_WIDTH{1'b0}};
            rd_ptr_sync_r2 <= {PTR_WIDTH{1'b0}};
        end else begin
            rd_ptr_sync_r1 <= wr_ptr_r;
            rd_ptr_sync_r2 <= rd_ptr_sync_r1;
        end
    end

    // Full and empty detection
    wire [PTR_WIDTH-1:0] wr_ptr_sync_diff = wr_ptr_r - wr_ptr_sync_r2;
    wire [PTR_WIDTH-1:0] rd_ptr_sync_diff = rd_ptr_r - rd_ptr_sync_r2;

    assign full = (wr_ptr_sync_diff == DEPTH);
    assign empty = (rd_ptr_sync_diff == 0);

    // Write logic
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_ptr_r <= {PTR_WIDTH{1'b0}};
        end else if (wr_en & !full) begin
            ram_data[wr_ptr_r[ADDR_WIDTH-1:0]] <= wr_data;
            ram_keep[wr_ptr_r[ADDR_WIDTH-1:0]] <= wr_keep;
            ram_tlast[wr_ptr_r[ADDR_WIDTH-1:0]] <= wr_tlast;
            ram_tid[wr_ptr_r[ADDR_WIDTH-1:0]] <= wr_tid;
            ram_tdest[wr_ptr_r[ADDR_WIDTH-1:0]] <= wr_tdest;
            ram_tuser[wr_ptr_r[ADDR_WIDTH-1:0]] <= wr_tuser;
            wr_ptr_r <= wr_ptr_r + 1'b1;
        end
    end

    // Read logic
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_ptr_r <= {PTR_WIDTH{1'b0}};
        end else if (rd_en & !empty) begin
            rd_ptr_r <= rd_ptr_r + 1'b1;
        end
    end

    // Output data (combinational read from RAM)
    assign rd_data = ram_data[rd_ptr_r[ADDR_WIDTH-1:0]];
    assign rd_keep = ram_keep[rd_ptr_r[ADDR_WIDTH-1:0]];
    assign rd_tlast = ram_tlast[rd_ptr_r[ADDR_WIDTH-1:0]];
    assign rd_tid = ram_tid[rd_ptr_r[ADDR_WIDTH-1:0]];
    assign rd_tdest = ram_tdest[rd_ptr_r[ADDR_WIDTH-1:0]];
    assign rd_tuser = ram_tuser[rd_ptr_r[ADDR_WIDTH-1:0]];

endmodule
