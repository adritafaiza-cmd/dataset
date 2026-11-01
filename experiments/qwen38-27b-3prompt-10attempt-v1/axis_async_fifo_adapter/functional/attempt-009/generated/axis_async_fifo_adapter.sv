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

    // Pause logic
    reg s_pause_active;
    reg m_pause_active;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_pause_active <= 1'b0;
        else if (PAUSE_ENABLE)
            s_pause_active <= s_pause_req;
        else
            s_pause_active <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_pause_active <= 1'b0;
        else if (PAUSE_ENABLE)
            m_pause_active <= m_pause_req;
        else
            m_pause_active <= 1'b0;
    end

    assign s_pause_ack = s_pause_active;
    assign m_pause_ack = m_pause_active;

    // Write enable logic
    wire s_can_write = s_axis_tvalid && !s_full && !s_pause_active;
    assign s_wr_en = s_can_write;
    assign s_axis_tready = !s_full && !s_pause_active;

    // Data to write
    assign s_wr_data = s_axis_tdata;
    assign s_wr_keep = s_axis_tkeep;
    assign s_wr_last = s_axis_tlast;
    assign s_wr_id = s_axis_tid;
    assign s_wr_dest = s_axis_tdest;
    assign s_wr_user = s_axis_tuser;

    // Read enable logic
    wire m_can_read = m_axis_tready && !m_empty && !m_pause_active;
    assign m_rd_en = m_can_read;

    // Output data
    assign m_axis_tdata = m_rd_data;
    assign m_axis_tkeep = m_rd_keep;
    assign m_axis_tlast = m_rd_last;
    assign m_axis_tid = m_rd_id;
    assign m_axis_tdest = m_rd_dest;
    assign m_axis_tuser = m_rd_user;
    assign m_axis_tvalid = !m_empty && !m_pause_active;

    // Status signals
    wire [$clog2(DEPTH):0] s_depth;
    wire [$clog2(DEPTH):0] m_depth;
    wire [$clog2(DEPTH):0] s_depth_commit;
    wire [$clog2(DEPTH):0] m_depth_commit;

    assign s_status_depth = s_depth;
    assign m_status_depth = m_depth;
    assign s_status_depth_commit = s_depth_commit;
    assign m_status_depth_commit = m_depth_commit;

    // Overflow and frame status
    reg s_overflow;
    reg m_overflow;
    reg s_bad_frame;
    reg m_bad_frame;
    reg s_good_frame;
    reg m_good_frame;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow <= 1'b0;
            s_bad_frame <= 1'b0;
            s_good_frame <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_full)
                s_overflow <= 1'b1;
            if (s_axis_tvalid && s_axis_tlast) begin
                if (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                    s_bad_frame <= 1'b1;
                else
                    s_good_frame <= 1'b1;
            end
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_overflow <= 1'b0;
            m_bad_frame <= 1'b0;
            m_good_frame <= 1'b0;
        end else begin
            if (m_axis_tready && m_empty)
                m_overflow <= 1'b0; // No overflow on read
            if (m_axis_tready && m_axis_tlast) begin
                if (USER_ENABLE && (m_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE)
                    m_bad_frame <= 1'b1;
                else
                    m_good_frame <= 1'b1;
            end
        end
    end

    assign s_status_overflow = s_overflow;
    assign m_status_overflow = m_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign m_status_bad_frame = m_bad_frame;
    assign s_status_good_frame = s_good_frame;
    assign m_status_good_frame = m_good_frame;

    // Async FIFO core
    async_fifo_core #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(S_DATA_WIDTH),
        .KEEP_WIDTH(S_KEEP_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .RAM_PIPELINE(RAM_PIPELINE)
    ) u_fifo (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_wr_en(s_wr_en),
        .s_wr_data(s_wr_data),
        .s_wr_keep(s_wr_keep),
        .s_wr_last(s_wr_last),
        .s_wr_id(s_wr_id),
        .s_wr_dest(s_wr_dest),
        .s_wr_user(s_wr_user),
        .s_full(s_full),
        .s_depth(s_depth),
        .s_depth_commit(s_depth_commit),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_rd_en(m_rd_en),
        .m_rd_data(m_rd_data),
        .m_rd_keep(m_rd_keep),
        .m_rd_last(m_rd_last),
        .m_rd_id(m_rd_id),
        .m_rd_dest(m_rd_dest),
        .m_rd_user(m_rd_user),
        .m_empty(m_empty),
        .m_depth(m_depth),
        .m_depth_commit(m_depth_commit)
    );

endmodule

module async_fifo_core #(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = 1,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter USER_WIDTH = 1,
    parameter RAM_PIPELINE = 1
) (
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire                     s_wr_en,
    input  wire [DATA_WIDTH-1:0]    s_wr_data,
    input  wire [KEEP_WIDTH-1:0]    s_wr_keep,
    input  wire                     s_wr_last,
    input  wire [ID_WIDTH-1:0]      s_wr_id,
    input  wire [DEST_WIDTH-1:0]    s_wr_dest,
    input  wire [USER_WIDTH-1:0]    s_wr_user,
    output wire                     s_full,
    output wire [$clog2(DEPTH):0]   s_depth,
    output wire [$clog2(DEPTH):0]   s_depth_commit,
    input  wire                     m_clk,
    input  wire                     m_rst,
    input  wire                     m_rd_en,
    output wire [DATA_WIDTH-1:0]    m_rd_data,
    output wire [KEEP_WIDTH-1:0]    m_rd_keep,
    output wire                     m_rd_last,
    output wire [ID_WIDTH-1:0]      m_rd_id,
    output wire [DEST_WIDTH-1:0]    m_rd_dest,
    output wire [USER_WIDTH-1:0]    m_rd_user,
    output wire                     m_empty,
    output wire [$clog2(DEPTH):0]   m_depth,
    output wire [$clog2(DEPTH):0]   m_depth_commit
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH_MASK = DEPTH - 1;

    // Write pointer
    reg [PTR_WIDTH-1:0] wr_ptr;
    wire [ADDR_WIDTH-1:0] wr_addr = wr_ptr[ADDR_WIDTH-1:0];

    // Read pointer
    reg [PTR_WIDTH-1:0] rd_ptr;
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];

    // RAM storage
    reg [DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg                  ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]   ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    // Write logic
    always @(posedge s_clk) begin
        if (s_wr_en) begin
            ram_data[wr_addr] <= s_wr_data;
            ram_keep[wr_addr] <= s_wr_keep;
            ram_last[wr_addr] <= s_wr_last;
            ram_id[wr_addr] <= s_wr_id;
            ram_dest[wr_addr] <= s_wr_dest;
            ram_user[wr_addr] <= s_wr_user;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // Read logic
    always @(posedge m_clk) begin
        if (m_rd_en) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Output data
    assign m_rd_data = ram_data[rd_addr];
    assign m_rd_keep = ram_keep[rd_addr];
    assign m_rd_last = ram_last[rd_addr];
    assign m_rd_id = ram_id[rd_addr];
    assign m_rd_dest = ram_dest[rd_addr];
    assign m_rd_user = ram_user[rd_addr];

    // Pointer synchronization
    reg [PTR_WIDTH-1:0] wr_ptr_sync1, wr_ptr_sync2;
    reg [PTR_WIDTH-1:0] rd_ptr_sync1, rd_ptr_sync2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            wr_ptr_sync1 <= wr_ptr;
            wr_ptr_sync2 <= wr_ptr_sync1;
        end
    end

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            rd_ptr_sync1 <= rd_ptr;
            rd_ptr_sync2 <= rd_ptr_sync1;
        end
    end

    // Full and empty detection
    wire [PTR_WIDTH-1:0] wr_ptr_m = wr_ptr_sync2;
    wire [PTR_WIDTH-1:0] rd_ptr_s = rd_ptr_sync2;

    assign s_full = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr_s[ADDR_WIDTH-1:0]) &&
                    (wr_ptr[ADDR_WIDTH] != rd_ptr_s[ADDR_WIDTH]);

    assign m_empty = (rd_ptr == wr_ptr_m);

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_wr_ptr_m = wr_ptr_sync2;
    wire [PTR_WIDTH-1:0] s_rd_ptr_s = rd_ptr;
    wire [PTR_WIDTH-1:0] s_depth_raw = s_wr_ptr_m - s_rd_ptr_s;
    assign s_depth = s_depth_raw[PTR_WIDTH-1:0];
    assign s_depth_commit = s_depth;

    wire [PTR_WIDTH-1:0] m_wr_ptr_m = wr_ptr;
    wire [PTR_WIDTH-1:0] m_rd_ptr_s = rd_ptr_sync2;
    wire [PTR_WIDTH-1:0] m_depth_raw = m_wr_ptr_m - m_rd_ptr_s;
    assign m_depth = m_depth_raw[PTR_WIDTH-1:0];
    assign m_depth_commit = m_depth;

endmodule
