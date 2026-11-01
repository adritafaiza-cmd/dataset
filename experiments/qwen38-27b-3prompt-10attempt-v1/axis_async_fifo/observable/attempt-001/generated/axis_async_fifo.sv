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
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + KEEP_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH;

    // Storage arrays
    reg [DATA_WIDTH-1:0]  mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0]  mem_keep [0:DEPTH-1];
    reg                   mem_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]    mem_id   [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]  mem_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]  mem_user [0:DEPTH-1];

    // Write pointer (s_clk domain)
    reg [PTR_WIDTH-1:0] w_ptr;
    // Read pointer (m_clk domain)
    reg [PTR_WIDTH-1:0] r_ptr;

    // Synchronizers for read pointer to s_clk domain
    reg [PTR_WIDTH-1:0] r_ptr_sync1, r_ptr_sync2, r_ptr_sync3;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            r_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            r_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            r_ptr_sync1 <= r_ptr;
            r_ptr_sync2 <= r_ptr_sync1;
            r_ptr_sync3 <= r_ptr_sync2;
        end
    end

    // Synchronizers for write pointer to m_clk domain
    reg [PTR_WIDTH-1:0] w_ptr_sync1, w_ptr_sync2, w_ptr_sync3;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            w_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync2 <= {PTR_WIDTH{1'b0}};
            w_ptr_sync3 <= {PTR_WIDTH{1'b0}};
        end else begin
            w_ptr_sync1 <= w_ptr;
            w_ptr_sync2 <= w_ptr_sync1;
            w_ptr_sync3 <= w_ptr_sync2;
        end
    end

    // Depth calculations
    wire [PTR_WIDTH-1:0] s_depth = w_ptr - r_ptr_sync3;
    wire [PTR_WIDTH-1:0] m_depth = w_ptr_sync3 - r_ptr;

    // Full and empty conditions
    wire s_full = (s_depth == DEPTH);
    wire m_empty = (m_depth == 0);

    // Pause logic
    reg s_paused, m_paused;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) s_paused <= 1'b0;
        else if (PAUSE_ENABLE) s_paused <= s_pause_req;
        else s_paused <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) m_paused <= 1'b0;
        else if (PAUSE_ENABLE) m_paused <= m_pause_req;
        else m_paused <= 1'b0;
    end

    // Frame tracking in s_clk domain
    reg s_in_frame;
    reg s_frame_bad;
    reg s_frame_oversize;
    reg [ADDR_WIDTH-1:0] s_frame_start_addr;
    reg [PTR_WIDTH-1:0] s_frame_count;

    // Write enable
    wire s_write_en = s_axis_tvalid && s_axis_tready && !s_paused;

    // Determine if frame is bad based on user signals
    wire s_user_bad = (USER_ENABLE && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE);

    // Frame commit logic
    wire s_frame_end = s_axis_tlast && s_write_en;

    // Drop/mark logic
    wire s_drop_frame = (DROP_OVERSIZE_FRAME && s_frame_oversize) || (DROP_BAD_FRAME && s_frame_bad);
    wire s_mark_frame = (MARK_WHEN_FULL && s_full);

    // Actual write to memory
    wire s_mem_write = s_write_en && !s_drop_frame;

    // Status flags
    reg s_overflow_flag, s_bad_frame_flag, s_good_frame_flag;
    reg m_overflow_flag, m_bad_frame_flag, m_good_frame_flag;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_overflow_flag <= 1'b0;
            s_bad_frame_flag <= 1'b0;
            s_good_frame_flag <= 1'b0;
        end else begin
            if (s_full && s_axis_tvalid && !s_paused) s_overflow_flag <= 1'b1;
            if (s_frame_end && s_frame_bad) s_bad_frame_flag <= 1'b1;
            if (s_frame_end && !s_frame_bad) s_good_frame_flag <= 1'b1;
        end
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_overflow_flag <= 1'b0;
            m_bad_frame_flag <= 1'b0;
            m_good_frame_flag <= 1'b0;
        end else begin
            // These are set based on what was written
            // For simplicity, we track them in s_clk and sync
        end
    end

    // Synchronize status flags to m_clk
    reg s_overflow_sync1, s_overflow_sync2;
    reg s_bad_frame_sync1, s_bad_frame_sync2;
    reg s_good_frame_sync1, s_good_frame_sync2;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            s_overflow_sync1 <= 1'b0;
            s_overflow_sync2 <= 1'b0;
            s_bad_frame_sync1 <= 1'b0;
            s_bad_frame_sync2 <= 1'b0;
            s_good_frame_sync1 <= 1'b0;
            s_good_frame_sync2 <= 1'b0;
        end else begin
            s_overflow_sync1 <= s_overflow_flag;
            s_overflow_sync2 <= s_overflow_sync1;
            s_bad_frame_sync1 <= s_bad_frame_flag;
            s_bad_frame_sync2 <= s_bad_frame_sync1;
            s_good_frame_sync1 <= s_good_frame_flag;
            s_good_frame_sync2 <= s_good_frame_sync1;
        end
    end

    // Read enable
    wire m_read_en = m_axis_tvalid && m_axis_tready && !m_paused;

    // Memory write
    always @(posedge s_clk) begin
        if (s_mem_write) begin
            mem_data[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdata;
            mem_keep[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tkeep;
            mem_last[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tlast;
            mem_id[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tid;
            mem_dest[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tdest;
            mem_user[w_ptr[ADDR_WIDTH-1:0]] <= s_axis_tuser;
        end
    end

    // Memory read
    wire [ADDR_WIDTH-1:0] r_addr = r_ptr[ADDR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] r_data = mem_data[r_addr];
    wire [KEEP_WIDTH-1:0] r_keep = mem_keep[r_addr];
    wire                  r_last = mem_last[r_addr];
    wire [ID_WIDTH-1:0]   r_id   = mem_id[r_addr];
    wire [DEST_WIDTH-1:0] r_dest = mem_dest[r_addr];
    wire [USER_WIDTH-1:0] r_user = mem_user[r_addr];

    // Output FIFO logic
    reg [DATA_WIDTH-1:0]  out_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0]  out_fifo_keep [0:DEPTH-1];
    reg                   out_fifo_last [0:DEPTH-1];
    reg [ID_WIDTH-1:0]    out_fifo_id   [0:DEPTH-1];
    reg [DEST_WIDTH-1:0]  out_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0]  out_fifo_user [0:DEPTH-1];
    reg [PTR_WIDTH-1:0]   out_fifo_wptr, out_fifo_rptr;
    reg                   out_fifo_valid;

    wire out_fifo_full = (out_fifo_wptr - out_fifo_rptr == DEPTH);
    wire out_fifo_empty = (out_fifo_wptr == out_fifo_rptr);

    // Write to output FIFO from main FIFO read
    wire out_fifo_write_en = m_read_en && !out_fifo_full;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            out_fifo_wptr <= {PTR_WIDTH{1'b0}};
            out_fifo_rptr <= {PTR_WIDTH{1'b0}};
            out_fifo_valid <= 1'b0;
        end else begin
            if (out_fifo_write_en) begin
                out_fifo_data[out_fifo_wptr[ADDR_WIDTH-1:0]] <= r_data;
                out_fifo_keep[out_fifo_wptr[ADDR_WIDTH-1:0]] <= r_keep;
                out_fifo_last[out_fifo_wptr[ADDR_WIDTH-1:0]] <= r_last;
                out_fifo_id[out_fifo_wptr[ADDR_WIDTH-1:0]] <= r_id;
                out_fifo_dest[out_fifo_wptr[ADDR_WIDTH-1:0]] <= r_dest;
                out_fifo_user[out_fifo_wptr[ADDR_WIDTH-1:0]] <= r_user;
                out_fifo_wptr <= out_fifo_wptr + 1'b1;
            end
            if (m_axis_tvalid && m_axis_tready && !m_paused) begin
                out_fifo_rptr <= out_fifo_rptr + 1'b1;
            end
        end
    end

    // Output FIFO read address
    wire [ADDR_WIDTH-1:0] out_fifo_raddr = out_fifo_rptr[ADDR_WIDTH-1:0];
    wire [DATA_WIDTH-1:0]  out_fifo_rdata = out_fifo_data[out_fifo_raddr];
    wire [KEEP_WIDTH-1:0]  out_fifo_rkeep = out_fifo_keep[out_fifo_raddr];
    wire                  out_fifo_rlast = out_fifo_last[out_fifo_raddr];
    wire [ID_WIDTH-1:0]    out_fifo_rid   = out_fifo_id[out_fifo_raddr];
    wire [DEST_WIDTH-1:0]  out_fifo_rdest = out_fifo_dest[out_fifo_raddr];
    wire [USER_WIDTH-1:0]  out_fifo_ruser = out_fifo_user[out_fifo_raddr];

    // Main FIFO read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            r_ptr <= {PTR_WIDTH{1'b0}};
        end else if (m_read_en) begin
            r_ptr <= r_ptr + 1'b1;
        end
    end

    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            w_ptr <= {PTR_WIDTH{1'b0}};
            s_in_frame <= 1'b0;
            s_frame_bad <= 1'b0;
            s_frame_oversize <= 1'b0;
            s_frame_start_addr <= {ADDR_WIDTH{1'b0}};
            s_frame_count <= {PTR_WIDTH{1'b0}};
        end else begin
            if (s_write_en) begin
                w_ptr <= w_ptr + 1'b1;
                if (!s_in_frame) begin
                    s_in_frame <= 1'b1;
                    s_frame_start_addr <= w_ptr[ADDR_WIDTH-1:0];
                    s_frame_count <= 1'b1;
                    s_frame_bad <= s_user_bad;
                    s_frame_oversize <= 1'b0;
                end else begin
                    s_frame_count <= s_frame_count + 1'b1;
                    if (s_user_bad) s_frame_bad <= 1'b1;
                    if (s_frame_count >= DEPTH) s_frame_oversize <= 1'b1;
                end
                if (s_frame_end) begin
                    s_in_frame <= 1'b0;
                    s_frame_bad <= 1'b0;
                    s_frame_oversize <= 1'b0;
                    s_frame_count <= {PTR_WIDTH{1'b0}};
                end
            end
        end
    end

    // AXI output signals
    assign m_axis_tdata = OUTPUT_FIFO_ENABLE ? out_fifo_rdata : r_data;
    assign m_axis_tkeep = OUTPUT_FIFO_ENABLE ? out_fifo_rkeep : r_keep;
    assign m_axis_tlast = OUTPUT_FIFO_ENABLE ? out_fifo_rlast : r_last;
    assign m_axis_tid   = OUTPUT_FIFO_ENABLE ? out_fifo_rid   : r_id;
    assign m_axis_tdest = OUTPUT_FIFO_ENABLE ? out_fifo_rdest : r_dest;
    assign m_axis_tuser = OUTPUT_FIFO_ENABLE ? out_fifo_ruser : r_user;

    assign m_axis_tvalid = OUTPUT_FIFO_ENABLE ? !out_fifo_empty : !m_empty;

    // AXI input ready
    assign s_axis_tready = !s_full && !s_paused;

    // Pause ack
    assign s_pause_ack = s_paused;
    assign m_pause_ack = m_paused;

    // Status outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_overflow_flag;
    assign s_status_bad_frame = s_bad_frame_flag;
    assign s_status_good_frame = s_good_frame_flag;

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = s_overflow_sync2;
    assign m_status_bad_frame = s_bad_frame_sync2;
    assign m_status_good_frame = s_good_frame_sync2;

endmodule
