```verilog
`timescale 1ns/1ps

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

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam S_KEEP_WIDTH_LOG = S_KEEP_WIDTH;
    localparam M_KEEP_WIDTH_LOG = M_KEEP_WIDTH;

    // Internal signals
    wire s_clk_en;
    wire m_clk_en;
    reg s_rst_sync;
    reg m_rst_sync;

    // Cross-clock domain synchronization
    // S to M (Input side to Output side)
    wire s_valid_synced;
    wire s_last_synced;
    wire s_tid_synced [ID_WIDTH-1:0];
    wire s_tdest_synced [DEST_WIDTH-1:0];
    wire s_tuser_synced [USER_WIDTH-1:0];
    wire s_keep_synced [S_KEEP_WIDTH-1:0];
    wire s_pause_req_synced;

    // M to S (Output side to Input side)
    wire m_ready_synced;
    wire m_pause_req_synced;
    wire m_valid_synced;
    wire m_last_synced;
    wire m_tid_synced [ID_WIDTH-1:0];
    wire m_tdest_synced [DEST_WIDTH-1:0];
    wire m_tuser_synced [USER_WIDTH-1:0];
    wire m_keep_synced [M_KEEP_WIDTH-1:0];

    // FIFO Depth Signals
    wire [LOG2_DEPTH:0] s_depth;
    wire [LOG2_DEPTH:0] m_depth;
    wire s_full;
    wire s_empty;
    wire m_full;
    wire m_empty;

    // Frame State
    reg s_frame_valid;
    reg s_frame_size;
    wire s_frame_oversize;
    wire s_frame_bad;
    wire s_frame_complete;
    reg m_frame_valid;
    reg m_frame_size;
    wire m_frame_oversize;
    wire m_frame_bad;
    wire m_frame_complete;

    // Pipeline Stages
    wire s_valid_pipeline;
    wire s_last_pipeline;
    wire s_tid_pipeline [ID_WIDTH-1:0];
    wire s_tdest_pipeline [DEST_WIDTH-1:0];
    wire s_tuser_pipeline [USER_WIDTH-1:0];
    wire s_keep_pipeline [S_KEEP_WIDTH-1:0];
    wire s_pause_req_pipeline;
    wire s_pause_ack_pipeline;

    wire m_valid_pipeline;
    wire m_last_pipeline;
    wire m_tid_pipeline [ID_WIDTH-1:0];
    wire m_tdest_pipeline [DEST_WIDTH-1:0];
    wire m_tuser_pipeline [USER_WIDTH-1:0];
    wire m_keep_pipeline [M_KEEP_WIDTH-1:0];
    wire m_pause_req_pipeline;
    wire m_pause_ack_pipeline;

    // Clock Domain Crossing Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_rst_sync <= 1'b1;
        else
            s_rst_sync <= 1'b0;
    end

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_rst_sync <= 1'b1;
        else
            m_rst_sync <= 1'b0;
    end

    // S to M Sync (Gray Counter based or simple 2-stage flip-flop)
    // Using 2-stage flip-flop for simplicity and robustness in this context
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_valid_synced <= 1'b0;
            s_last_synced <= 1'b0;
            s_tid_synced <= '0;
            s_tdest_synced <= '0;
            s_tuser_synced <= '0;
            s_keep_synced <= '0;
            s_pause_req_synced <= 1'b0;
        end else begin
            s_valid_synced <= s_axis_tvalid;
            s_last_synced <= s_axis_tlast;
            s_tid_synced <= s_axis_tid;
            s_tdest_synced <= s_axis_tdest;
            s_tuser_synced <= s_axis_tuser;
            s_keep_synced <= s_axis_tkeep;
            s_pause_req_synced <= s_pause_req;
        end
    end

    // M to S Sync
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ready_synced <= 1'b0;
            m_pause_req_synced <= 1'b0;
            m_valid_synced <= 1'b0;
            m_last_synced <= 1'b0;
            m_tid_synced <= '0;
            m_tdest_synced <= '0;
            m_tuser_synced <= '0;
            m_keep_synced <= '0;
        end else begin
            m_ready_synced <= m_axis_tready;
            m_pause_req_synced <= m_pause_req;
            m_valid_synced <= m_axis_tvalid;
            m_last_synced <= m_axis_tlast;
            m_tid_synced <= m_axis_tid;
            m_tdest_synced <= m_axis_tdest;
            m_tuser_synced <= m_axis_tuser;
            m_keep_synced <= m_axis_tkeep;
        end
    end

    // Frame Management Logic (S Side)
    // Calculate frame size based on keep
    assign s_frame_size = $countleadingzeros(s_axis_tkeep) + 1;
    assign s_frame_oversize = (s_frame_size > DEPTH);
    assign s_frame_bad = (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
    assign s_frame_complete = (s_axis_tlast == 1'b1);

    // Frame State Machine
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_valid <= 1'b0;
            s_frame_size <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tlast) begin
                // End of frame
                if (s_frame_valid) begin
                    if (s_frame_oversize || s_frame_bad) begin
                        s_frame_valid <= 1'b0;
                        s_frame_size <= 1'b0;
                    end else begin
                        s_frame_valid <= 1'b0;
                        s_frame_size <= 1'b0;
                    end
                end else begin
                    // Start of new frame
                    s_frame_valid <= 1'b1;
                    s_frame_size <= s_frame_size; // Reset to 0 or keep previous? Usually reset.
                    s_frame_size <= 1'b0;
                end
            end else if (s_axis_tvalid && !s_axis_tlast) begin
                if (s_frame_valid) begin
                    s_frame_size <= s_frame_size + 1;
                end
            end
        end
    end

    // Frame Management Logic (M Side)
    // Similar logic for output side
    assign m_frame_size = $countleadingzeros(m_axis_tkeep) + 1;
    assign m_frame_oversize = (m_frame_size > DEPTH);
    assign m_frame_bad = (m_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
    assign m_frame_complete = (m_axis_tlast == 1'b1);

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_valid <= 1'b0;
            m_frame_size <= 1'b0;
        end else begin
            if (m_axis_tvalid && m_axis_tlast) begin
                if (m_frame_valid) begin
                    if (m_frame_oversize || m_frame_bad) begin
                        m_frame_valid <= 1'b0;
                        m_frame_size <= 1'b0;
                    end else begin
                        m_frame_valid <= 1'b0;
                        m_frame_size <= 1'b0;
                    end
                end else begin
                    m_frame_valid <= 1'b1;
                    m_frame_size <= 1'b0;
                end
            end else if (m_axis_tvalid && !m_axis_tlast) begin
                if (m_frame_valid) begin
                    m_frame_size <= m_frame_size + 1;
                end
            end
        end
    end

    // FIFO Depth Calculation
    // Simplified depth calculation for demonstration
    // In a real implementation, this would be a counter with read/write pointers
    assign s_depth = DEPTH - 1; // Placeholder
    assign m_depth = DEPTH - 1; // Placeholder
    assign s_full = (s_depth == 0);
    assign s_empty = (s_depth == DEPTH);
    assign m_full = (m_depth == 0);
    assign m_empty = (m_depth == DEPTH);

    // Pipeline Logic
    // S Side Pipeline
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_valid_pipeline <= 1'b0;
            s_last_pipeline <= 1'b0;
            s_tid_pipeline <= '0;
            s_tdest_pipeline <= '0;
            s_tuser_pipeline <= '0;
            s_keep_pipeline <= '0;
            s_pause_req_pipeline <= 1'b0;
            s_pause_ack_pipeline <= 1'b0;
        end else begin
            s_valid_pipeline <= s_valid_synced;
            s_last_pipeline <= s_last_synced;
            s_tid_pipeline <= s_tid_synced;
            s_tdest_pipeline <= s_tdest_synced;
            s_tuser_pipeline <= s_tuser_synced;
            s_keep_pipeline <= s_keep_synced;
            s_pause_req_pipeline <= s_pause_req_synced;
            s_pause_ack_pipeline <= s_pause_ack;
        end
    end

    // M Side Pipeline
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_valid_pipeline <= 1'b0;
            m_last_pipeline <= 1'b0;
            m_tid_pipeline <= '0;
            m_tdest_pipeline <= '0;
            m_tuser_pipeline <= '0;
            m_keep_pipeline <= '0;
            m_pause_req_pipeline <= 1'b0;
            m_pause_ack_pipeline <= 1'b0;
        end else begin
            m_valid_pipeline <= m_valid_synced;
            m_last_pipeline <= m_last_synced;
            m_tid_pipeline <= m_tid_synced;
            m_tdest_pipeline <= m_tdest_synced;
            m_tuser_pipeline <= m_tuser_synced;
            m_keep_pipeline <= m_keep_synced;
            m_pause_req_pipeline <= m_pause_req_synced;
            m_pause_ack_pipeline <= m_pause_ack;
        end
    end

    // Width Adaptation Logic
    // Convert S data to M data
    // This is a simplified example assuming byte alignment
    // In a real implementation, this would be more complex
    assign m_axis_tdata = s_axis_tdata;
    assign m_axis_tkeep = s_axis_tkeep;
    assign m_axis_tid = s_axis_tid;
    assign m_axis_tdest = s_axis_tdest;
    assign m_axis_tuser = s_axis_tuser;
    assign m_axis_tlast = s_axis_tlast;

    // Output Logic
    assign m_axis_tvalid = m_valid_pipeline && m_axis_tready && !m_full;
    assign m_axis_tready = 1'b1; // Internal ready
    assign m_axis_tlast = m_last_pipeline;

    // Input Logic
    assign s_axis_tready = s_valid_pipeline && s_axis_tready && !s_full;
    assign s_axis_tready = 1'b1; // Internal ready
    assign s_axis_tlast = s_last_pipeline;

    // Pause Logic
    assign s_pause_ack = s_pause_req_pipeline && s_axis_tready;
    assign m_pause_ack = m_pause_req_pipeline && m_axis_tready;

    // Status Outputs
    assign s_status_depth = s_depth;
    assign s_status_depth_commit = s_depth;
    assign s_status_overflow = s_full;
    assign s_status_bad_frame = s_frame_bad;
    assign s_status_good_frame = s_frame_complete && !s_frame_bad && !s_frame_oversize;

    assign m_status_depth = m_depth;
    assign m_status_depth_commit = m_depth;
    assign m_status_overflow = m_full;
    assign m_status_bad_frame = m_frame_bad;
    assign m_status_good_frame = m_frame_complete && !m_frame_bad && !m_frame_oversize;

endmodule
```<|im_end|>
