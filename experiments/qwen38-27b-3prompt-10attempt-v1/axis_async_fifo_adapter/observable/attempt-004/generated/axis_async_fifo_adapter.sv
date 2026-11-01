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
    localparam S_BYTES = S_DATA_WIDTH / 8;
    localparam M_BYTES = M_DATA_WIDTH / 8;
    localparam S_KEEP_W = S_KEEP_ENABLE ? S_KEEP_WIDTH : 1;
    localparam M_KEEP_W = M_KEEP_ENABLE ? M_KEEP_WIDTH : 1;
    localparam ID_W = ID_ENABLE ? ID_WIDTH : 1;
    localparam DEST_W = DEST_ENABLE ? DEST_WIDTH : 1;
    localparam USER_W = USER_ENABLE ? USER_WIDTH : 1;
    localparam USER_BAD_W = USER_ENABLE ? USER_WIDTH : 1;

    // Internal signals
    wire [S_DATA_WIDTH-1:0] s_tdata_int;
    wire [S_KEEP_W-1:0] s_tkeep_int;
    wire s_tvalid_int;
    wire s_tready_int;
    wire s_tlast_int;
    wire [ID_W-1:0] s_tid_int;
    wire [DEST_W-1:0] s_tdest_int;
    wire [USER_W-1:0] s_tuser_int;

    wire [M_DATA_WIDTH-1:0] m_tdata_int;
    wire [M_KEEP_W-1:0] m_tkeep_int;
    wire m_tvalid_int;
    wire m_tready_int;
    wire m_tlast_int;
    wire [ID_W-1:0] m_tid_int;
    wire [DEST_W-1:0] m_tdest_int;
    wire [USER_W-1:0] m_tuser_int;

    assign s_tdata_int = s_axis_tdata;
    assign s_tkeep_int = S_KEEP_ENABLE ? s_axis_tkeep : {S_KEEP_W{1'b1}};
    assign s_tvalid_int = s_axis_tvalid;
    assign s_tlast_int = s_axis_tlast;
    assign s_tid_int = ID_ENABLE ? s_axis_tid : {ID_W{1'b0}};
    assign s_tdest_int = DEST_ENABLE ? s_axis_tdest : {DEST_W{1'b0}};
    assign s_tuser_int = USER_ENABLE ? s_axis_tuser : {USER_W{1'b0}};

    assign m_tdata_int = m_axis_tdata;
    assign m_tkeep_int = M_KEEP_ENABLE ? m_axis_tkeep : {M_KEEP_W{1'b1}};
    assign m_tvalid_int = m_axis_tvalid;
    assign m_tready_int = m_axis_tready;
    assign m_tlast_int = m_axis_tlast;
    assign m_tid_int = ID_ENABLE ? m_axis_tid : {ID_W{1'b0}};
    assign m_tdest_int = DEST_ENABLE ? m_axis_tdest : {DEST_W{1'b0}};
    assign m_tuser_int = USER_ENABLE ? m_axis_tuser : {USER_W{1'b0}};

    // Pause logic
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;
    wire s_paused;
    wire m_paused;

    assign s_paused = PAUSE_ENABLE ? s_pause_req : 1'b0;
    assign m_paused = PAUSE_ENABLE ? m_pause_req : 1'b0;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_pause_ack_reg <= 1'b0;
        else if (s_pause_req)
            s_pause_ack_reg <= 1'b1;
        else
            s_pause_ack_reg <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_pause_ack_reg <= 1'b0;
        else if (m_pause_req)
            m_pause_ack_reg <= 1'b1;
        else
            m_pause_ack_reg <= 1'b0;
    end

    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;

    // FIFO pointers
    reg [PTR_WIDTH-1:0] s_wr_ptr;
    reg [PTR_WIDTH-1:0] m_rd_ptr;

    // Gray code pointers for CDC
    reg [PTR_WIDTH-1:0] s_wr_ptr_gray;
    reg [PTR_WIDTH-1:0] m_rd_ptr_gray;

    // Synchronizers
    reg [PTR_WIDTH-1:0] m_rd_ptr_gray_s1, m_rd_ptr_gray_s2;
    reg [PTR_WIDTH-1:0] s_wr_ptr_gray_m1, s_wr_ptr_gray_m2;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            m_rd_ptr_gray_s1 <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_gray_s2 <= {PTR_WIDTH{1'b0}};
        end else begin
            m_rd_ptr_gray_s1 <= m_rd_ptr_gray;
            m_rd_ptr_gray_s2 <= m_rd_ptr_gray_s1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_wr_ptr_gray_m1 <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_gray_m2 <= {PTR_WIDTH{1'b0}};
        end else begin
            s_wr_ptr_gray_m1 <= s_wr_ptr_gray;
            s_wr_ptr_gray_m2 <= s_wr_ptr_gray_m1;
        end
    end

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

    function [PTR_WIDTH-1:0] bin_to_gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin_to_gray = bin ^ (bin >> 1);
        end
    endfunction

    wire [PTR_WIDTH-1:0] m_rd_ptr_bin_s = gray_to_bin(m_rd_ptr_gray_s2);
    wire [PTR_WIDTH-1:0] s_wr_ptr_bin_m = gray_to_bin(s_wr_ptr_gray_m2);

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth = s_wr_ptr - m_rd_ptr_bin_s;
    wire [PTR_WIDTH-1:0] m_depth = s_wr_ptr_bin_m - m_rd_ptr;

    // Full/Empty
    wire s_full = (s_depth >= DEPTH);
    wire m_empty = (m_depth == 0);

    // Write enable
    wire s_write_en = s_tvalid_int && s_tready_int && !s_paused && !s_full;

    // Read enable
    wire m_read_en = m_tvalid_int && m_tready_int && !m_paused && !m_empty;

    // RAM
    reg [S_DATA_WIDTH-1:0] ram [0:DEPTH-1];
    reg [S_KEEP_W-1:0] ram_keep [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];
    reg [ID_W-1:0] ram_tid [0:DEPTH-1];
    reg [DEST_W-1:0] ram_tdest [0:DEPTH-1];
    reg [USER_W-1:0] ram_tuser [0:DEPTH-1];

    // Write address
    wire [ADDR_WIDTH-1:0] s_wr_addr = s_wr_ptr[ADDR_WIDTH-1:0];

    // Read address
    wire [ADDR_WIDTH-1:0] m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];

    // RAM read
    wire [S_DATA_WIDTH-1:0] ram_rd_data;
    wire [S_KEEP_W-1:0] ram_rd_keep;
    wire ram_rd_last;
    wire [ID_W-1:0] ram_rd_tid;
    wire [DEST_W-1:0] ram_rd_tdest;
    wire [USER_W-1:0] ram_rd_tuser;

    assign ram_rd_data = ram[m_rd_addr];
    assign ram_rd_keep = ram_keep[m_rd_addr];
    assign ram_rd_last = ram_last[m_rd_addr];
    assign ram_rd_tid = ram_tid[m_rd_addr];
    assign ram_rd_tdest = ram_tdest[m_rd_addr];
    assign ram_rd_tuser = ram_tuser[m_rd_addr];

    // Write to RAM
    always @(posedge s_clk) begin
        if (s_write_en) begin
            ram[s_wr_addr] <= s_tdata_int;
            ram_keep[s_wr_addr] <= s_tkeep_int;
            ram_last[s_wr_addr] <= s_tlast_int;
            ram_tid[s_wr_addr] <= s_tid_int;
            ram_tdest[s_wr_addr] <= s_tdest_int;
            ram_tuser[s_wr_addr] <= s_tuser_int;
        end
    end

    // Pointer updates
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= {PTR_WIDTH{1'b0}};
            s_wr_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else begin
            if (s_write_en) begin
                s_wr_ptr <= s_wr_ptr + 1'b1;
                s_wr_ptr_gray <= bin_to_gray(s_wr_ptr + 1'b1);
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= {PTR_WIDTH{1'b0}};
            m_rd_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else begin
            if (m_read_en) begin
                m_rd_ptr <= m_rd_ptr + 1'b1;
                m_rd_ptr_gray <= bin_to_gray(m_rd_ptr + 1'b1);
            end
        end
    end

    // Width adaptation: S_DATA_WIDTH to M_DATA_WIDTH
    // For simplicity, assume S_DATA_WIDTH == M_DATA_WIDTH or handle byte-wise
    // Here we implement a simple pass-through with keep adaptation

    reg [M_DATA_WIDTH-1:0] m_tdata_reg;
    reg [M_KEEP_W-1:0] m_tkeep_reg;
    reg m_tlast_reg;
    reg [ID_W-1:0] m_tid_reg;
    reg [DEST_W-1:0] m_tdest_reg;
    reg [USER_W-1:0] m_tuser_reg;
    reg m_tvalid_reg;

    // Simple width adapter: if widths match, direct pass
    // If different, we need to accumulate bytes. For now, assume same width.
    // In a real implementation, you'd need a byte accumulator.

    wire [M_DATA_WIDTH-1:0] adapted_data;
    wire [M_KEEP_W-1:0] adapted_keep;
    wire adapted_last;
    wire [ID_W-1:0] adapted_tid;
    wire [DEST_W-1:0] adapted_tdest;
    wire [USER_W-1:0] adapted_tuser;

    // For same width case
    assign adapted_data = ram_rd_data[M_DATA_WIDTH-1:0];
    assign adapted_keep = M_KEEP_ENABLE ? ram_rd_keep[M_KEEP_W-1:0] : {M_KEEP_W{1'b1}};
    assign adapted_last = ram_rd_last;
    assign adapted_tid = ram_rd_tid;
    assign adapted_tdest = ram_rd_tdest;
    assign adapted_tuser = ram_rd_tuser;

    // Output register
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_tdata_reg <= {M_DATA_WIDTH{1'b0}};
            m_tkeep_reg <= {M_KEEP_W{1'b0}};
            m_tlast_reg <= 1'b0;
            m_tid_reg <= {ID_W{1'b0}};
            m_tdest_reg <= {DEST_W{1'b0}};
            m_tuser_reg <= {USER_W{1'b0}};
            m_tvalid_reg <= 1'b0;
        end else begin
            if (m_read_en) begin
                m_tdata_reg <= adapted_data;
                m_tkeep_reg <= adapted_keep;
                m_tlast_reg <= adapted_last;
                m_tid_reg <= adapted_tid;
                m_tdest_reg <= adapted_tdest;
                m_tuser_reg <= adapted_tuser;
                m_tvalid_reg <= 1'b1;
            end else if (m_tvalid_reg && m_tready_int) begin
                m_tvalid_reg <= 1'b0;
            end
        end
    end

    assign m_axis_tdata = m_tdata_reg;
    assign m_axis_tkeep = m_tkeep_reg;
    assign m_axis_tvalid = m_tvalid_reg;
    assign m_axis_tlast = m_tlast_reg;
    assign m_axis_tid = m_tid_reg;
    assign m_axis_tdest = m_tdest_reg;
    assign m_axis_tuser = m_tuser_reg;

    // Ready signals
    assign s_axis_tready = !s_full && !s_paused;
    assign m_axis_tready = !m_empty && !m_paused;

    // Status
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = 1'b0;
    assign s_status_bad_frame = 1'b0;
    assign s_status_good_frame = 1'b0;

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = 1'b0;
    assign m_status_bad_frame = 1'b0;
    assign m_status_good_frame = 1'b0;

endmodule
