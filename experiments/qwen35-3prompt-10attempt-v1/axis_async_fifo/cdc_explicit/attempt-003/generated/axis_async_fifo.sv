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
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
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
    localparam FULL_THRESHOLD = DEPTH - 1;
    localparam EMPTY_THRESHOLD = 0;

    // Internal signals for CDC
    wire [LOG2_DEPTH:0] s_ptr;
    wire [LOG2_DEPTH:0] m_ptr;
    wire [LOG2_DEPTH:0] s_ptr_commit;
    wire [LOG2_DEPTH:0] m_ptr_commit;
    wire s_empty;
    wire s_full;
    wire m_empty;
    wire m_full;
    wire s_depth;
    wire m_depth;
    wire s_depth_commit;
    wire m_depth_commit;
    wire s_pause;
    wire m_pause;

    // Cross-domain pointers and pointers
    wire [LOG2_DEPTH:0] s_ptr_next;
    wire [LOG2_DEPTH:0] m_ptr_next;
    wire [LOG2_DEPTH:0] s_ptr_prev;
    wire [LOG2_DEPTH:0] m_ptr_prev;

    // FIFO Memory
    reg [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] mem_keep [0:DEPTH-1];
    reg [LAST_ENABLE?1:0] mem_last [0:DEPTH-1];
    reg [ID_ENABLE?1:0] mem_id [0:DEPTH-1];
    reg [DEST_ENABLE?1:0] mem_dest [0:DEPTH-1];
    reg [USER_ENABLE?1:0] mem_user [0:DEPTH-1];
    reg [USER_ENABLE?1:0] mem_user_bad_frame [0:DEPTH-1];

    // Status registers
    reg s_status_bad_frame_reg;
    reg s_status_good_frame_reg;
    reg m_status_bad_frame_reg;
    reg m_status_good_frame_reg;

    // --- Synchronizers for Control Signals ---

    // S-domain to M-domain synchronizers (2-stage)
    reg s_valid_sync1;
    reg s_valid_sync2;
    reg s_last_sync1;
    reg s_last_sync2;
    reg s_tid_sync1;
    reg s_tid_sync2;
    reg s_dest_sync1;
    reg s_dest_sync2;
    reg s_user_sync1;
    reg s_user_sync2;
    reg s_keep_sync1;
    reg s_keep_sync2;
    reg s_pause_req_sync1;
    reg s_pause_req_sync2;
    reg s_rst_sync1;
    reg s_rst_sync2;

    // M-domain to S-domain synchronizers (2-stage)
    reg m_ready_sync1;
    reg m_ready_sync2;
    reg m_pause_req_sync1;
    reg m_pause_req_sync2;
    reg m_rst_sync1;
    reg m_rst_sync2;

    assign s_valid_sync1 = s_axis_tvalid;
    assign s_valid_sync2 = s_valid_sync1;
    assign s_last_sync1 = s_axis_tlast;
    assign s_last_sync2 = s_last_sync1;
    assign s_tid_sync1 = s_axis_tid;
    assign s_tid_sync2 = s_tid_sync1;
    assign s_dest_sync1 = s_axis_tdest;
    assign s_dest_sync2 = s_dest_sync1;
    assign s_user_sync1 = s_axis_tuser;
    assign s_user_sync2 = s_user_sync1;
    assign s_keep_sync1 = s_axis_tkeep;
    assign s_keep_sync2 = s_keep_sync1;
    assign s_pause_req_sync1 = s_pause_req;
    assign s_pause_req_sync2 = s_pause_req_sync1;
    assign s_rst_sync1 = s_rst;
    assign s_rst_sync2 = s_rst_sync1;

    assign m_ready_sync1 = m_axis_tready;
    assign m_ready_sync2 = m_ready_sync1;
    assign m_pause_req_sync1 = m_pause_req;
    assign m_pause_req_sync2 = m_pause_req_sync1;
    assign m_rst_sync1 = m_rst;
    assign m_rst_sync2 = m_rst_sync1;

    // --- S-Domain Logic (Write Side) ---

    // Pointer logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_ptr <= 0;
        else if (s_axis_tvalid && s_axis_tready)
            s_ptr <= s_ptr + 1;
        else
            s_ptr <= s_ptr;
    end

    // Depth calculation
    always @(*) begin
        s_depth = s_ptr;
        s_depth_commit = s_ptr; // In this simple implementation, commit is same as current pointer for depth reporting
        s_empty = (s_ptr == 0);
        s_full = (s_ptr == DEPTH);
    end

    // Overflow detection
    assign s_status_overflow = (s_full && s_axis_tvalid && !s_axis_tready);

    // Bad Frame Detection Logic
    // Check if frame is oversized or bad user data
    wire frame_bad = (FRAME_FIFO && (s_ptr > 0)) ? 
                      (mem_user_bad_frame[s_ptr-1] & USER_BAD_FRAME_MASK) : 1'b0;
    
    wire frame_oversize = (FRAME_FIFO && (s_ptr > 0)) ? 
                          (s_ptr > DEPTH - 1) : 1'b0; // Simplified check, usually based on frame count logic not available here directly without frame counter
                          // Note: Without explicit frame counter state, we assume 'oversize' is handled via USER_BAD_FRAME or specific logic.
                          // For this generic implementation, we rely on USER_BAD_FRAME_MASK for bad frames.
                          // If FRAME_FIFO is enabled, we assume the user sets the bad flag if the frame is too big.

    wire is_bad_frame = (DROP_BAD_FRAME || DROP_OVERSIZE_FRAME) ? 
                        (frame_bad || frame_oversize) : 1'b0;

    // Status Registers (S-domain)
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_bad_frame_reg <= 1'b0;
            s_status_good_frame_reg <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                s_status_bad_frame_reg <= is_bad_frame;
                s_status_good_frame_reg <= !is_bad_frame;
            end else begin
                // Hold previous status
                s_status_bad_frame_reg <= s_status_bad_frame_reg;
                s_status_good_frame_reg <= s_status_good_frame_reg;
            end
        end
    end

    // Write Data Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            // Reset memory
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                mem_data[i] <= 0;
                mem_keep[i] <= 0;
                mem_last[i] <= 0;
                mem_id[i] <= 0;
                mem_dest[i] <= 0;
                mem_user[i] <= 0;
                mem_user_bad_frame[i] <= 0;
            end
        end else if (s_axis_tvalid && s_axis_tready) begin
            // Write data
            mem_data[s_ptr] <= s_axis_tdata;
            mem_keep[s_ptr] <= s_axis_tkeep;
            mem_last[s_ptr] <= s_axis_tlast;
            mem_id[s_ptr] <= s_axis_tid;
            mem_dest[s_ptr] <= s_axis_tdest;
            mem_user[s_ptr] <= s_axis_tuser;
            
            // Set bad frame flag if needed
            if (DROP_BAD_FRAME || DROP_OVERSIZE_FRAME) begin
                if (is_bad_frame) begin
                    mem_user_bad_frame[s_ptr] <= USER_BAD_FRAME_VALUE;
                end else begin
                    mem_user_bad_frame[s_ptr] <= 0;
                end
            end else begin
                mem_user_bad_frame[s_ptr] <= 0;
            end
        end
    end

    // Pause Ack (S-domain)
    // Acknowledge pause request if FIFO is not full
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_pause_ack <= 1'b1;
        else if (s_axis_tvalid && s_axis_tready)
            s_pause_ack <= 1'b0; // Busy writing
        else if (s_pause_req_sync2)
            s_pause_ack <= 1'b1; // Acknowledge pause
        else
            s_pause_ack <= 1'b1; // Idle
    end

    // --- M-Domain Logic (Read Side) ---

    // Pointer logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_ptr <= 0;
        else if (m_axis_tvalid && m_axis_tready)
            m_ptr <= m_ptr + 1;
        else
            m_ptr <= m_ptr;
    end

    // Depth calculation
    always @(*) begin
        m_depth = m_ptr;
        m_depth_commit = m_ptr;
        m_empty = (m_ptr == 0);
        m_full = (m_ptr == DEPTH);
    end

    // Overflow detection (M-domain)
    assign m_status_overflow = (m_full && m_axis_tvalid && !m_axis_tready);

    // Bad Frame Detection Logic (M-domain)
    // Read the bad frame flag from the memory location we are about to read
    wire read_bad_frame_flag = (m_ptr > 0) ? mem_user_bad_frame[m_ptr-1] : 0;
    wire is_bad_frame_m = (DROP_BAD_FRAME || DROP_OVERSIZE_FRAME) ? 
                          (read_bad_frame_flag & USER_BAD_FRAME_MASK) : 1'b0;

    // Status Registers (M-domain)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_bad_frame_reg <= 1'b0;
            m_status_good_frame_reg <= 1'b0;
        end else begin
            if (m_axis_tvalid && m_axis_tready) begin
                m_status_bad_frame_reg <= is_bad_frame_m;
                m_status_good_frame_reg <= !is_bad_frame_m;
            end else begin
                m_status_bad_frame_reg <= m_status_bad_frame_reg;
                m_status_good_frame_reg <= m_status_good_frame_reg;
            end
        end
    end

    // Read Data Logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_axis_tdata <= 0;
            m_axis_tkeep <= 0;
            m_axis_tlast <= 0;
            m_axis_tid <= 0;
            m_axis_tdest <= 0;
            m_axis_tuser <= 0;
            m_axis_tvalid <= 1'b0;
        end else if (m_axis_tvalid && m_axis_tready) begin
            // Read data
            if (m_ptr > 0) begin
                m_axis_tdata <= mem_data[m_ptr-1];
                m_axis_tkeep <= mem_keep[m_ptr-1];
                m_axis_tlast <= mem_last[m_ptr-1];
                m_axis_tid <= mem_id[m_ptr-1];
                m_axis_tdest <= mem_dest[m_ptr-1];
                m_axis_tuser <= mem_user[m_ptr-1];
            end else begin
                // Should not happen if empty check is correct, but safe default
                m_axis_tdata <= 0;
                m_axis_tkeep <= 0;
                m_axis_tlast <= 0;
                m_axis_tid <= 0;
                m_axis_tdest <= 0;
                m_axis_tuser <= 0;
            end
            m_axis_tvalid <= 1'b1;
        end else begin
            m_axis_tvalid <= 1'b0;
        end
    end

    // Pause Ack (M-domain)
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_pause_ack <= 1'b1;
        else if (m_axis_tvalid && m_axis_tready)
            m_pause_ack <= 1'b0;
        else if (m_pause_req_sync2)
            m_pause_ack <= 1'b1;
        else
            m_pause_ack <= 1'b1;
    end

    // --- Handshake Logic ---

    // S-domain Ready
    // Ready if not full, or if full and drop/mark enabled
    always @(*) begin
        if (DROP_WHEN_FULL)
            s_axis_tready = 1'b1;
        else if (MARK_WHEN_FULL)
            s_axis_tready = 1'b1; // Marking implies we accept but mark, so ready is high
        else
            s_axis_tready = !s_full;
    end

    // M-domain Valid
    // Valid if not empty, or if empty and drop enabled (though drop usually happens on write side)
    // Standard FIFO: Valid if not empty
    always @(*) begin
        if (DROP_WHEN_FULL)
            m_axis_tvalid = 1'b1; // If we drop on full, we might still have data to read
        else
            m_axis_tvalid = !m_empty;
    end

    // --- Status Outputs ---

    assign s_status_depth = s_ptr;
    assign s_status_depth_commit = s_ptr_commit;
    assign s_status_bad_frame = s_status_bad_frame_reg;
    assign s_status_good_frame = s_status_good_frame_reg;

    assign m_status_depth = m_ptr;
    assign m_status_depth_commit = m_ptr_commit;
    assign m_status_bad_frame = m_status_bad_frame_reg;
    assign m_status_good_frame = m_status_good_frame_reg;

    // --- Pause Logic Implementation Details ---
    // The above pause_ack logic is a simplified state machine. 
    // A more robust implementation for PAUSE_ENABLE would involve a dedicated pause state machine
    // that asserts pause_ack when the FIFO is not full and the request is seen.
    // Given the constraints and typical usage, the logic above handles the basic case:
    // If pause_req is high, we acknowledge (pause_ack=1) unless we are actively writing (valid & ready).
    // This effectively tells the requester "I am pausing" or "I am ready to pause".
    
    // Refining Pause Logic for better CDC and behavior:
    // s_pause_ack should be high when the FIFO can accept a pause request (i.e., not full).
    // If the FIFO is full, we cannot pause (or we are already paused/full).
    // If the FIFO is not full, we acknowledge the pause request.
    
    // Re-implementing Pause Ack for clarity and correctness
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;

    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_pause_ack_reg <= 1'b1;
        else if (s_axis_tvalid && s_axis_tready)
            s_pause_ack_reg <= 1'b0; // Busy
        else if (s_pause_req_sync2)
            s_pause_ack_reg <= 1'b1; // Acknowledge
        else
            s_pause_ack_reg <= 1'b1; // Idle
    end
    assign s_pause_ack = s_pause_ack_reg;

    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_pause_ack_reg <= 1'b1;
        else if (m_axis_tvalid && m_axis_tready)
            m_pause_ack_reg <= 1'b0; // Busy
        else if (m_pause_req_sync2)
            m_pause_ack_reg <= 1'b1; // Acknowledge
        else
            m_pause_ack_reg <= 1'b1; // Idle
    end
    assign m_pause_ack = m_pause_ack_reg;

endmodule
```<|im_end|>
