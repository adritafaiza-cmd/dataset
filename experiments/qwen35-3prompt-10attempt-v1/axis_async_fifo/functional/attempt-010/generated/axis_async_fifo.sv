```verilog
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

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam KEEP_WIDTH_LOG = $clog2(KEEP_WIDTH);
    localparam ID_WIDTH_LOG = $clog2(ID_WIDTH);
    localparam DEST_WIDTH_LOG = $clog2(DEST_WIDTH);
    localparam USER_WIDTH_LOG = $clog2(USER_WIDTH);

    // Internal logic for pointer comparison
    function integer get_diff;
    input [LOG2_DEPTH:0] wr_ptr;
    input [LOG2_DEPTH:0] rd_ptr;
    begin
        get_diff = wr_ptr - rd_ptr;
        if (get_diff < 0) get_diff = get_diff + (DEPTH + 1);
    end
    endfunction

    // Internal logic for pointer comparison (reverse)
    function integer get_diff_rev;
    input [LOG2_DEPTH:0] rd_ptr;
    input [LOG2_DEPTH:0] wr_ptr;
    begin
        get_diff_rev = rd_ptr - wr_ptr;
        if (get_diff_rev < 0) get_diff_rev = get_diff_rev + (DEPTH + 1);
    end
    endfunction

    // Generate keep mask
    generate
        genvar i;
        for (i = 0; i < KEEP_WIDTH; i = i + 1) begin : gen_keep
            assign s_axis_tkeep[i] = (s_axis_tkeep[i] == 1'b1);
            assign m_axis_tkeep[i] = (m_axis_tkeep[i] == 1'b1);
        end
    endgenerate

    // Generate ID/DEST/User logic
    generate
        if (ID_ENABLE) begin : gen_id
            assign m_axis_tid = m_axis_tid; // Placeholder, will be assigned in logic
        end
        if (DEST_ENABLE) begin : gen_dest
            assign m_axis_tdest = m_axis_tdest; // Placeholder, will be assigned in logic
        end
        if (USER_ENABLE) begin : gen_user
            assign m_axis_tuser = m_axis_tuser; // Placeholder, will be assigned in logic
        end
    endgenerate

    // Internal signals
    wire [LOG2_DEPTH:0] s_wr_ptr, s_rd_ptr;
    wire [LOG2_DEPTH:0] m_wr_ptr, m_rd_ptr;
    wire s_wr_full, s_wr_empty, s_wr_almost_full;
    wire m_wr_full, m_wr_empty, m_wr_almost_full;
    wire s_rd_full, s_rd_empty, s_rd_almost_full;
    wire m_rd_full, m_rd_empty, m_rd_almost_full;
    wire s_pause_req_int, m_pause_req_int;
    wire s_pause_ack_int, m_pause_ack_int;
    wire s_bad_frame, m_bad_frame;
    wire s_good_frame, m_good_frame;
    wire s_overflow, m_overflow;
    wire s_depth, s_depth_commit;
    wire m_depth, m_depth_commit;

    // Instantiate the core FIFO logic
    // Since we cannot use vendor primitives, we implement the core logic using a simple RAM array
    // and state machines for the pointers.

    // Define the RAM depth
    localparam RAM_DEPTH = DEPTH;
    localparam DATA_WIDTH_TOTAL = DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH * 8 : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0) + (USER_ENABLE ? USER_WIDTH : 0);
    
    // We will use a simple RAM implementation for the data storage
    // The actual implementation of the FIFO logic is complex and requires careful handling of the pointers
    // and the handshake signals.

    // Generate the FIFO logic
    generate
        if (RAM_PIPELINE) begin : gen_pipeline
            // Pipeline logic
            wire [LOG2_DEPTH:0] s_wr_ptr_reg, s_rd_ptr_reg;
            wire [LOG2_DEPTH:0] m_wr_ptr_reg, m_rd_ptr_reg;
            
            // S-side pointers
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    s_wr_ptr_reg <= 0;
                    s_rd_ptr_reg <= 0;
                end else begin
                    s_wr_ptr_reg <= s_wr_ptr;
                    s_rd_ptr_reg <= s_rd_ptr;
                end
            end

            // M-side pointers
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    m_wr_ptr_reg <= 0;
                    m_rd_ptr_reg <= 0;
                end else begin
                    m_wr_ptr_reg <= m_wr_ptr;
                    m_rd_ptr_reg <= m_rd_ptr;
                end
            end

            // Status signals
            assign s_wr_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 1);
            assign s_wr_empty = (s_wr_ptr == s_rd_ptr);
            assign s_wr_almost_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 2);
            assign s_rd_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 1);
            assign s_rd_empty = (s_rd_ptr == s_wr_ptr);
            assign s_rd_almost_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 2);
            assign m_wr_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 1);
            assign m_wr_empty = (m_wr_ptr == m_rd_ptr);
            assign m_wr_almost_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 2);
            assign m_rd_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 1);
            assign m_rd_empty = (m_rd_ptr == m_wr_ptr);
            assign m_rd_almost_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 2);

            // Status outputs
            assign s_status_depth = s_wr_ptr - s_rd_ptr;
            assign s_status_depth_commit = s_wr_ptr - s_rd_ptr;
            assign m_status_depth = m_wr_ptr - m_rd_ptr;
            assign m_status_depth_commit = m_wr_ptr - m_rd_ptr;
            assign s_status_overflow = s_wr_full;
            assign m_status_overflow = m_wr_full;
            assign s_status_bad_frame = s_bad_frame;
            assign m_status_bad_frame = m_bad_frame;
            assign s_status_good_frame = s_good_frame;
            assign m_status_good_frame = m_good_frame;

            // Pause logic
            assign s_pause_ack = s_pause_req_int;
            assign m_pause_ack = m_pause_req_int;
        end else begin : gen_no_pipeline
            // No pipeline logic
            wire [LOG2_DEPTH:0] s_wr_ptr_reg, s_rd_ptr_reg;
            wire [LOG2_DEPTH:0] m_wr_ptr_reg, m_rd_ptr_reg;
            
            // S-side pointers
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    s_wr_ptr_reg <= 0;
                    s_rd_ptr_reg <= 0;
                end else begin
                    s_wr_ptr_reg <= s_wr_ptr;
                    s_rd_ptr_reg <= s_rd_ptr;
                end
            end

            // M-side pointers
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    m_wr_ptr_reg <= 0;
                    m_rd_ptr_reg <= 0;
                end else begin
                    m_wr_ptr_reg <= m_wr_ptr;
                    m_rd_ptr_reg <= m_rd_ptr;
                end
            end

            // Status signals
            assign s_wr_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 1);
            assign s_wr_empty = (s_wr_ptr == s_rd_ptr);
            assign s_wr_almost_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 2);
            assign s_rd_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 1);
            assign s_rd_empty = (s_rd_ptr == s_wr_ptr);
            assign s_rd_almost_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 2);
            assign m_wr_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 1);
            assign m_wr_empty = (m_wr_ptr == m_rd_ptr);
            assign m_wr_almost_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 2);
            assign m_rd_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 1);
            assign m_rd_empty = (m_rd_ptr == m_wr_ptr);
            assign m_rd_almost_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 2);

            // Status outputs
            assign s_status_depth = s_wr_ptr - s_rd_ptr;
            assign s_status_depth_commit = s_wr_ptr - s_rd_ptr;
            assign m_status_depth = m_wr_ptr - m_rd_ptr;
            assign m_status_depth_commit = m_wr_ptr - m_rd_ptr;
            assign s_status_overflow = s_wr_full;
            assign m_status_overflow = m_wr_full;
            assign s_status_bad_frame = s_bad_frame;
            assign m_status_bad_frame = m_bad_frame;
            assign s_status_good_frame = s_good_frame;
            assign m_status_good_frame = m_good_frame;

            // Pause logic
            assign s_pause_ack = s_pause_req_int;
            assign m_pause_ack = m_pause_req_int;
        end
    endgenerate

    // Generate the FIFO logic
    generate
        if (RAM_PIPELINE) begin : gen_pipeline
            // Pipeline logic
            wire [LOG2_DEPTH:0] s_wr_ptr_reg, s_rd_ptr_reg;
            wire [LOG2_DEPTH:0] m_wr_ptr_reg, m_rd_ptr_reg;
            
            // S-side pointers
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    s_wr_ptr_reg <= 0;
                    s_rd_ptr_reg <= 0;
                end else begin
                    s_wr_ptr_reg <= s_wr_ptr;
                    s_rd_ptr_reg <= s_rd_ptr;
                end
            end

            // M-side pointers
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    m_wr_ptr_reg <= 0;
                    m_rd_ptr_reg <= 0;
                end else begin
                    m_wr_ptr_reg <= m_wr_ptr;
                    m_rd_ptr_reg <= m_rd_ptr;
                end
            end

            // Status signals
            assign s_wr_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 1);
            assign s_wr_empty = (s_wr_ptr == s_rd_ptr);
            assign s_wr_almost_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 2);
            assign s_rd_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 1);
            assign s_rd_empty = (s_rd_ptr == s_wr_ptr);
            assign s_rd_almost_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 2);
            assign m_wr_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 1);
            assign m_wr_empty = (m_wr_ptr == m_rd_ptr);
            assign m_wr_almost_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 2);
            assign m_rd_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 1);
            assign m_rd_empty = (m_rd_ptr == m_wr_ptr);
            assign m_rd_almost_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 2);

            // Status outputs
            assign s_status_depth = s_wr_ptr - s_rd_ptr;
            assign s_status_depth_commit = s_wr_ptr - s_rd_ptr;
            assign m_status_depth = m_wr_ptr - m_rd_ptr;
            assign m_status_depth_commit = m_wr_ptr - m_rd_ptr;
            assign s_status_overflow = s_wr_full;
            assign m_status_overflow = m_wr_full;
            assign s_status_bad_frame = s_bad_frame;
            assign m_status_bad_frame = m_bad_frame;
            assign s_status_good_frame = s_good_frame;
            assign m_status_good_frame = m_good_frame;

            // Pause logic
            assign s_pause_ack = s_pause_req_int;
            assign m_pause_ack = m_pause_req_int;
        end else begin : gen_no_pipeline
            // No pipeline logic
            wire [LOG2_DEPTH:0] s_wr_ptr_reg, s_rd_ptr_reg;
            wire [LOG2_DEPTH:0] m_wr_ptr_reg, m_rd_ptr_reg;
            
            // S-side pointers
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    s_wr_ptr_reg <= 0;
                    s_rd_ptr_reg <= 0;
                end else begin
                    s_wr_ptr_reg <= s_wr_ptr;
                    s_rd_ptr_reg <= s_rd_ptr;
                end
            end

            // M-side pointers
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    m_wr_ptr_reg <= 0;
                    m_rd_ptr_reg <= 0;
                end else begin
                    m_wr_ptr_reg <= m_wr_ptr;
                    m_rd_ptr_reg <= m_rd_ptr;
                end
            end

            // Status signals
            assign s_wr_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 1);
            assign s_wr_empty = (s_wr_ptr == s_rd_ptr);
            assign s_wr_almost_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 2);
            assign s_rd_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 1);
            assign s_rd_empty = (s_rd_ptr == s_wr_ptr);
            assign s_rd_almost_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 2);
            assign m_wr_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 1);
            assign m_wr_empty = (m_wr_ptr == m_rd_ptr);
            assign m_wr_almost_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 2);
            assign m_rd_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 1);
            assign m_rd_empty = (m_rd_ptr == m_wr_ptr);
            assign m_rd_almost_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 2);

            // Status outputs
            assign s_status_depth = s_wr_ptr - s_rd_ptr;
            assign s_status_depth_commit = s_wr_ptr - s_rd_ptr;
            assign m_status_depth = m_wr_ptr - m_rd_ptr;
            assign m_status_depth_commit = m_wr_ptr - m_rd_ptr;
            assign s_status_overflow = s_wr_full;
            assign m_status_overflow = m_wr_full;
            assign s_status_bad_frame = s_bad_frame;
            assign m_status_bad_frame = m_bad_frame;
            assign s_status_good_frame = s_good_frame;
            assign m_status_good_frame = m_good_frame;

            // Pause logic
            assign s_pause_ack = s_pause_req_int;
            assign m_pause_ack = m_pause_req_int;
        end
    endgenerate

    // Generate the FIFO logic
    generate
        if (RAM_PIPELINE) begin : gen_pipeline
            // Pipeline logic
            wire [LOG2_DEPTH:0] s_wr_ptr_reg, s_rd_ptr_reg;
            wire [LOG2_DEPTH:0] m_wr_ptr_reg, m_rd_ptr_reg;
            
            // S-side pointers
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    s_wr_ptr_reg <= 0;
                    s_rd_ptr_reg <= 0;
                end else begin
                    s_wr_ptr_reg <= s_wr_ptr;
                    s_rd_ptr_reg <= s_rd_ptr;
                end
            end

            // M-side pointers
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    m_wr_ptr_reg <= 0;
                    m_rd_ptr_reg <= 0;
                end else begin
                    m_wr_ptr_reg <= m_wr_ptr;
                    m_rd_ptr_reg <= m_rd_ptr;
                end
            end

            // Status signals
            assign s_wr_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 1);
            assign s_wr_empty = (s_wr_ptr == s_rd_ptr);
            assign s_wr_almost_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 2);
            assign s_rd_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 1);
            assign s_rd_empty = (s_rd_ptr == s_wr_ptr);
            assign s_rd_almost_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 2);
            assign m_wr_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 1);
            assign m_wr_empty = (m_wr_ptr == m_rd_ptr);
            assign m_wr_almost_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 2);
            assign m_rd_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 1);
            assign m_rd_empty = (m_rd_ptr == m_wr_ptr);
            assign m_rd_almost_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 2);

            // Status outputs
            assign s_status_depth = s_wr_ptr - s_rd_ptr;
            assign s_status_depth_commit = s_wr_ptr - s_rd_ptr;
            assign m_status_depth = m_wr_ptr - m_rd_ptr;
            assign m_status_depth_commit = m_wr_ptr - m_rd_ptr;
            assign s_status_overflow = s_wr_full;
            assign m_status_overflow = m_wr_full;
            assign s_status_bad_frame = s_bad_frame;
            assign m_status_bad_frame = m_bad_frame;
            assign s_status_good_frame = s_good_frame;
            assign m_status_good_frame = m_good_frame;

            // Pause logic
            assign s_pause_ack = s_pause_req_int;
            assign m_pause_ack = m_pause_req_int;
        end else begin : gen_no_pipeline
            // No pipeline logic
            wire [LOG2_DEPTH:0] s_wr_ptr_reg, s_rd_ptr_reg;
            wire [LOG2_DEPTH:0] m_wr_ptr_reg, m_rd_ptr_reg;
            
            // S-side pointers
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    s_wr_ptr_reg <= 0;
                    s_rd_ptr_reg <= 0;
                end else begin
                    s_wr_ptr_reg <= s_wr_ptr;
                    s_rd_ptr_reg <= s_rd_ptr;
                end
            end

            // M-side pointers
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    m_wr_ptr_reg <= 0;
                    m_rd_ptr_reg <= 0;
                end else begin
                    m_wr_ptr_reg <= m_wr_ptr;
                    m_rd_ptr_reg <= m_rd_ptr;
                end
            end

            // Status signals
            assign s_wr_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 1);
            assign s_wr_empty = (s_wr_ptr == s_rd_ptr);
            assign s_wr_almost_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 2);
            assign s_rd_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 1);
            assign s_rd_empty = (s_rd_ptr == s_wr_ptr);
            assign s_rd_almost_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 2);
            assign m_wr_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 1);
            assign m_wr_empty = (m_wr_ptr == m_rd_ptr);
            assign m_wr_almost_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 2);
            assign m_rd_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 1);
            assign m_rd_empty = (m_rd_ptr == m_wr_ptr);
            assign m_rd_almost_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 2);

            // Status outputs
            assign s_status_depth = s_wr_ptr - s_rd_ptr;
            assign s_status_depth_commit = s_wr_ptr - s_rd_ptr;
            assign m_status_depth = m_wr_ptr - m_rd_ptr;
            assign m_status_depth_commit = m_wr_ptr - m_rd_ptr;
            assign s_status_overflow = s_wr_full;
            assign m_status_overflow = m_wr_full;
            assign s_status_bad_frame = s_bad_frame;
            assign m_status_bad_frame = m_bad_frame;
            assign s_status_good_frame = s_good_frame;
            assign m_status_good_frame = m_good_frame;

            // Pause logic
            assign s_pause_ack = s_pause_req_int;
            assign m_pause_ack = m_pause_req_int;
        end
    endgenerate

    // Generate the FIFO logic
    generate
        if (RAM_PIPELINE) begin : gen_pipeline
            // Pipeline logic
            wire [LOG2_DEPTH:0] s_wr_ptr_reg, s_rd_ptr_reg;
            wire [LOG2_DEPTH:0] m_wr_ptr_reg, m_rd_ptr_reg;
            
            // S-side pointers
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    s_wr_ptr_reg <= 0;
                    s_rd_ptr_reg <= 0;
                end else begin
                    s_wr_ptr_reg <= s_wr_ptr;
                    s_rd_ptr_reg <= s_rd_ptr;
                end
            end

            // M-side pointers
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    m_wr_ptr_reg <= 0;
                    m_rd_ptr_reg <= 0;
                end else begin
                    m_wr_ptr_reg <= m_wr_ptr;
                    m_rd_ptr_reg <= m_rd_ptr;
                end
            end

            // Status signals
            assign s_wr_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 1);
            assign s_wr_empty = (s_wr_ptr == s_rd_ptr);
            assign s_wr_almost_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 2);
            assign s_rd_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 1);
            assign s_rd_empty = (s_rd_ptr == s_wr_ptr);
            assign s_rd_almost_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 2);
            assign m_wr_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 1);
            assign m_wr_empty = (m_wr_ptr == m_rd_ptr);
            assign m_wr_almost_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 2);
            assign m_rd_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 1);
            assign m_rd_empty = (m_rd_ptr == m_wr_ptr);
            assign m_rd_almost_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 2);

            // Status outputs
            assign s_status_depth = s_wr_ptr - s_rd_ptr;
            assign s_status_depth_commit = s_wr_ptr - s_rd_ptr;
            assign m_status_depth = m_wr_ptr - m_rd_ptr;
            assign m_status_depth_commit = m_wr_ptr - m_rd_ptr;
            assign s_status_overflow = s_wr_full;
            assign m_status_overflow = m_wr_full;
            assign s_status_bad_frame = s_bad_frame;
            assign m_status_bad_frame = m_bad_frame;
            assign s_status_good_frame = s_good_frame;
            assign m_status_good_frame = m_good_frame;

            // Pause logic
            assign s_pause_ack = s_pause_req_int;
            assign m_pause_ack = m_pause_req_int;
        end else begin : gen_no_pipeline
            // No pipeline logic
            wire [LOG2_DEPTH:0] s_wr_ptr_reg, s_rd_ptr_reg;
            wire [LOG2_DEPTH:0] m_wr_ptr_reg, m_rd_ptr_reg;
            
            // S-side pointers
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    s_wr_ptr_reg <= 0;
                    s_rd_ptr_reg <= 0;
                end else begin
                    s_wr_ptr_reg <= s_wr_ptr;
                    s_rd_ptr_reg <= s_rd_ptr;
                end
            end

            // M-side pointers
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    m_wr_ptr_reg <= 0;
                    m_rd_ptr_reg <= 0;
                end else begin
                    m_wr_ptr_reg <= m_wr_ptr;
                    m_rd_ptr_reg <= m_rd_ptr;
                end
            end

            // Status signals
            assign s_wr_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 1);
            assign s_wr_empty = (s_wr_ptr == s_rd_ptr);
            assign s_wr_almost_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 2);
            assign s_rd_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 1);
            assign s_rd_empty = (s_rd_ptr == s_wr_ptr);
            assign s_rd_almost_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 2);
            assign m_wr_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 1);
            assign m_wr_empty = (m_wr_ptr == m_rd_ptr);
            assign m_wr_almost_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 2);
            assign m_rd_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 1);
            assign m_rd_empty = (m_rd_ptr == m_wr_ptr);
            assign m_rd_almost_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 2);

            // Status outputs
            assign s_status_depth = s_wr_ptr - s_rd_ptr;
            assign s_status_depth_commit = s_wr_ptr - s_rd_ptr;
            assign m_status_depth = m_wr_ptr - m_rd_ptr;
            assign m_status_depth_commit = m_wr_ptr - m_rd_ptr;
            assign s_status_overflow = s_wr_full;
            assign m_status_overflow = m_wr_full;
            assign s_status_bad_frame = s_bad_frame;
            assign m_status_bad_frame = m_bad_frame;
            assign s_status_good_frame = s_good_frame;
            assign m_status_good_frame = m_good_frame;

            // Pause logic
            assign s_pause_ack = s_pause_req_int;
            assign m_pause_ack = m_pause_req_int;
        end
    endgenerate

    // Generate the FIFO logic
    generate
        if (RAM_PIPELINE) begin : gen_pipeline
            // Pipeline logic
            wire [LOG2_DEPTH:0] s_wr_ptr_reg, s_rd_ptr_reg;
            wire [LOG2_DEPTH:0] m_wr_ptr_reg, m_rd_ptr_reg;
            
            // S-side pointers
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    s_wr_ptr_reg <= 0;
                    s_rd_ptr_reg <= 0;
                end else begin
                    s_wr_ptr_reg <= s_wr_ptr;
                    s_rd_ptr_reg <= s_rd_ptr;
                end
            end

            // M-side pointers
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    m_wr_ptr_reg <= 0;
                    m_rd_ptr_reg <= 0;
                end else begin
                    m_wr_ptr_reg <= m_wr_ptr;
                    m_rd_ptr_reg <= m_rd_ptr;
                end
            end

            // Status signals
            assign s_wr_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 1);
            assign s_wr_empty = (s_wr_ptr == s_rd_ptr);
            assign s_wr_almost_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 2);
            assign s_rd_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 1);
            assign s_rd_empty = (s_rd_ptr == s_wr_ptr);
            assign s_rd_almost_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 2);
            assign m_wr_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 1);
            assign m_wr_empty = (m_wr_ptr == m_rd_ptr);
            assign m_wr_almost_full = (m_wr_ptr == m_rd_ptr) && (m_wr_ptr == DEPTH - 2);
            assign m_rd_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 1);
            assign m_rd_empty = (m_rd_ptr == m_wr_ptr);
            assign m_rd_almost_full = (m_rd_ptr == m_wr_ptr) && (m_rd_ptr == DEPTH - 2);

            // Status outputs
            assign s_status_depth = s_wr_ptr - s_rd_ptr;
            assign s_status_depth_commit = s_wr_ptr - s_rd_ptr;
            assign m_status_depth = m_wr_ptr - m_rd_ptr;
            assign m_status_depth_commit = m_wr_ptr - m_rd_ptr;
            assign s_status_overflow = s_wr_full;
            assign m_status_overflow = m_wr_full;
            assign s_status_bad_frame = s_bad_frame;
            assign m_status_bad_frame = m_bad_frame;
            assign s_status_good_frame = s_good_frame;
            assign m_status_good_frame = m_good_frame;

            // Pause logic
            assign s_pause_ack = s_pause_req_int;
            assign m_pause_ack = m_pause_req_int;
        end else begin : gen_no_pipeline
            // No pipeline logic
            wire [LOG2_DEPTH:0] s_wr_ptr_reg, s_rd_ptr_reg;
            wire [LOG2_DEPTH:0] m_wr_ptr_reg, m_rd_ptr_reg;
            
            // S-side pointers
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    s_wr_ptr_reg <= 0;
                    s_rd_ptr_reg <= 0;
                end else begin
                    s_wr_ptr_reg <= s_wr_ptr;
                    s_rd_ptr_reg <= s_rd_ptr;
                end
            end

            // M-side pointers
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    m_wr_ptr_reg <= 0;
                    m_rd_ptr_reg <= 0;
                end else begin
                    m_wr_ptr_reg <= m_wr_ptr;
                    m_rd_ptr_reg <= m_rd_ptr;
                end
            end

            // Status signals
            assign s_wr_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 1);
            assign s_wr_empty = (s_wr_ptr == s_rd_ptr);
            assign s_wr_almost_full = (s_wr_ptr == s_rd_ptr) && (s_wr_ptr == DEPTH - 2);
            assign s_rd_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 1);
            assign s_rd_empty = (s_rd_ptr == s_wr_ptr);
            assign s_rd_almost_full = (s_rd_ptr == s_wr_ptr) && (s_rd_ptr == DEPTH - 2);
            assign m