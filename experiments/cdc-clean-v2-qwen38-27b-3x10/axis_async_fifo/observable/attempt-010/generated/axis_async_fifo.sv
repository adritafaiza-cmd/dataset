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

    // Total data width for storage
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + 
                                  (KEEP_ENABLE ? KEEP_WIDTH : 0) + 
                                  (LAST_ENABLE ? 1 : 0) + 
                                  (ID_ENABLE ? ID_WIDTH : 0) + 
                                  (DEST_ENABLE ? DEST_WIDTH : 0) + 
                                  (USER_ENABLE ? USER_WIDTH : 0);

    // RAM storage
    reg [TOTAL_DATA_WIDTH-1:0] ram [0:DEPTH-1];

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;

    // Gray code pointers for CDC
    reg [PTR_WIDTH-1:0] w_ptr_gray;
    reg [PTR_WIDTH-1:0] r_ptr_gray;

    // Synchronizers
    reg [PTR_WIDTH-1:0] w_ptr_gray_sync1, w_ptr_gray_sync2;
    reg [PTR_WIDTH-1:0] r_ptr_gray_sync1, r_ptr_gray_sync2;

    // Pause synchronizers
    reg s_pause_req_sync1, s_pause_req_sync2;
    reg m_pause_req_sync1, m_pause_req_sync2;

    // Status flags
    reg s_overflow_flag;
    reg m_overflow_flag;
    reg s_bad_frame_flag;
    reg m_bad_frame_flag;
    reg s_good_frame_flag;
    reg m_good_frame_flag;

    // Frame tracking for s_clk domain
    reg s_in_frame;
    reg [ADDR_WIDTH:0] s_frame_count;
    reg s_frame_oversize;

    // Frame tracking for m_clk domain
    reg m_in_frame;
    reg [ADDR_WIDTH:0] m_frame_count;
    reg m_frame_oversize;

    // Drop/mark when full logic
    reg s_drop_when_full_active;
    reg s_mark_when_full_active;

    // Pause logic
    reg s_paused;
    reg m_paused;

    // Write enable
    wire s_write_en;
    // Read enable
    wire m_read_en;

    // Full/Empty
    wire s_full;
    wire m_empty;

    // Depth calculation
    wire [PTR_WIDTH-1:0] s_depth;
    wire [PTR_WIDTH-1:0] m_depth;

    // Output register for m_clk domain
    reg [TOTAL_DATA_WIDTH-1:0] m_out_reg;
    reg m_out_valid;

    // Internal signals
    wire [ADDR_WIDTH-1:0] w_addr;
    wire [ADDR_WIDTH-1:0] r_addr;

    // Pack/unpack data
    wire [DATA_WIDTH-1:0] s_pack_data;
    wire [KEEP_WIDTH-1:0] s_pack_keep;
    wire s_pack_last;
    wire [ID_WIDTH-1:0] s_pack_id;
    wire [DEST_WIDTH-1:0] s_pack_dest;
    wire [USER_WIDTH-1:0] s_pack_user;

    wire [DATA_WIDTH-1:0] m_unpack_data;
    wire [KEEP_WIDTH-1:0] m_unpack_keep;
    wire m_unpack_last;
    wire [ID_WIDTH-1:0] m_unpack_id;
    wire [DEST_WIDTH-1:0] m_unpack_dest;
    wire [USER_WIDTH-1:0] m_unpack_user;

    // Pack data into single vector
    assign s_pack_data = s_axis_tdata;
    assign s_pack_keep = KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}};
    assign s_pack_last = LAST_ENABLE ? s_axis_tlast : 1'b0;
    assign s_pack_id = ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}};
    assign s_pack_dest = DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
    assign s_pack_user = USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};

    // Unpack data from single vector
    assign m_unpack_data = m_out_reg[DATA_WIDTH-1:0];
    assign m_unpack_keep = KEEP_ENABLE ? m_out_reg[DATA_WIDTH +: KEEP_WIDTH] : {KEEP_WIDTH{1'b0}};
    assign m_unpack_last = LAST_ENABLE ? m_out_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)] : 1'b0;
    assign m_unpack_id = ID_ENABLE ? m_out_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) +: ID_WIDTH] : {ID_WIDTH{1'b0}};
    assign m_unpack_dest = DEST_ENABLE ? m_out_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) +: DEST_WIDTH] : {DEST_WIDTH{1'b0}};
    assign m_unpack_user = USER_ENABLE ? m_out_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) +: USER_WIDTH] : {USER_WIDTH{1'b0}};

    // Write address
    assign w_addr = w_ptr[ADDR_WIDTH-1:0];
    // Read address
    assign r_addr = r_ptr[ADDR_WIDTH-1:0];

    // Full condition: write pointer is one full cycle ahead of read pointer
    assign s_full = (w_ptr[PTR_WIDTH-1] != r_ptr_gray_sync2[PTR_WIDTH-1]) && 
                    (w_ptr[ADDR_WIDTH-1:0] == r_ptr_gray_sync2[ADDR_WIDTH-1:0]);

    // Empty condition: read pointer equals write pointer
    assign m_empty = (r_ptr == w_ptr_gray_sync2);

    // Depth calculation
    assign s_depth = w_ptr - r_ptr_gray_sync2;
    assign m_depth = w_ptr_gray_sync2 - r_ptr;

    // Pause logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_paused <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (s_pause_req_sync2 && !s_paused) begin
                s_paused <= 1'b1;
            end else if (!s_pause_req_sync2 && s_paused) begin
                s_paused <= 1'b0;
            end
        end else begin
            s_paused <= 1'b0;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_paused <= 1'b0;
        end else if (PAUSE_ENABLE) begin
            if (m_pause_req_sync2 && !m_paused) begin
                m_paused <= 1'b1;
            end else if (!m_pause_req_sync2 && m_paused) begin
                m_paused <= 1'b0;
            end
        end else begin
            m_paused <= 1'b0;
        end
    end

    assign s_pause_ack = s_paused;
    assign m_pause_ack = m_paused;

    // Frame tracking in s_clk domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_in_frame <= 1'b0;
            s_frame_count <= {ADDR_WIDTH+1{1'b0}};
            s_frame_oversize <= 1'b0;
        end else begin
            if (s_write_en) begin
                if (s_pack_last) begin
                    s_in_frame <= 1'b0;
                    s_frame_count <= {ADDR_WIDTH+1{1'b0}};
                    s_frame_oversize <= 1'b0;
                end else begin
                    if (!s_in_frame) begin
                        s_in_frame <= 1'b1;
                        s_frame_count <= {{ADDR_WIDTH{1'b0}}, 1'b1};
                    end else begin
                        s_frame_count <= s_frame_count + 1'b1;
                        if (s_frame_count >= DEPTH[ADDR_WIDTH:0]) begin
                            s_frame_oversize <= 1'b1;
                        end
                    end
                end
            end
        end
    end

    // Frame tracking in m_clk domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_in_frame <= 1'b0;
            m_frame_count <= {ADDR_WIDTH+1{1'b0}};
            m_frame_oversize <= 1'b0;
        end else begin
            if (m_read_en) begin
                if (m_unpack_last) begin
                    m_in_frame <= 1'b0;
                    m_frame_count <= {ADDR_WIDTH+1{1'b0}};
                    m_frame_oversize <= 1'b0;
                end else begin
                    if (!m_in_frame) begin
                        m_in_frame <= 1'b1;
                        m_frame_count <= {{ADDR_WIDTH{1'b0}}, 1'b1};
                    end else begin
                        m_frame_count <= m_frame_count + 1'b1;
                        if (m_frame_count >= DEPTH[ADDR_WIDTH:0]) begin
                            m_frame_oversize <= 1'b1;
                        end
                    end
                end
            end
        end
    end

    // Drop/mark when full
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_drop_when_full_active <= 1'b0;
            s_mark_when_full_active <= 1'b0;
        end else begin
            if (DROP_WHEN_FULL) begin
                s_drop_when_full_active <= s_full && s_axis_tvalid && !s_paused;
            end else begin
                s_drop_when_full_active <= 1'b0;
            end
            if (MARK_WHEN_FULL) begin
                s_mark_when_full_active <= s_full && s_axis_tvalid && !s_paused;
            end else begin
                s_mark_when_full_active <= 1'b0;
            end
        end
    end

    // Write enable
    assign s_write_en = s_axis_tvalid && s_axis_tready && !s_paused && 
                        !(DROP_WHEN_FULL && s_full) && 
                        !(DROP_OVERSIZE_FRAME && s_frame_oversize && !s_pack_last) &&
                        !(DROP_BAD_FRAME && s_bad_frame_flag);

    // tready
    assign s_axis_tready = !s_full && !s_paused && 
                           !(DROP_WHEN_FULL && s_full) &&
                           !(DROP_OVERSIZE_FRAME && s_frame_oversize && !s_pack_last) &&
                           !(DROP_BAD_FRAME && s_bad_frame_flag);

    // RAM write
    always @(posedge s_clk) begin
        if (s_write_en) begin
            ram[w_addr] <= {s_pack_user, s_pack_dest, s_pack_id, s_pack_last, s_pack_keep, s_pack_data};
        end
    end

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
        end else if (s_write_en) begin
            w_ptr <= w_ptr + 1'b1;
        end
    end

    // Gray code conversion for write pointer
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_gray <= (w_ptr >> 1) ^ w_ptr;
        end
    end

    // Synchronize write pointer gray to m_clk domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            w_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            w_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_gray_sync1 <= w_ptr_gray;
            w_ptr_gray_sync2 <= w_ptr_gray_sync1;
        end
    end

    // Read enable
    assign m_read_en = m_out_valid && m_axis_tready && !m_paused;

    // RAM read
    always @(posedge m_clk) begin
        if (m_read_en) begin
            m_out_reg <= ram[r_addr];
        end
    end

    // Output valid
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_out_valid <= 1'b0;
        end else begin
            if (m_read_en) begin
                m_out_valid <= !m_empty;
            end else if (!m_out_valid && !m_empty) begin
                m_out_valid <= 1'b1;
            end
        end
    end

    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
        end else if (m_read_en) begin
            r_ptr <= r_ptr + 1'b1;
        end
    end

    // Gray code conversion for read pointer
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr_gray <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_gray <= (r_ptr >> 1) ^ r_ptr;
        end
    end

    // Synchronize read pointer gray to s_clk domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            r_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_gray_sync1 <= r_ptr_gray;
            r_ptr_gray_sync2 <= r_ptr_gray_sync1;
        end
    end

    // Synchronize pause requests
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_req_sync1 <= 1'b0;
            s_pause_req_sync2 <= 1'b0;
        end else begin
            s_pause_req_sync1 <= s_pause_req;
            s_pause_req_sync2 <= s_pause_req_sync1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_req_sync1 <= 1'b0;
            m_pause_req_sync2 <= 1'b0;
        end else begin
            m_pause_req_sync1 <= m_pause_req;
            m_pause_req_sync2 <= m_pause_req_sync1;
        end
    end

    // Overflow flags
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow_flag <= 1'b0;
        end else if (s_full && s_axis_tvalid && !s_paused) begin
            s_overflow_flag <= 1'b1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_overflow_flag <= 1'b0;
        end else if (s_full && s_axis_tvalid && !s_paused) begin
            m_overflow_flag <= 1'b1;
        end
    end

    // Bad frame flags
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bad_frame_flag <= 1'b0;
        end else if (DROP_BAD_FRAME && s_frame_oversize && s_pack_last) begin
            s_bad_frame_flag <= 1'b1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bad_frame_flag <= 1'b0;
        end else if (DROP_BAD_FRAME && m_frame_oversize && m_unpack_last) begin
            m_bad_frame_flag <= 1'b1;
        end
    end

    // Good frame flags
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_good_frame_flag <= 1'b0;
        end else if (s_pack_last && !s_frame_oversize && s_write_en) begin
            s_good_frame_flag <= 1'b1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_good_frame_flag <= 1'b0;
        end else if (m_unpack_last && !m_frame_oversize && m_read_en) begin
            m_good_frame_flag <= 1'b1;
        end
    end

    // Output assignments
    assign m_axis_tdata = m_unpack_data;
    assign m_axis_tkeep = m_unpack_keep;
    assign m_axis_tvalid = m_out_valid;
    assign m_axis_tlast = m_unpack_last;
    assign m_axis_tid = m_unpack_id;
    assign m_axis_tdest = m_unpack_dest;
    assign m_axis_tuser = m_unpack_user;

    // Status assignments
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_overflow_flag;
    assign s_status_bad_frame = s_bad_frame_flag;
    assign s_status_good_frame = s_good_frame_flag;

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = m_overflow_flag;
    assign m_status_bad_frame = m_bad_frame_flag;
    assign m_status_good_frame = m_good_frame_flag;

endmodule
