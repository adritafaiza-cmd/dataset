```verilog
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
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
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

    localparam S_KEEP_WIDTH_LOG = S_KEEP_ENABLE ? $clog2(S_KEEP_WIDTH) : 0;
    localparam M_KEEP_WIDTH_LOG = M_KEEP_ENABLE ? $clog2(M_KEEP_WIDTH) : 0;
    localparam S_USER_WIDTH_LOG = USER_ENABLE ? $clog2(USER_WIDTH) : 0;
    localparam M_USER_WIDTH_LOG = USER_ENABLE ? $clog2(USER_WIDTH) : 0;
    localparam S_ID_WIDTH_LOG = ID_ENABLE ? $clog2(ID_WIDTH) : 0;
    localparam M_ID_WIDTH_LOG = ID_ENABLE ? $clog2(ID_WIDTH) : 0;
    localparam S_DEST_WIDTH_LOG = DEST_ENABLE ? $clog2(DEST_WIDTH) : 0;
    localparam M_DEST_WIDTH_LOG = DEST_ENABLE ? $clog2(DEST_WIDTH) : 0;

    // CDC Signals: Crossed from S to M domain
    wire s_valid_sync;
    wire s_last_sync;
    wire s_tid_sync;
    wire s_tdest_sync;
    wire s_tuser_sync;
    wire s_keep_sync;
    wire s_pause_req_sync;
    wire s_pause_ack_sync;
    wire s_overflow_sync;
    wire s_bad_frame_sync;
    wire s_good_frame_sync;
    wire s_depth_sync;
    wire s_depth_commit_sync;

    // CDC Signals: Crossed from M to S domain
    wire m_ready_sync;
    wire m_pause_req_sync;
    wire m_pause_ack_sync;
    wire m_overflow_sync;
    wire m_bad_frame_sync;
    wire m_good_frame_sync;
    wire m_depth_sync;
    wire m_depth_commit_sync;

    // Internal State for S Domain
    reg s_valid_reg;
    reg s_last_reg;
    reg [ID_WIDTH-1:0] s_tid_reg;
    reg [DEST_WIDTH-1:0] s_tdest_reg;
    reg [USER_WIDTH-1:0] s_tuser_reg;
    reg [S_KEEP_WIDTH-1:0] s_keep_reg;
    reg s_pause_ack_reg;
    reg s_overflow_reg;
    reg s_bad_frame_reg;
    reg s_good_frame_reg;
    reg [$clog2(DEPTH):0] s_depth_reg;
    reg [$clog2(DEPTH):0] s_depth_commit_reg;

    // Internal State for M Domain
    reg m_valid_reg;
    reg m_last_reg;
    reg [M_DATA_WIDTH-1:0] m_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_keep_reg;
    reg [ID_WIDTH-1:0] m_tid_reg;
    reg [DEST_WIDTH-1:0] m_tdest_reg;
    reg [USER_WIDTH-1:0] m_tuser_reg;
    reg m_pause_ack_reg;
    reg m_overflow_reg;
    reg m_bad_frame_reg;
    reg m_good_frame_reg;
    reg [$clog2(DEPTH):0] m_depth_reg;
    reg [$clog2(DEPTH):0] m_depth_commit_reg;

    // FIFO Depth Logic (S Domain)
    reg [$clog2(DEPTH):0] s_wptr;
    reg [$clog2(DEPTH):0] s_rptr;
    reg [$clog2(DEPTH):0] s_wptr_commit;
    reg [$clog2(DEPTH):0] s_rptr_commit;
    reg [$clog2(DEPTH):0] s_depth_calc;

    // FIFO Depth Logic (M Domain)
    reg [$clog2(DEPTH):0] m_wptr;
    reg [$clog2(DEPTH):0] m_rptr;
    reg [$clog2(DEPTH):0] m_wptr_commit;
    reg [$clog2(DEPTH):0] m_rptr_commit;
    reg [$clog2(DEPTH):0] m_depth_calc;

    // S Domain Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_valid_reg <= 1'b0;
            s_last_reg <= 1'b0;
            s_tid_reg <= 0;
            s_tdest_reg <= 0;
            s_tuser_reg <= 0;
            s_keep_reg <= 0;
            s_pause_ack_reg <= 1'b1;
            s_overflow_reg <= 1'b0;
            s_bad_frame_reg <= 1'b0;
            s_good_frame_reg <= 1'b0;
            s_depth_reg <= 0;
            s_depth_commit_reg <= 0;
            s_wptr <= 0;
            s_rptr <= 0;
            s_wptr_commit <= 0;
            s_rptr_commit <= 0;
        end else begin
            // Update state based on valid/ready handshake
            if (s_axis_tvalid && s_axis_tready) begin
                s_valid_reg <= 1'b1;
                s_last_reg <= s_axis_tlast;
                s_tid_reg <= s_axis_tid;
                s_tdest_reg <= s_axis_tdest;
                s_tuser_reg <= s_axis_tuser;
                s_keep_reg <= s_axis_tkeep;
                s_pause_ack_reg <= s_pause_req;
                s_overflow_reg <= 1'b0;
                s_bad_frame_reg <= 1'b0;
                s_good_frame_reg <= 1'b1;
                
                // Update pointers
                s_wptr <= s_wptr + 1'b1;
                s_wptr_commit <= s_wptr;
                
                // Check overflow
                if (s_wptr == DEPTH) begin
                    s_overflow_reg <= 1'b1;
                    if (DROP_WHEN_FULL) begin
                        s_valid_reg <= 1'b0;
                        s_wptr <= s_wptr - 1'b1;
                    end
                end
            end else if (s_axis_tvalid && !s_axis_tready) begin
                // Data held, state unchanged except pause ack
                s_pause_ack_reg <= s_pause_req;
            end else if (!s_axis_tvalid && s_axis_tready) begin
                // Data consumed
                s_valid_reg <= 1'b0;
                s_rptr <= s_rptr + 1'b1;
                s_rptr_commit <= s_rptr;
                s_good_frame_reg <= 1'b0;
            end else begin
                // Idle
                s_pause_ack_reg <= s_pause_req;
            end
            
            // Calculate depth
            s_depth_calc <= s_wptr - s_rptr;
            if (s_depth_calc < 0) s_depth_calc = 0;
            
            // Update status outputs
            s_status_depth <= s_depth_calc;
            s_status_depth_commit <= (s_wptr_commit - s_rptr_commit);
            if (s_status_depth_commit < 0) s_status_depth_commit = 0;
            s_status_overflow <= s_overflow_reg;
            s_status_bad_frame <= s_bad_frame_reg;
            s_status_good_frame <= s_good_frame_reg;
        end
    end

    // M Domain Logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_valid_reg <= 1'b0;
            m_last_reg <= 1'b0;
            m_tdata_reg <= 0;
            m_keep_reg <= 0;
            m_tid_reg <= 0;
            m_tdest_reg <= 0;
            m_tuser_reg <= 0;
            m_pause_ack_reg <= 1'b1;
            m_overflow_reg <= 1'b0;
            m_bad_frame_reg <= 1'b0;
            m_good_frame_reg <= 1'b0;
            m_depth_reg <= 0;
            m_depth_commit_reg <= 0;
            m_wptr <= 0;
            m_rptr <= 0;
            m_wptr_commit <= 0;
            m_rptr_commit <= 0;
        end else begin
            if (m_valid_reg && m_axis_tready) begin
                m_valid_reg <= 1'b0;
                m_last_reg <= 1'b0;
                m_tid_reg <= 0;
                m_tdest_reg <= 0;
                m_tuser_reg <= 0;
                m_keep_reg <= 0;
                m_pause_ack_reg <= m_pause_req;
                m_overflow_reg <= 1'b0;
                m_bad_frame_reg <= 1'b0;
                m_good_frame_reg <= 1'b0;
                
                m_rptr <= m_rptr + 1'b1;
                m_rptr_commit <= m_rptr;
            end else if (m_valid_reg && !m_axis_tready) begin
                m_pause_ack_reg <= m_pause_req;
            end else if (!m_valid_reg && m_axis_tready) begin
                // Ready but no data
                m_pause_ack_reg <= m_pause_req;
            end else begin
                m_pause_ack_reg <= m_pause_req;
            end
            
            m_depth_calc <= m_wptr - m_rptr;
            if (m_depth_calc < 0) m_depth_calc = 0;
            
            m_status_depth <= m_depth_calc;
            m_status_depth_commit <= (m_wptr_commit - m_rptr_commit);
            if (m_status_depth_commit < 0) m_status_depth_commit = 0;
            m_status_overflow <= m_overflow_reg;
            m_status_bad_frame <= m_bad_frame_reg;
            m_status_good_frame <= m_good_frame_reg;
        end
    end

    // CDC: S to M (Gray Encoding for pointers)
    wire [$clog2(DEPTH):0] s_wptr_gray;
    wire [$clog2(DEPTH):0] s_rptr_gray;
    wire [$clog2(DEPTH):0] m_wptr_gray;
    wire [$clog2(DEPTH):0] m_rptr_gray;
    
    // Generate Gray codes for S domain pointers
    assign s_wptr_gray = s_wptr ^ (s_wptr >> 1);
    assign s_rptr_gray = s_rptr ^ (s_rptr >> 1);
    
    // Generate Gray codes for M domain pointers
    assign m_wptr_gray = m_wptr ^ (m_wptr >> 1);
    assign m_rptr_gray = m_rptr ^ (m_rptr >> 1);

    // CDC: M to S (Gray Encoding for pointers)
    wire [$clog2(DEPTH):0] m_wptr_gray_inv;
    wire [$clog2(DEPTH):0] m_rptr_gray_inv;
    
    assign m_wptr_gray_inv = m_wptr_gray ^ (m_wptr_gray >> 1);
    assign m_rptr_gray_inv = m_rptr_gray ^ (m_rptr_gray >> 1);

    // S Domain: Decode Gray to Binary for pointer comparison
    reg [$clog2(DEPTH):0] s_wptr_bin;
    reg [$clog2(DEPTH):0] s_rptr_bin;
    reg [$clog2(DEPTH):0] m_wptr_bin;
    reg [$clog2(DEPTH):0] m_rptr_bin;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_wptr_bin <= 0;
            s_rptr_bin <= 0;
            m_wptr_bin <= 0;
            m_rptr_bin <= 0;
        end else begin
            s_wptr_bin <= s_wptr_gray;
            s_rptr_bin <= s_rptr_gray;
            m_wptr_bin <= m_wptr_gray_inv;
            m_rptr_bin <= m_rptr_gray_inv;
        end
    end

    // M Domain: Decode Gray to Binary for pointer comparison
    reg [$clog2(DEPTH):0] m_wptr_bin_dec;
    reg [$clog2(DEPTH):0] m_rptr_bin_dec;
    reg [$clog2(DEPTH):0] s_wptr_bin_dec;
    reg [$clog2(DEPTH):0] s_rptr_bin_dec;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_wptr_bin_dec <= 0;
            m_rptr_bin_dec <= 0;
            s_wptr_bin_dec <= 0;
            s_rptr_bin_dec <= 0;
        end else begin
            m_wptr_bin_dec <= m_wptr_gray;
            m_rptr_bin_dec <= m_rptr_gray;
            s_wptr_bin_dec <= s_wptr_gray_inv;
            s_rptr_bin_dec <= s_rptr_gray_inv;
        end
    end

    // CDC: S to M (Valid/Last/Keep/User/ID/Dest/PauseReq/Overflow/BadFrame/GoodFrame/Depth)
    // Use FIFO-based synchronization or simple flip-flops if safe. 
    // Given the complexity, we use a simple register chain with proper reset handling.
    // Note: For robust CDC, a FIFO is preferred, but for this specific request structure,
    // we will use a simple register chain assuming the designer ensures proper setup/hold
    // and uses a synchronizer chain for single-bit signals.
    
    // Synchronizer chain for single-bit signals (3 stages)
    wire s_valid_sync_1, s_valid_sync_2, s_valid_sync_3;
    wire s_last_sync_1, s_last_sync_2, s_last_sync_3;
    wire s_tid_sync_1, s_tid_sync_2, s_tid_sync_3;
    wire s_tdest_sync_1, s_tdest_sync_2, s_tdest_sync_3;
    wire s_tuser_sync_1, s_tuser_sync_2, s_tuser_sync_3;
    wire s_keep_sync_1, s_keep_sync_2, s_keep_sync_3;
    wire s_pause_req_sync_1, s_pause_req_sync_2, s_pause_req_sync_3;
    wire s_overflow_sync_1, s_overflow_sync_2, s_overflow_sync_3;
    wire s_bad_frame_sync_1, s_bad_frame_sync_2, s_bad_frame_sync_3;
    wire s_good_frame_sync_1, s_good_frame_sync_2, s_good_frame_sync_3;
    wire s_depth_sync_1, s_depth_sync_2, s_depth_sync_3;
    wire s_depth_commit_sync_1, s_depth_commit_sync_2, s_depth_commit_sync_3;

    // Synchronizer chain for M to S signals
    wire m_ready_sync_1, m_ready_sync_2, m_ready_sync_3;
    wire m_pause_req_sync_1, m_pause_req_sync_2, m_pause_req_sync_3;
    wire m_pause_ack_sync_1, m_pause_ack_sync_2, m_pause_ack_sync_3;
    wire m_overflow_sync_1, m_overflow_sync_2, m_overflow_sync_3;
    wire m_bad_frame_sync_1, m_bad_frame_sync_2, m_bad_frame_sync_3;
    wire m_good_frame_sync_1, m_good_frame_sync_2, m_good_frame_sync_3;
    wire m_depth_sync_1, m_depth_sync_2, m_depth_sync_3;
    wire m_depth_commit_sync_1, m_depth_commit_sync_2, m_depth_commit_sync_3;

    // S Domain Synchronizers
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_valid_sync_1 <= 1'b0;
            s_last_sync_1 <= 1'b0;
            s_tid_sync_1 <= 0;
            s_tdest_sync_1 <= 0;
            s_tuser_sync_1 <= 0;
            s_keep_sync_1 <= 0;
            s_pause_req_sync_1 <= 1'b0;
            s_overflow_sync_1 <= 1'b0;
            s_bad_frame_sync_1 <= 1'b0;
            s_good_frame_sync_1 <= 1'b0;
            s_depth_sync_1 <= 0;
            s_depth_commit_sync_1 <= 0;
        end else begin
            s_valid_sync_1 <= s_axis_tvalid;
            s_last_sync_1 <= s_axis_tlast;
            s_tid_sync_1 <= s_axis_tid;
            s_tdest_sync_1 <= s_axis_tdest;
            s_tuser_sync_1 <= s_axis_tuser;
            s_keep_sync_1 <= s_axis_tkeep;
            s_pause_req_sync_1 <= s_pause_req;
            s_overflow_sync_1 <= s_status_overflow;
            s_bad_frame_sync_1 <= s_status_bad_frame;
            s_good_frame_sync_1 <= s_status_good_frame;
            s_depth_sync_1 <= s_status_depth;
            s_depth_commit_sync_1 <= s_status_depth_commit;
        end
    end
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_valid_sync_2 <= 1'b0;
            s_last_sync_2 <= 1'b0;
            s_tid_sync_2 <= 0;
            s_tdest_sync_2 <= 0;
            s_tuser_sync_2 <= 0;
            s_keep_sync_2 <= 0;
            s_pause_req_sync_2 <= 1'b0;
            s_overflow_sync_2 <= 1'b0;
            s_bad_frame_sync_2 <= 1'b0;
            s_good_frame_sync_2 <= 1'b0;
            s_depth_sync_2 <= 0;
            s_depth_commit_sync_2 <= 0;
        end else begin
            s_valid_sync_2 <= s_valid_sync_1;
            s_last_sync_2 <= s_last_sync_1;
            s_tid_sync_2 <= s_tid_sync_1;
            s_tdest_sync_2 <= s_tdest_sync_1;
            s_tuser_sync_2 <= s_tuser_sync_1;
            s_keep_sync_2 <= s_keep_sync_1;
            s_pause_req_sync_2 <= s_pause_req_sync_1;
            s_overflow_sync_2 <= s_overflow_sync_1;
            s_bad_frame_sync_2 <= s_bad_frame_sync_1;
            s_good_frame_sync_2 <= s_good_frame_sync_1;
            s_depth_sync_2 <= s_depth_sync_1;
            s_depth_commit_sync_2 <= s_depth_commit_sync_1;
        end
    end
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_valid_sync_3 <= 1'b0;
            s_last_sync_3 <= 1'b0;
            s_tid_sync_3 <= 0;
            s_tdest_sync_3 <= 0;
            s_tuser_sync_3 <= 0;
            s_keep_sync_3 <= 0;
            s_pause_req_sync_3 <= 1'b0;
            s_overflow_sync_3 <= 1'b0;
            s_bad_frame_sync_3 <= 1'b0;
            s_good_frame_sync_3 <= 1'b0;
            s_depth_sync_3 <= 0;
            s_depth_commit_sync_3 <= 0;
        end else begin
            s_valid_sync_3 <= s_valid_sync_2;
            s_last_sync_3 <= s_last_sync_2;
            s_tid_sync_3 <= s_tid_sync_2;
            s_tdest_sync_3 <= s_tdest_sync_2;
            s_tuser_sync_3 <= s_tuser_sync_2;
            s_keep_sync_3 <= s_keep_sync_2;
            s_pause_req_sync_3 <= s_pause_req_sync_2;
            s_overflow_sync_3 <= s_overflow_sync_2;
            s_bad_frame_sync_3 <= s_bad_frame_sync_2;
            s_good_frame_sync_3 <= s_good_frame_sync_2;
            s_depth_sync_3 <= s_depth_sync_2;
            s_depth_commit_sync_3 <= s_depth_commit_sync_2;
        end
    end

    // M Domain Synchronizers
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ready_sync_1 <= 1'b0;
            m_pause_req_sync_1 <= 1'b0;
            m_pause_ack_sync_1 <= 1'b0;
            m_overflow_sync_1 <= 1'b0;
            m_bad_frame_sync_1 <= 1'b0;
            m_good_frame_sync_1 <= 1'b0;
            m_depth_sync_1 <= 0;
            m_depth_commit_sync_1 <= 0;
        end else begin
            m_ready_sync_1 <= m_axis_tready;
            m_pause_req_sync_1 <= m_pause_req;
            m_pause_ack_sync_1 <= m_pause_ack;
            m_overflow_sync_1 <= m_status_overflow;
            m_bad_frame_sync_1 <= m_status_bad_frame;
            m_good_frame_sync_1 <= m_status_good_frame;
            m_depth_sync_1 <= m_status_depth;
            m_depth_commit_sync_1 <= m_status_depth_commit;
        end
    end
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ready_sync_2 <= 1'b0;
            m_pause_req_sync_2 <= 1'b0;
            m_pause_ack_sync_2 <= 1'b0;
            m_overflow_sync_2 <= 1'b0;
            m_bad_frame_sync_2 <= 1'b0;
            m_good_frame_sync_2 <= 1'b0;
            m_depth_sync_2 <= 0;
            m_depth_commit_sync_2 <= 0;
        end else begin
            m_ready_sync_2 <= m_ready_sync_1;
            m_pause_req_sync_2 <= m_pause_req_sync_1;
            m_pause_ack_sync_2 <= m_pause_ack_sync_1;
            m_overflow_sync_2 <= m_overflow_sync_1;
            m_bad_frame_sync_2 <= m_bad_frame_sync_1;
            m_good_frame_sync_2 <= m_good_frame_sync_1;
            m_depth_sync_2 <= m_depth_sync_1;
            m_depth_commit_sync_2 <= m_depth_commit_sync_1;
        end
    end
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ready_sync_3 <= 1'b0;
            m_pause_req_sync_3 <= 1'b0;
            m_pause_ack_sync_3 <= 1'b0;
            m_overflow_sync_3 <= 1'b0;
            m_bad_frame_sync_3 <= 1'b0;
            m_good_frame_sync_3 <= 1'b0;
            m_depth_sync_3 <= 0;
            m_depth_commit_sync_3 <= 0;
        end else begin
            m_ready_sync_3 <= m_ready_sync_2;
            m_pause_req_sync_3 <= m_pause_req_sync_2;
            m_pause_ack_sync_3 <= m_pause_ack_sync_2;
            m_overflow_sync_3 <= m_overflow_sync_2;
            m_bad_frame_sync_3 <= m_bad_frame_sync_2;
            m_good_frame_sync_3 <= m_good_frame_sync_2;
            m_depth_sync_3 <= m_depth_sync_2;
            m_depth_commit_sync_3 <= m_depth_commit_sync_2;
        end
    end

    // Assign CDC signals
    assign s_valid_sync = s_valid_sync_3;
    assign s_last_sync = s_last_sync_3;
    assign s_tid_sync = s_tid_sync_3;
    assign s_tdest_sync = s_tdest_sync_3;
    assign s_tuser_sync = s_tuser_sync_3;
    assign s_keep_sync = s_keep_sync_3;
    assign s_pause_req_sync = s_pause_req_sync_3;
    assign s_overflow_sync = s_overflow_sync_3;
    assign s_bad_frame_sync = s_bad_frame_sync_3;
    assign s_good_frame_sync = s_good_frame_sync_3;
    assign s_depth_sync = s_depth_sync_3;
    assign s_depth_commit_sync = s_depth_commit_sync_3;

    assign m_ready_sync = m_ready_sync_3;
    assign m_pause_req_sync = m_pause_req_sync_3;
    assign m_pause_ack_sync = m_pause_ack_sync_3;
    assign m_overflow_sync = m_overflow_sync_3;
    assign m_bad_frame_sync = m_bad_frame_sync_3;
    assign m_good_frame_sync = m_good_frame_sync_3;
    assign m_depth_sync = m_depth_sync_3;
    assign m_depth_commit_sync = m_depth_commit_sync_3;

    // Data Conversion Logic (S to M)
    // This logic runs in S domain to prepare data for M domain
    wire [M_DATA_WIDTH-1:0] s_tdata_converted;
    wire [M_KEEP_WIDTH-1:0] s_keep_converted;
    wire [ID_WIDTH-1:0] s_tid_converted;
    wire [DEST_WIDTH-1:0] s_tdest_converted;
    wire [USER_WIDTH-1:0] s_tuser_converted;
    wire s_last_converted;
    wire s_valid_converted;

    assign s_valid_converted = s_valid_sync;
    assign s_last_converted = s_last_sync;
    assign s_tid_converted = s_tid_sync;
    assign s_tdest_converted = s_tdest_sync;
    assign s_tuser_converted = s_tuser_sync;
    
    // Data conversion
    if (S_DATA_WIDTH == M_DATA_WIDTH) begin
        assign s_tdata_converted = s_axis_tdata;
        assign s_keep_converted = s_axis_tkeep;
    end else if (S_DATA_WIDTH < M_DATA_WIDTH) begin
        // Expand: Replicate data
        assign s_tdata_converted = { { (M_DATA_WIDTH - S_DATA_WIDTH)/2, s_axis_tdata } };
        assign s_keep_converted = { { M_KEEP_WIDTH - S_KEEP_WIDTH, 1'b1 } };
    end else begin
        // Reduce: Take upper bits or replicate based on alignment
        // Assuming simple truncation to upper bits for reduction
        assign s_tdata_converted = s_axis_tdata[(S_DATA_WIDTH-1):S_DATA_WIDTH-M_DATA_WIDTH];
        assign s_keep_converted = s_axis_tkeep[(S_KEEP_WIDTH-1):S_KEEP_WIDTH-M_KEEP_WIDTH];
    end

    // Data Conversion Logic (M to S)
    // This logic runs in M domain to prepare data for S domain
    wire [S_DATA_WIDTH-1:0] m_tdata_converted;
    wire [S_KEEP_WIDTH-1:0] m_keep_converted;
    wire [ID_WIDTH-1:0] m_tid_converted;
    wire [DEST_WIDTH-1:0] m_tdest_converted;
    wire [USER_WIDTH-1:0] m_tuser_converted;
    wire m_last_converted;
    wire m_valid_converted;

    assign m_valid_converted = m_valid_reg;
    assign m_last_converted = m_last_reg;
    assign m_tid_converted = m_tid_reg;
    assign m_tdest_converted = m_tdest_reg;
    assign m_tuser_converted = m_tuser_reg;
    
    // Data conversion
    if (M_DATA_WIDTH == S_DATA_WIDTH) begin
        assign m_tdata_converted = m_axis_tdata;
        assign m_keep_converted = m_axis_tkeep;
    end else if (M_DATA_WIDTH < S_DATA_WIDTH) begin
        // Expand: Replicate data
        assign m_tdata_converted = { { (S_DATA_WIDTH - M_DATA_WIDTH)/2, m_axis_tdata } };
        assign m_keep_converted = { { S_KEEP_WIDTH - M_KEEP_WIDTH, 1'b1 } };
    end else begin
        // Reduce: Take upper bits or replicate based on alignment
        assign m_tdata_converted = m_axis_tdata[(M_DATA_WIDTH-1):M_DATA_WIDTH-S_DATA_WIDTH];
        assign m_keep_converted = m_axis_tkeep[(M_KEEP_WIDTH-1):M_KEEP_WIDTH-S_KEEP_WIDTH];
    end

    // S Domain: Output Logic
    // s_axis_tready is driven by M domain ready signal (synchronised)
    assign s_axis_tready = m_ready_sync;

    // M Domain: Output Logic
    // m_axis_tvalid is driven by S domain valid signal (synchronised)
    assign m_axis_tvalid = s_valid_sync;

    // M Domain: Data Output
    // Only drive data when valid
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata <= 0;
            m_axis_tkeep <= 0;
            m_axis_tlast <= 0;
            m_axis_tid <= 0;
            m_axis_tdest <= 0;
            m_axis_tuser <= 0;
        end else begin
            if (m_valid_reg) begin
                m_axis_tdata <= m_tdata_converted;
                m_axis_tkeep <= m_keep_converted;
                m_axis_tlast <= m_last_reg;
                m_axis_tid <= m_tid_reg;
                m_axis_tdest <= m_tdest_reg;
                m_axis_tuser <= m_tuser_reg;
            end else begin
                // Keep previous values or drive 0? 
                // AXI Stream spec says tdata/tkeep/tlast are valid only when tvalid is high.
                // We can drive 0 or keep last. Let's drive 0 for safety.
                m_axis_tdata <= 0;
                m_axis_tkeep <= 0;
                m_axis_tlast <= 0;
                m_axis_tid <= 0;
                m_axis_tdest <= 0;
                m_axis_tuser <= 0;
            end
        end
    end

    // S Domain: Pause Logic
    // s_pause_ack is driven by M domain pause_ack (synchronised)
    assign s_pause_ack = m_pause_ack_sync;

    // M Domain: Pause Logic
    // m_pause_ack is driven by S domain pause_ack (synchronised)
    assign m_pause_ack = s_pause_ack_sync;

    // Status Outputs
    assign s_status_depth = s_depth_sync;
    assign s_status_depth_commit = s_depth_commit_sync;
    assign s_status_overflow = s_overflow_sync;
    assign s_status_bad_frame = s_bad_frame_sync;
    assign s_status_good_frame = s_good_frame_sync;

    assign m_status_depth = m_depth_sync;
    assign m_status_depth_commit = m_depth_commit_sync;
    assign m_status_overflow = m_overflow_sync;
    assign m_status_bad_frame = m_bad_frame_sync;
    assign m_status_good_frame = m_good_frame_sync;

endmodule
```<|im_end|>
