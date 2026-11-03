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

    // Internal signals
    reg [ADDR_WIDTH-1:0] s_wr_addr, s_rd_addr;
    reg [ADDR_WIDTH-1:0] m_wr_addr, m_rd_addr;
    reg [ADDR_WIDTH-1:0] s_gray_wr, s_gray_rd;
    reg [ADDR_WIDTH-1:0] m_gray_wr, m_gray_rd;
    reg                  s_full, s_empty;
    reg                  m_full, m_empty;
    reg [$clog2(DEPTH):0] s_depth, m_depth;
    reg [$clog2(DEPTH):0] s_depth_commit, m_depth_commit;
    reg                  s_status_overflow_reg, s_status_bad_frame_reg, s_status_good_frame_reg;
    reg                  m_status_overflow_reg, m_status_bad_frame_reg, m_status_good_frame_reg;
    reg                  s_pause_ack_reg, m_pause_ack_reg;
    reg                  s_axis_tready_reg, m_axis_tvalid_reg;

    // Gray counter instances
    gray_counter #(.WIDTH(ADDR_WIDTH)) s_gray_counter (
        .clk(s_clk),
        .rst(s_rst),
        .binary_in(s_wr_addr),
        .gray_out(s_gray_wr)
    );

    gray_counter #(.WIDTH(ADDR_WIDTH)) m_gray_counter (
        .clk(m_clk),
        .rst(m_rst),
        .binary_in(m_wr_addr),
        .gray_out(m_gray_wr)
    );

    // Sync counter instances
    sync_counter #(.WIDTH(ADDR_WIDTH+1)) s_depth_sync (
        .clk_src(s_clk),
        .rst_src(s_rst),
        .data_src(s_depth_commit),
        .clk_dst(m_clk),
        .rst_dst(m_rst),
        .data_dst(m_depth)
    );

    sync_counter #(.WIDTH(ADDR_WIDTH+1)) m_depth_sync (
        .clk_src(m_clk),
        .rst_src(m_rst),
        .data_src(m_depth_commit),
        .clk_dst(s_clk),
        .rst_dst(s_rst),
        .data_dst(s_depth)
    );

    // FIFO RAM instance
    fifo_ram #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH + KEEP_WIDTH + LAST_ENABLE + ID_ENABLE*ID_WIDTH + DEST_ENABLE*DEST_WIDTH + USER_ENABLE*USER_WIDTH)
    ) fifo_memory (
        .wr_clk(s_clk),
        .wr_rst(s_rst),
        .wr_addr(s_gray_wr),
        .wr_en(s_axis_tvalid & s_axis_tready_reg),
        .din({s_axis_tdata, s_axis_tkeep, s_axis_tlast, s_axis_tid, s_axis_tdest, s_axis_tuser}),
        .rd_clk(m_clk),
        .rd_rst(m_rst),
        .rd_addr(m_gray_rd),
        .rd_en(m_axis_tvalid_reg & m_axis_tready),
        .dout({m_axis_tdata, m_axis_tkeep, m_axis_tlast, m_axis_tid, m_axis_tdest, m_axis_tuser})
    );

    // Write address and full/empty flags
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_addr <= 0;
            s_full <= 0;
            s_empty <= 1;
        end else begin
            if (s_axis_tvalid & s_axis_tready_reg & !s_full) begin
                s_wr_addr <= s_wr_addr + 1;
            end
            if (s_wr_addr == m_gray_rd) begin
                s_full <= 1;
            end else if (s_wr_addr != m_gray_rd + 1) begin
                s_full <= 0;
            end
            if (s_wr_addr == s_gray_rd + 1) begin
                s_empty <= 1;
            end else if (s_wr_addr != s_gray_rd) begin
                s_empty <= 0;
            end
        end
    end

    // Read address and full/empty flags
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_addr <= 0;
            m_full <= 0;
            m_empty <= 1;
        end else begin
            if (m_axis_tvalid_reg & m_axis_tready & !m_empty) begin
                m_rd_addr <= m_rd_addr + 1;
            end
            if (m_rd_addr == s_gray_wr) begin
                m_full <= 1;
            end else if (m_rd_addr != s_gray_wr + 1) begin
                m_full <= 0;
            end
            if (m_rd_addr == m_gray_wr + 1) begin
                m_empty <= 1;
            end else if (m_rd_addr != m_gray_wr) begin
                m_empty <= 0;
            end
        end
    end

    // Depth calculation
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_depth <= 0;
            s_depth_commit <= 0;
        end else begin
            if (s_axis_tvalid & s_axis_tready_reg & !s_full) begin
                s_depth <= s_depth + 1;
            end
            if (m_axis_tvalid_reg & m_axis_tready & !m_empty) begin
                s_depth <= s_depth - 1;
            end
            s_depth_commit <= s_depth;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_depth_commit <= 0;
        end else begin
            m_depth_commit <= m_depth;
        end
    end

    // Status flags
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_overflow_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
        end else begin
            if (s_full & s_axis_tvalid & s_axis_tready_reg) begin
                s_status_overflow_reg <= 1;
            end else begin
                s_status_overflow_reg <= 0;
            end
            // Frame status handling is simplified as the specification does not provide specific frame logic
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_overflow_reg <= 0;
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
        end else begin
            if (m_full & m_axis_tvalid_reg & m_axis_tready) begin
                m_status_overflow_reg <= 1;
            end else begin
                m_status_overflow_reg <= 0;
            end
            // Frame status handling is simplified as the specification does not provide specific frame logic
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
        end
    end

    // Pause handling
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack_reg <= 0;
        end else begin
            s_pause_ack_reg <= s_pause_req;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack_reg <= 0;
        end else begin
            m_pause_ack_reg <= m_pause_req;
        end
    end

    // AXI ready and valid signals
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tready_reg <= 0;
        end else begin
            s_axis_tready_reg <= !s_full;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tvalid_reg <= 0;
        end else begin
            m_axis_tvalid_reg <= !m_empty;
        end
    end

    // Assign outputs
    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth_commit;
    assign s_status_overflow = s_status_overflow_reg;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;
    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth_commit;
    assign m_status_overflow = m_status_overflow_reg;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

endmodule

module gray_counter #(
    parameter WIDTH = 4
)
(
    input  wire clk,
    input  wire rst,
    input  wire [WIDTH-1:0] binary_in,
    output reg [WIDTH-1:0] gray_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            gray_out <= 0;
        end else begin
            gray_out <= binary_in ^ (binary_in >> 1);
        end
    end

endmodule

module sync_counter #(
    parameter WIDTH = 4
)
(
    input  wire clk_src,
    input  wire rst_src,
    input  wire [WIDTH-1:0] data_src,
    input  wire clk_dst,
    input  wire rst_dst,
    output reg [WIDTH-1:0] data_dst
);

    reg [WIDTH-1:0] sync_reg [1:0];

    always @(posedge clk_src or posedge rst_src) begin
        if (rst_src) begin
            sync_reg[0] <= 0;
            sync_reg[1] <= 0;
        end else begin
            sync_reg[0] <= data_src;
            sync_reg[1] <= sync_reg[0];
        end
    end

    always @(posedge clk_dst or posedge rst_dst) begin
        if (rst_dst) begin
            data_dst <= 0;
        end else begin
            data_dst <= sync_reg[1];
        end
    end

endmodule

module fifo_ram #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 32
)
(
    input  wire wr_clk,
    input  wire wr_rst,
    input  wire [ADDR_WIDTH-1:0] wr_addr,
    input  wire wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    input  wire rd_clk,
    input  wire rd_rst,
    input  wire [ADDR_WIDTH-1:0] rd_addr,
    input  wire rd_en,
    output wire [DATA_WIDTH-1:0] dout
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            mem <= '{default: 0};
        end else if (wr_en) begin
            mem[wr_addr] <= din;
        end
    end

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            dout <= 0;
        end else if (rd_en) begin
            dout <= mem[rd_addr];
        end
    end

endmodule
