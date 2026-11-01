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
    localparam MAX_BYTES = (S_BYTES > M_BYTES) ? S_BYTES : M_BYTES;
    localparam ACC_WIDTH = $clog2(MAX_BYTES) + 1;
    localparam ACC_MAX = (1 << ACC_WIDTH) - 1;

    // Internal signals
    wire [S_DATA_WIDTH-1:0] s_data;
    wire [S_KEEP_WIDTH-1:0] s_keep;
    wire s_last;
    wire [ID_WIDTH-1:0] s_id;
    wire [DEST_WIDTH-1:0] s_dest;
    wire [USER_WIDTH-1:0] s_user;
    wire s_valid;
    wire s_ready;

    wire [M_DATA_WIDTH-1:0] m_data;
    wire [M_KEEP_WIDTH-1:0] m_keep;
    wire m_last;
    wire [ID_WIDTH-1:0] m_id;
    wire [DEST_WIDTH-1:0] m_dest;
    wire [USER_WIDTH-1:0] m_user;
    wire m_valid;
    wire m_ready;

    // Pause logic
    reg s_paused = 0;
    reg m_paused = 0;
    wire s_pause_active = PAUSE_ENABLE && s_paused;
    wire m_pause_active = PAUSE_ENABLE && m_paused;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_paused <= 0;
        else if (s_pause_req)
            s_paused <= 1;
        else if (s_pause_ack)
            s_paused <= 0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_paused <= 0;
        else if (m_pause_req)
            m_paused <= 1;
        else if (m_pause_ack)
            m_paused <= 0;
    end

    assign s_pause_ack = s_paused;
    assign m_pause_ack = m_paused;

    // Frame tracking
    reg s_in_frame = 0;
    reg m_in_frame = 0;
    reg [ACC_WIDTH-1:0] s_acc_bytes = 0;
    reg [ACC_WIDTH-1:0] m_acc_bytes = 0;
    reg s_bad_frame = 0;
    reg m_bad_frame = 0;
    reg s_overflow = 0;
    reg m_overflow = 0;
    reg s_good_frame = 0;
    reg m_good_frame = 0;

    // FIFO pointers
    reg [PTR_WIDTH-1:0] s_wr_ptr = 0;
    reg [PTR_WIDTH-1:0] m_rd_ptr = 0;
    reg [PTR_WIDTH-1:0] s_wr_ptr_commit = 0;
    reg [PTR_WIDTH-1:0] m_rd_ptr_commit = 0;

    // RAM
    reg [S_DATA_WIDTH-1:0] ram [0:DEPTH-1];
    reg [S_KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];

    // Write logic
    wire s_write = s_valid && s_ready && !s_pause_active;
    wire [ADDR_WIDTH-1:0] s_wr_addr = s_wr_ptr[ADDR_WIDTH-1:0];

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wr_ptr <= 0;
            s_wr_ptr_commit <= 0;
            s_in_frame <= 0;
            s_acc_bytes <= 0;
            s_bad_frame <= 0;
            s_overflow <= 0;
            s_good_frame <= 0;
        end else begin
            s_wr_ptr_commit <= s_wr_ptr;
            if (s_write) begin
                ram[s_wr_addr] <= s_data;
                ram_keep[s_wr_addr] <= s_keep;
                ram_last[s_wr_addr] <= s_last;
                ram_id[s_wr_addr] <= s_id;
                ram_dest[s_wr_addr] <= s_dest;
                ram_user[s_wr_addr] <= s_user;
                s_wr_ptr <= s_wr_ptr + 1;
            end
        end
    end

    // Read logic
    wire m_read = m_valid && m_ready && !m_pause_active;
    wire [ADDR_WIDTH-1:0] m_rd_addr = m_rd_ptr[ADDR_WIDTH-1:0];

    wire [S_DATA_WIDTH-1:0] rd_data;
    wire [S_KEEP_WIDTH-1:0] rd_keep;
    wire rd_last;
    wire [ID_WIDTH-1:0] rd_id;
    wire [DEST_WIDTH-1:0] rd_dest;
    wire [USER_WIDTH-1:0] rd_user;

    assign rd_data = ram[m_rd_addr];
    assign rd_keep = ram_keep[m_rd_addr];
    assign rd_last = ram_last[m_rd_addr];
    assign rd_id = ram_id[m_rd_addr];
    assign rd_dest = ram_dest[m_rd_addr];
    assign rd_user = ram_user[m_rd_addr];

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_rd_ptr <= 0;
            m_rd_ptr_commit <= 0;
            m_in_frame <= 0;
            m_acc_bytes <= 0;
            m_bad_frame <= 0;
            m_overflow <= 0;
            m_good_frame <= 0;
        end else begin
            m_rd_ptr_commit <= m_rd_ptr;
            if (m_read) begin
                m_rd_ptr <= m_rd_ptr + 1;
            end
        end
    end

    // Width conversion and output generation
    reg [S_DATA_WIDTH-1:0] out_data_reg = 0;
    reg [S_KEEP_WIDTH-1:0] out_keep_reg = 0;
    reg out_last_reg = 0;
    reg [ID_WIDTH-1:0] out_id_reg = 0;
    reg [DEST_WIDTH-1:0] out_dest_reg = 0;
    reg [USER_WIDTH-1:0] out_user_reg = 0;
    reg out_valid_reg = 0;

    wire [ACC_WIDTH-1:0] s_keep_count = s_keep; // Simplified: assume tkeep is byte count
    wire [ACC_WIDTH-1:0] rd_keep_count = rd_keep;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            out_data_reg <= 0;
            out_keep_reg <= 0;
            out_last_reg <= 0;
            out_id_reg <= 0;
            out_dest_reg <= 0;
            out_user_reg <= 0;
            out_valid_reg <= 0;
        end else begin
            if (m_read) begin
                out_valid_reg <= 0;
            end else if (!out_valid_reg && m_rd_ptr != s_wr_ptr_commit) begin
                out_data_reg <= rd_data;
                out_keep_reg <= rd_keep;
                out_last_reg <= rd_last;
                out_id_reg <= rd_id;
                out_dest_reg <= rd_dest;
                out_user_reg <= rd_user;
                out_valid_reg <= 1;
            end
        end
    end

    // Output assignment
    assign m_axis_tdata = out_data_reg;
    assign m_axis_tkeep = out_keep_reg;
    assign m_axis_tvalid = out_valid_reg;
    assign m_axis_tlast = out_last_reg;
    assign m_axis_tid = out_id_reg;
    assign m_axis_tdest = out_dest_reg;
    assign m_axis_tuser = out_user_reg;

    // Ready logic
    wire fifo_full = (s_wr_ptr - m_rd_ptr_commit) >= DEPTH;
    wire s_can_write = !fifo_full && !s_pause_active;
    assign s_axis_tready = s_can_write;

    // Status
    wire [PTR_WIDTH-1:0] s_depth = s_wr_ptr - m_rd_ptr_commit;
    wire [PTR_WIDTH-1:0] m_depth = s_wr_ptr_commit - m_rd_ptr;

    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_wr_ptr_commit - m_rd_ptr_commit;
    assign s_status_overflow = s_overflow;
    assign s_status_bad_frame = s_bad_frame;
    assign s_status_good_frame = s_good_frame;

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = s_wr_ptr_commit - m_rd_ptr;
    assign m_status_overflow = m_overflow;
    assign m_status_bad_frame = m_bad_frame;
    assign m_status_good_frame = m_good_frame;

    // Input assignment
    assign s_data = s_axis_tdata;
    assign s_keep = s_axis_tkeep;
    assign s_last = s_axis_tlast;
    assign s_id = s_axis_tid;
    assign s_dest = s_axis_tdest;
    assign s_user = s_axis_tuser;
    assign s_valid = s_axis_tvalid;
    assign s_ready = s_axis_tready;

    // Output ready
    assign m_ready = m_axis_tready;
    assign m_valid = m_axis_tvalid;

endmodule
