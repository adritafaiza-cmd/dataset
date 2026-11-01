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

    // Internal signals
    reg [DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg                  ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   ram_tid  [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    reg [PTR_WIDTH-1:0] s_wr_ptr;
    reg [PTR_WIDTH-1:0] m_rd_ptr;

    // Gray code pointers for CDC
    wire [PTR_WIDTH-1:0] s_wr_ptr_gray;
    wire [PTR_WIDTH-1:0] m_rd_ptr_gray;

    // Synchronizers
    reg [PTR_WIDTH-1:0] m_rd_ptr_gray_sync1, m_rd_ptr_gray_sync2;
    reg [PTR_WIDTH-1:0] s_wr_ptr_gray_sync1, s_wr_ptr_gray_sync2;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_wr_ptr_sync;
    wire [PTR_WIDTH-1:0] m_rd_ptr_sync;

    // Convert gray to binary
    function [PTR_WIDTH-1:0] gray_to_bin;
        input [PTR_WIDTH-1:0] gray;
        integer i;
        begin
            gray_to_bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
                gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
        end
    endfunction

    // Binary to gray
    function [PTR_WIDTH-1:0] bin_to_gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin_to_gray = bin ^ (bin >> 1);
        end
    endfunction

    assign s_wr_ptr_gray = bin_to_gray(s_wr_ptr);
    assign m_rd_ptr_gray = bin_to_gray(m_rd_ptr);

    // Synchronizers
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_gray_sync1 <= m_rd_ptr_gray;
            m_rd_ptr_gray_sync2 <= m_rd_ptr_gray_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_gray_sync1 <= s_wr_ptr_gray;
            s_wr_ptr_gray_sync2 <= s_wr_ptr_gray_sync1;
        end
    end

    assign s_wr_ptr_sync = gray_to_bin(s_wr_ptr_gray_sync2);
    assign m_rd_ptr_sync = gray_to_bin(m_rd_ptr_gray_sync2);

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth_bin = s_wr_ptr_sync - m_rd_ptr_sync;
    wire [PTR_WIDTH-1:0] m_depth_bin = m_rd_ptr_sync - s_wr_ptr_sync;

    // Full and empty
    wire s_full = (s_depth_bin == DEPTH);
    wire m_empty = (m_depth_bin == 0);

    // Pause logic
    reg s_paused, m_paused;
    wire s_pause_active = PAUSE_ENABLE ? (s_pause_req | s_paused) : 1'b0;
    wire m_pause_active = PAUSE_ENABLE ? (m_pause_req | m_paused) : 1'b0;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_paused <= 1'b0;
        else if (s_pause_req)
            s_paused <= 1'b1;
        else if (s_pause_ack)
            s_paused <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_paused <= 1'b0;
        else if (m_pause_req)
            m_paused <= 1'b1;
        else if (m_pause_ack)
            m_paused <= 1'b0;
    end

    assign s_pause_ack = s_paused;
    assign m_pause_ack = m_paused;

    // Write enable
    wire s_write_en = s_axis_tvalid & s_axis_tready & ~s_pause_active;

    // Read enable
    wire m_read_en = m_axis_tvalid & m_axis_tready & ~m_pause_active;

    // tready logic
    wire s_can_accept = ~s_full | DROP_WHEN_FULL | MARK_WHEN_FULL;
    assign s_axis_tready = s_can_accept & ~s_pause_active;

    // Write pointer increment
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
        else if (s_write_en)
            s_wr_ptr <= s_wr_ptr + 1'b1;
    end

    // RAM write
    always @(posedge s_clk) begin
        if (s_write_en) begin
            ram_data[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            ram_keep[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
            ram_last[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
            ram_tid[s_wr_ptr[ADDR_WIDTH-1:0]]  <= s_axis_tid;
            ram_dest[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
            ram_user[s_wr_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
        end
    end

    // Read pointer increment
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
        else if (m_read_en)
            m_rd_ptr <= m_rd_ptr + 1'b1;
    end

    // RAM read
    wire [ADDR_WIDTH-1:0] m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] m_rd_data = ram_data[m_rd_addr];
    wire [KEEP_WIDTH-1:0] m_rd_keep = ram_keep[m_rd_addr];
    wire                  m_rd_last = ram_last[m_rd_addr];
    wire [ID_WIDTH-1:0]   m_rd_tid  = ram_tid[m_rd_addr];
    wire [DEST_WIDTH-1:0] m_rd_dest = ram_dest[m_rd_addr];
    wire [USER_WIDTH-1:0] m_rd_user = ram_user[m_rd_addr];

    // Output valid
    assign m_axis_tvalid = ~m_empty & ~m_pause_active;

    // Output data
    assign m_axis_tdata  = m_rd_data;
    assign m_axis_tkeep  = m_rd_keep;
    assign m_axis_tlast  = m_rd_last;
    assign m_axis_tid    = m_rd_tid;
    assign m_axis_tdest  = m_rd_dest;
    assign m_axis_tuser  = m_rd_user;

    // Status outputs
    assign s_status_depth = s_depth_bin;
    assign s_status_depth_commit = s_depth_bin;
    assign m_status_depth = m_depth_bin;
    assign m_status_depth_commit = m_depth_bin;

    // Overflow detection (simplified: when full and write attempted)
    reg s_overflow_reg, m_overflow_reg;
    wire s_overflow_pulse = s_full & s_axis_tvalid & ~s_axis_tready;
    wire m_overflow_pulse = m_empty & m_axis_tvalid & ~m_axis_tready;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_overflow_reg <= 1'b0;
        else if (s_overflow_pulse)
            s_overflow_reg <= 1'b1;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_overflow_reg <= 1'b0;
        else if (m_overflow_pulse)
            m_overflow_reg <= 1'b1;
    end

    assign s_status_overflow = s_overflow_reg;
    assign m_status_overflow = m_overflow_reg;

    // Frame status (simplified)
    reg s_bad_frame_reg, s_good_frame_reg;
    reg m_bad_frame_reg, m_good_frame_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
        end else begin
            if (s_write_en && s_axis_tlast) begin
                s_good_frame_reg <= 1'b1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bad_frame_reg <= 1'b0;
            m_good_frame_reg <= 1'b0;
        end else begin
            if (m_read_en && m_rd_last) begin
                m_good_frame_reg <= 1'b1;
            end
        end
    end

    assign s_status_bad_frame = s_bad_frame_reg;
    assign s_status_good_frame = s_good_frame_reg;
    assign m_status_bad_frame = m_bad_frame_reg;
    assign m_status_good_frame = m_good_frame_reg;

endmodule
