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
    localparam DEPTH_POW2 = (DEPTH == 1) ? 1 : (1 << ADDR_WIDTH);
    localparam DEPTH_MASK = DEPTH_POW2 - 1;
    localparam DEPTH_LIMIT = DEPTH - 1;
    localparam DEPTH_WIDTH = $clog2(DEPTH) + 1;
    localparam DEPTH_MAX = (1 << DEPTH_WIDTH) - 1;

    // Total width of the data bus stored in RAM
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + 
                                  (KEEP_ENABLE ? KEEP_WIDTH : 0) +
                                  (LAST_ENABLE ? 1 : 0) +
                                  (ID_ENABLE ? ID_WIDTH : 0) +
                                  (DEST_ENABLE ? DEST_WIDTH : 0) +
                                  (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    wire [ADDR_WIDTH:0] s_wr_ptr;
    wire [ADDR_WIDTH:0] s_rd_ptr;
    wire [ADDR_WIDTH:0] m_wr_ptr;
    wire [ADDR_WIDTH:0] m_rd_ptr;

    // CDC synchronizers for write pointer (to m domain)
    reg [ADDR_WIDTH:0] m_wr_ptr_sync_1;
    reg [ADDR_WIDTH:0] m_wr_ptr_sync_2;
    reg [ADDR_WIDTH:0] m_wr_ptr_sync_3;

    // CDC synchronizers for read pointer (to s domain)
    reg [ADDR_WIDTH:0] s_rd_ptr_sync_1;
    reg [ADDR_WIDTH:0] s_rd_ptr_sync_2;
    reg [ADDR_WIDTH:0] s_rd_ptr_sync_3;

    // RAM
    reg [TOTAL_DATA_WIDTH-1:0] ram [0:DEPTH_POW2-1];

    // Write address
    wire [ADDR_WIDTH-1:0] s_wr_addr = s_wr_ptr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];

    // Write enable
    wire s_wr_en = s_axis_tvalid & s_axis_tready;

    // Read enable
    wire m_rd_en = m_axis_tvalid & m_axis_tready;

    // RAM read data
    wire [TOTAL_DATA_WIDTH-1:0] ram_rd_data;
    wire [TOTAL_DATA_WIDTH-1:0] ram_rd_data_reg;

    // RAM read
    always @(posedge m_clk) begin
        ram_rd_data_reg <= ram[m_rd_addr];
    end

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

    // Synchronize write pointer to m domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wr_ptr_sync_1 <= {(ADDR_WIDTH+1){1'b0}};
            m_wr_ptr_sync_2 <= {(ADDR_WIDTH+1){1'b0}};
            m_wr_ptr_sync_3 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            m_wr_ptr_sync_1 <= s_wr_ptr;
            m_wr_ptr_sync_2 <= m_wr_ptr_sync_1;
            m_wr_ptr_sync_3 <= m_wr_ptr_sync_2;
        end
    end

    // Synchronize read pointer to s domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rd_ptr_sync_1 <= {(ADDR_WIDTH+1){1'b0}};
            s_rd_ptr_sync_2 <= {(ADDR_WIDTH+1){1'b0}};
            s_rd_ptr_sync_3 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            s_rd_ptr_sync_1 <= m_rd_ptr;
            s_rd_ptr_sync_2 <= s_rd_ptr_sync_1;
            s_rd_ptr_sync_3 <= s_rd_ptr_sync_2;
        end
    end

    // Depth calculation
    wire [ADDR_WIDTH:0] s_wr_ptr_m = m_wr_ptr_sync_3;
    wire [ADDR_WIDTH:0] m_rd_ptr_s = s_rd_ptr_sync_3;

    // Signed difference for depth
    wire [ADDR_WIDTH:0] s_depth_diff = s_wr_ptr - m_rd_ptr_s;
    wire [ADDR_WIDTH:0] m_depth_diff = s_wr_ptr_m - m_rd_ptr;

    // Depth with limit
    wire [DEPTH_WIDTH-1:0] s_depth_raw = s_depth_diff[DEPTH_WIDTH-1:0];
    wire [DEPTH_WIDTH-1:0] m_depth_raw = m_depth_diff[DEPTH_WIDTH-1:0];

    // Clamp depth to DEPTH
    wire [DEPTH_WIDTH-1:0] s_depth = (s_depth_raw > DEPTH_LIMIT) ? DEPTH_LIMIT : s_depth_raw;
    wire [DEPTH_WIDTH-1:0] m_depth = (m_depth_raw > DEPTH_LIMIT) ? DEPTH_LIMIT : m_depth_raw;

    // Full and empty
    wire s_full = (s_depth == DEPTH_LIMIT);
    wire m_empty = (m_depth == 0);

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

    // Effective ready/valid considering pause
    wire s_tready_eff = s_axis_tready & ~(PAUSE_ENABLE & s_pause_req);
    wire m_tvalid_eff = m_axis_tvalid & ~(PAUSE_ENABLE & m_pause_req);

    // Overflow detection
    reg s_overflow_reg;
    reg m_overflow_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_overflow_reg <= 1'b0;
        else if (s_axis_tvalid & s_full & ~DROP_WHEN_FULL & ~MARK_WHEN_FULL)
            s_overflow_reg <= 1'b1;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_overflow_reg <= 1'b0;
        else if (m_axis_tvalid & m_empty)
            m_overflow_reg <= 1'b0;
    end

    // Frame tracking
    reg s_in_frame;
    reg m_in_frame;
    reg s_bad_frame_reg;
    reg m_bad_frame_reg;
    reg s_good_frame_reg;
    reg m_good_frame_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_in_frame <= 1'b0;
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
        end else begin
            if (s_wr_en) begin
                if (LAST_ENABLE && s_axis_tlast) begin
                    s_in_frame <= 1'b0;
                    if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                        s_bad_frame_reg <= 1'b1;
                    else
                        s_good_frame_reg <= 1'b1;
                end else begin
                    s_in_frame <= 1'b1;
                end
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_in_frame <= 1'b0;
            m_bad_frame_reg <= 1'b0;
            m_good_frame_reg <= 1'b0;
        end else begin
            if (m_rd_en) begin
                if (LAST_ENABLE && m_axis_tlast) begin
                    m_in_frame <= 1'b0;
                    if (USER_ENABLE && (m_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                        m_bad_frame_reg <= 1'b1;
                    else
                        m_good_frame_reg <= 1'b1;
                end else begin
                    m_in_frame <= 1'b1;
                end
            end
        end
    end

    // Output assignments
    assign s_axis_tready = (DROP_WHEN_FULL || MARK_WHEN_FULL) ? 1'b1 : ~s_full;
    assign m_axis_tdata = ram_rd_data_reg[DATA_WIDTH-1:0];
    assign m_axis_tkeep = KEEP_ENABLE ? ram_rd_data_reg[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH] : {KEEP_WIDTH{1'b0}};
    assign m_axis_tlast = LAST_ENABLE ? ram_rd_data_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? ram_rd_data_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + ID_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? ram_rd_data_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + DEST_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? ram_rd_data_reg[TOTAL_DATA_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0)] : {USER_WIDTH{1'b0}};
    assign m_axis_tvalid = ~m_empty;
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_overflow_reg;
    assign s_status_bad_frame = s_bad_frame_reg;
    assign s_status_good_frame = s_good_frame_reg;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = m_overflow_reg;
    assign m_status_bad_frame = m_bad_frame_reg;
    assign m_status_good_frame = m_good_frame_reg;

endmodule
