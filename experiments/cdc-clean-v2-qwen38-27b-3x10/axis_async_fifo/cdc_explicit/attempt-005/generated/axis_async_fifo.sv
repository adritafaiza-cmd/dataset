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
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
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
    localparam DEPTH_MASK = DEPTH - 1;

    // Total width of stored data
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + 
        (KEEP_ENABLE ? KEEP_WIDTH : 0) +
        (LAST_ENABLE ? 1 : 0) +
        (ID_ENABLE ? ID_WIDTH : 0) +
        (DEST_ENABLE ? DEST_WIDTH : 0) +
        (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    wire [ADDR_WIDTH:0] s_wr_ptr;
    wire [ADDR_WIDTH:0] s_rd_ptr_sync;
    wire [ADDR_WIDTH:0] m_rd_ptr;
    wire [ADDR_WIDTH:0] m_wr_ptr_sync;

    wire s_wr_en;
    wire m_rd_en;

    // RAM storage
    reg [TOTAL_DATA_WIDTH-1:0] ram [0:DEPTH-1];

    // Write side (s_clk domain)
    wire [ADDR_WIDTH-1:0] s_wr_addr = s_wr_ptr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] s_rd_addr = s_rd_ptr_sync[ADDR_WIDTH-1:0];

    // Read side (m_clk domain)
    wire [ADDR_WIDTH-1:0] m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] m_wr_addr = m_wr_ptr_sync[ADDR_WIDTH-1:0];

    // Write enable
    assign s_wr_en = s_axis_tvalid && s_axis_tready;

    // Read enable
    assign m_rd_en = m_axis_tvalid && m_axis_tready;

    // Write pointer increment
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_wr_ptr <= {(ADDR_WIDTH+1){1'b0}};
        else if (s_wr_en)
            s_wr_ptr <= s_wr_ptr + 1'b1;
    end

    // Read pointer increment
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rd_ptr <= {(ADDR_WIDTH+1){1'b0}};
        else if (m_rd_en)
            m_rd_ptr <= m_rd_ptr + 1'b1;
    end

    // Synchronize write pointer to m_clk domain
    reg [ADDR_WIDTH:0] s_wr_ptr_sync1, s_wr_ptr_sync2;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_sync1 <= {(ADDR_WIDTH+1){1'b0}};
            s_wr_ptr_sync2 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            s_wr_ptr_sync1 <= s_wr_ptr;
            s_wr_ptr_sync2 <= s_wr_ptr_sync1;
        end
    end
    assign m_wr_ptr_sync = s_wr_ptr_sync2;

    // Synchronize read pointer to s_clk domain
    reg [ADDR_WIDTH:0] m_rd_ptr_sync1, m_rd_ptr_sync2;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_sync1 <= {(ADDR_WIDTH+1){1'b0}};
            m_rd_ptr_sync2 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            m_rd_ptr_sync1 <= m_rd_ptr;
            m_rd_ptr_sync2 <= m_rd_ptr_sync1;
        end
    end
    assign s_rd_ptr_sync = m_rd_ptr_sync2;

    // Calculate depth
    wire [ADDR_WIDTH:0] s_depth = s_wr_ptr - s_rd_ptr_sync;
    wire [ADDR_WIDTH:0] m_depth = m_wr_ptr_sync - m_rd_ptr;

    // Full and empty conditions
    wire s_full = (s_depth == DEPTH);
    wire m_empty = (m_depth == 0);

    // tready logic
    wire s_tready_base = !s_full;
    wire m_tvalid_base = !m_empty;

    // Handle drop/mark when full
    wire s_tready;
    wire m_tvalid;

    generate
        if (DROP_WHEN_FULL) begin
            assign s_tready = 1'b1;
        end else if (MARK_WHEN_FULL) begin
            assign s_tready = 1'b1;
        end else begin
            assign s_tready = s_tready_base;
        end
    endgenerate

    assign m_tvalid = m_tvalid_base;

    // RAM write
    always @(posedge s_clk) begin
        if (s_wr_en) begin
            ram[s_wr_addr] <= {
                (USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}}),
                (DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}}),
                (ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}}),
                (LAST_ENABLE ? s_axis_tlast : 1'b0),
                (KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}}),
                s_axis_tdata
            };
        end
    end

    // RAM read
    reg [TOTAL_DATA_WIDTH-1:0] ram_rd_data;
    always @(posedge m_clk) begin
        ram_rd_data <= ram[m_rd_addr];
    end

    // Extract fields from read data
    wire [DATA_WIDTH-1:0] rd_data = ram_rd_data[DATA_WIDTH-1:0];
    wire [KEEP_WIDTH-1:0] rd_keep = KEEP_ENABLE ? ram_rd_data[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH] : {KEEP_WIDTH{1'b0}};
    wire rd_last = LAST_ENABLE ? ram_rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)] : 1'b0;
    wire [ID_WIDTH-1:0] rd_id = ID_ENABLE ? ram_rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + ID_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)] : {ID_WIDTH{1'b0}};
    wire [DEST_WIDTH-1:0] rd_dest = DEST_ENABLE ? ram_rd_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + DEST_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)] : {DEST_WIDTH{1'b0}};
    wire [USER_WIDTH-1:0] rd_user = USER_ENABLE ? ram_rd_data[TOTAL_DATA_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0)] : {USER_WIDTH{1'b0}};

    // Output assignments
    assign m_axis_tdata = rd_data;
    assign m_axis_tkeep = rd_keep;
    assign m_axis_tlast = rd_last;
    assign m_axis_tid = rd_id;
    assign m_axis_tdest = rd_dest;
    assign m_axis_tuser = rd_user;
    assign m_axis_tvalid = m_tvalid;

    // Pause logic
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_pause_ack_reg <= 1'b0;
        else if (PAUSE_ENABLE)
            s_pause_ack_reg <= s_pause_req;
        else
            s_pause_ack_reg <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_pause_ack_reg <= 1'b0;
        else if (PAUSE_ENABLE)
            m_pause_ack_reg <= m_pause_req;
        else
            m_pause_ack_reg <= 1'b0;
    end

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_full && s_axis_tvalid;
    assign s_status_bad_frame = 1'b0;
    assign s_status_good_frame = 1'b0;

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = 1'b0;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b0;

endmodule
