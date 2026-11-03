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

    // Internal signals
    wire [$clog2(DEPTH):0] s_wr_ptr, s_wr_ptr_gray, m_wr_ptr_gray_sync, s_wr_ptr_gray_sync;
    wire [$clog2(DEPTH):0] m_rd_ptr, m_rd_ptr_gray, s_rd_ptr_gray_sync, m_rd_ptr_gray_sync;
    wire [S_DATA_WIDTH-1:0] s_axis_tdata_reg, m_axis_tdata_reg;
    wire [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg, m_axis_tkeep_reg;
    wire [USER_WIDTH-1:0] s_axis_tuser_reg, m_axis_tuser_reg;
    wire s_axis_tlast_reg, m_axis_tlast_reg;
    wire s_axis_tid_reg, m_axis_tid_reg;
    wire s_axis_tdest_reg, m_axis_tdest_reg;
    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;
    reg [USER_WIDTH-1:0] s_status_bad_frame_reg, s_status_good_frame_reg;
    reg [USER_WIDTH-1:0] m_status_bad_frame_reg, m_status_good_frame_reg;

    // FIFO depth calculation
    wire [$clog2(DEPTH):0] s_fifo_depth, m_fifo_depth;
    assign s_fifo_depth = s_wr_ptr_gray_sync - m_rd_ptr_gray;
    assign m_fifo_depth = m_wr_ptr_gray_sync - s_rd_ptr_gray;

    // Status signals
    assign s_status_depth = s_fifo_depth;
    assign s_status_depth_commit = s_wr_ptr_gray_sync - s_rd_ptr_gray_sync;
    assign s_status_overflow = (s_fifo_depth >= DEPTH);
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;

    assign m_status_depth = m_fifo_depth;
    assign m_status_depth_commit = m_wr_ptr_gray_sync - m_rd_ptr_gray_sync;
    assign m_status_overflow = (m_fifo_depth >= DEPTH);
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

    // Pause signals
    assign s_pause_ack = s_pause_req;
    assign m_pause_ack = m_pause_req;

    // Slave side FIFO
    circular_buffer #(
        .WIDTH(S_DATA_WIDTH),
        .DEPTH(DEPTH)
    ) s_cb (
        .clk(s_clk),
        .rst(s_rst),
        .wr_ptr(s_wr_ptr),
        .rd_ptr(m_rd_ptr_gray_sync),
        .data_in(s_axis_tdata_reg),
        .data_out(m_axis_tdata_reg)
    );

    circular_buffer #(
        .WIDTH(S_KEEP_WIDTH),
        .DEPTH(DEPTH)
    ) s_cb_keep (
        .clk(s_clk),
        .rst(s_rst),
        .wr_ptr(s_wr_ptr),
        .rd_ptr(m_rd_ptr_gray_sync),
        .data_in(s_axis_tkeep_reg),
        .data_out(m_axis_tkeep_reg)
    );

    circular_buffer #(
        .WIDTH(USER_WIDTH),
        .DEPTH(DEPTH)
    ) s_cb_user (
        .clk(s_clk),
        .rst(s_rst),
        .wr_ptr(s_wr_ptr),
        .rd_ptr(m_rd_ptr_gray_sync),
        .data_in(s_axis_tuser_reg),
        .data_out(m_axis_tuser_reg)
    );

    circular_buffer #(
        .WIDTH(1),
        .DEPTH(DEPTH)
    ) s_cb_last (
        .clk(s_clk),
        .rst(s_rst),
        .wr_ptr(s_wr_ptr),
        .rd_ptr(m_rd_ptr_gray_sync),
        .data_in(s_axis_tlast_reg),
        .data_out(m_axis_tlast_reg)
    );

    circular_buffer #(
        .WIDTH(ID_WIDTH),
        .DEPTH(DEPTH)
    ) s_cb_tid (
        .clk(s_clk),
        .rst(s_rst),
        .wr_ptr(s_wr_ptr),
        .rd_ptr(m_rd_ptr_gray_sync),
        .data_in(s_axis_tid_reg),
        .data_out(m_axis_tid_reg)
    );

    circular_buffer #(
        .WIDTH(DEST_WIDTH),
        .DEPTH(DEPTH)
    ) s_cb_tdest (
        .clk(s_clk),
        .rst(s_rst),
        .wr_ptr(s_wr_ptr),
        .rd_ptr(m_rd_ptr_gray_sync),
        .data_in(s_axis_tdest_reg),
        .data_out(m_axis_tdest_reg)
    );

    // Master side FIFO
    circular_buffer #(
        .WIDTH(M_DATA_WIDTH),
        .DEPTH(DEPTH)
    ) m_cb (
        .clk(m_clk),
        .rst(m_rst),
        .wr_ptr(m_wr_ptr),
        .rd_ptr(s_rd_ptr_gray_sync),
        .data_in(m_axis_tdata_reg),
        .data_out(m_axis_tdata)
    );

    circular_buffer #(
        .WIDTH(M_KEEP_WIDTH),
        .DEPTH(DEPTH)
    ) m_cb_keep (
        .clk(m_clk),
        .rst(m_rst),
        .wr_ptr(m_wr_ptr),
        .rd_ptr(s_rd_ptr_gray_sync),
        .data_in(m_axis_tkeep_reg),
        .data_out(m_axis_tkeep)
    );

    circular_buffer #(
        .WIDTH(USER_WIDTH),
        .DEPTH(DEPTH)
    ) m_cb_user (
        .clk(m_clk),
        .rst(m_rst),
        .wr_ptr(m_wr_ptr),
        .rd_ptr(s_rd_ptr_gray_sync),
        .data_in(m_axis_tuser_reg),
        .data_out(m_axis_tuser)
    );

    circular_buffer #(
        .WIDTH(1),
        .DEPTH(DEPTH)
    ) m_cb_last (
        .clk(m_clk),
        .rst(m_rst),
        .wr_ptr(m_wr_ptr),
        .rd_ptr(s_rd_ptr_gray_sync),
        .data_in(m_axis_tlast_reg),
        .data_out(m_axis_tlast)
    );

    circular_buffer #(
        .WIDTH(ID_WIDTH),
        .DEPTH(DEPTH)
    ) m_cb_tid (
        .clk(m_clk),
        .rst(m_rst),
        .wr_ptr(m_wr_ptr),
        .rd_ptr(s_rd_ptr_gray_sync),
        .data_in(m_axis_tid_reg),
        .data_out(m_axis_tid)
    );

    circular_buffer #(
        .WIDTH(DEST_WIDTH),
        .DEPTH(DEPTH)
    ) m_cb_tdest (
        .clk(m_clk),
        .rst(m_rst),
        .wr_ptr(m_wr_ptr),
        .rd_ptr(s_rd_ptr_gray_sync),
        .data_in(m_axis_tdest_reg),
        .data_out(m_axis_tdest)
    );

    // Gray code conversion for pointers
    gray_counter #(
        .WIDTH($clog2(DEPTH)+1)
    ) s_gray_counter (
        .clk(s_clk),
        .rst(s_rst),
        .binary(s_wr_ptr),
        .gray(s_wr_ptr_gray)
    );

    gray_counter #(
        .WIDTH($clog2(DEPTH)+1)
    ) m_gray_counter (
        .clk(m_clk),
        .rst(m_rst),
        .binary(m_wr_ptr),
        .gray(m_wr_ptr_gray)
    );

    // Cross-domain synchronization
    cross_domain_sync #(
        .WIDTH($clog2(DEPTH)+1)
    ) rd_ptr_sync (
        .clk_src(s_clk),
        .rst_src(s_rst),
        .data_src(s_rd_ptr_gray),
        .clk_dst(m_clk),
        .rst_dst(m_rst),
        .data_dst(m_rd_ptr_gray_sync)
    );

    cross_domain_sync #(
        .WIDTH($clog2(DEPTH)+1)
    ) wr_ptr_sync (
        .clk_src(m_clk),
        .rst_src(m_rst),
        .data_src(m_wr_ptr_gray),
        .clk_dst(s_clk),
        .rst_dst(s_rst),
        .data_dst(s_wr_ptr_gray_sync)
    );

    // Write pointer logic
    reg [$clog2(DEPTH):0] s_wr_ptr_next;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
        end else if (s_axis_tready_reg && s_axis_tvalid) begin
            s_wr_ptr <= s_wr_ptr_next;
        end
    end

    always @(*) begin
        s_wr_ptr_next = s_wr_ptr + 1;
    end

    // Read pointer logic
    reg [$clog2(DEPTH):0] m_rd_ptr_next;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
        end else if (m_axis_tready && m_axis_tvalid_reg) begin
            m_rd_ptr <= m_rd_ptr_next;
        end
    end

    always @(*) begin
        m_rd_ptr_next = m_rd_ptr + 1;
    end

    // AXI-Stream sideband signals
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_axis_tready_reg <= 0;
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
            s_status_bad_frame_reg <= 0;
            s_status_good_frame_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready_reg) begin
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
                s_axis_tlast_reg <= s_axis_tlast;
                s_axis_tid_reg <= s_axis_tid;
                s_axis_tdest_reg <= s_axis_tdest;
                s_axis_tuser_reg <= s_axis_tuser;
                if (s_axis_tlast) begin
                    s_status_good_frame_reg <= 1;
                    s_status_bad_frame_reg <= (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
                end
            end
            s_axis_tready_reg <= (s_fifo_depth < DEPTH) && !s_pause_req;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tvalid_reg <= 0;
            m_status_bad_frame_reg <= 0;
            m_status_good_frame_reg <= 0;
        end else begin
            if (m_axis_tready && m_axis_tvalid_reg) begin
                m_axis_tvalid_reg <= 0;
                if (m_axis_tlast_reg) begin
                    m_status_good_frame_reg <= 1;
                    m_status_bad_frame_reg <= (m_axis_tuser_reg & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
                end
            end else if (m_fifo_depth > 0) begin
                m_axis_tvalid_reg <= 1;
            end
        end
    end

    // Assign AXI-Stream outputs
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

    // Assign AXI-Stream inputs
    assign s_axis_tready = s_axis_tready_reg;

endmodule

module circular_buffer #
(
    parameter WIDTH = 8,
    parameter DEPTH = 4096
)
(
    input  wire clk,
    input  wire rst,
    input  wire [$clog2(DEPTH):0] wr_ptr,
    input  wire [$clog2(DEPTH):0] rd_ptr,
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [WIDTH-1:0] data_out_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out_reg <= 0;
        end else begin
            data_out_reg <= mem[rd_ptr];
        end
    end

    always @(posedge clk) begin
        if (wr_ptr != rd_ptr) begin
            mem[wr_ptr] <= data_in;
        end
    end

    assign data_out = data_out_reg;

endmodule

module gray_counter #
(
    parameter WIDTH = 4
)
(
    input  wire clk,
    input  wire rst,
    input  wire [WIDTH-1:0] binary,
    output wire [WIDTH-1:0] gray
);

    reg [WIDTH-1:0] gray_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            gray_reg <= 0;
        end else begin
            gray_reg <= {binary[WIDTH-1], binary[WIDTH-1:1] ^ binary[WIDTH-2:0]};
        end
    end

    assign gray = gray_reg;

endmodule

module cross_domain_sync #
(
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

    reg [WIDTH-1:0] data_sync;

    always @(posedge clk_src or posedge rst_src) begin
        if (rst_src) begin
            data_sync <= 0;
        end else begin
            data_sync <= data_src;
        end
    end

    always @(posedge clk_dst or posedge rst_dst) begin
        if (rst_dst) begin
            data_dst <= 0;
        end else begin
            data_dst <= data_sync;
        end
    end

endmodule
