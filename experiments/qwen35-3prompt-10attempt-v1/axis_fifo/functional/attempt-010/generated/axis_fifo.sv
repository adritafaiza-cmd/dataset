```verilog
`timescale 1ns/1ps

module axis_fifo #
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
    input  wire                   clk,
    input  wire                   rst,
    /*
     * AXI input
     */
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
    input  wire                   pause_req,
    output wire                   pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam MAX_DEPTH = 2**LOG2_DEPTH;

    // Internal signals for AXI-Stream handshake
    wire s_axis_tready_internal;
    wire m_axis_tvalid_internal;

    // State Machine for Frame Handling
    typedef enum logic [1:0] {
        STATE_IDLE,
        STATE_READING,
        STATE_WRITING,
        STATE_FRAME_END
    } fsm_state_t;

    fsm_state_t fsm_state, fsm_state_next;

    // Frame State
    logic frame_active;
    logic frame_complete;
    logic frame_oversize;
    logic frame_bad;
    logic frame_pause_requested;

    // FIFO Depth Logic
    logic [LOG2_DEPTH-1:0] write_ptr, read_ptr;
    logic [LOG2_DEPTH-1:0] write_ptr_commit, read_ptr_commit;
    logic [LOG2_DEPTH-1:0] depth;
    logic [LOG2_DEPTH-1:0] depth_commit;
    logic write_enable;
    logic read_enable;
    logic full;
    logic empty;

    // Data Storage
    // We store one word per beat. If FRAME_FIFO is enabled, we might need to handle multi-beat frames.
    // However, the prompt asks for a "Single-clock AXI-Stream FIFO". 
    // Standard AXI-Stream FIFOs usually store one TDATA word per cycle unless it's a specific frame buffer.
    // Given the parameters FRAME_FIFO and DROP_OVERSIZE_FRAME, we implement a logic that buffers frames.
    // If FRAME_FIFO is 0, we treat each beat as a frame or part of a stream without frame boundaries affecting storage depth logic significantly, 
    // but we still track tlast.
    // If FRAME_FIFO is 1, we accumulate data until tlast. If the frame is too large, we drop/mark based on params.
    
    // To support FRAME_FIFO properly with a standard depth, we assume the FIFO stores "words".
    // If a frame spans multiple words, we need to ensure we don't overflow before the frame ends.
    // Simplified approach for this generic implementation:
    // 1. If FRAME_FIFO == 0: Standard FIFO. Each beat is independent.
    // 2. If FRAME_FIFO == 1: We buffer until tlast. We check depth against frame size.
    
    // Let's implement a standard deep FIFO first, then add frame logic on top.
    // Since we cannot use vendor primitives, we use a simple RAM or a shift register if DEPTH is small.
    // For DEPTH=4096, a RAM is preferred. We will use a simple array instantiation logic or a generated RAM.
    // Since we cannot use generate loops in the final output block easily without making it huge, 
    // we will use a procedural assignment to a memory array if DEPTH is power of 2, 
    // or simply assume the synthesis tool handles the RAM instantiation if we declare it as a register array.
    // Verilog-2001 allows array declarations.
    
    logic [DATA_WIDTH-1:0] ram_data [0:MAX_DEPTH-1];
    logic [KEEP_WIDTH-1:0] ram_keep [0:MAX_DEPTH-1];
    logic ram_last [0:MAX_DEPTH-1];
    logic [ID_WIDTH-1:0] ram_id [0:MAX_DEPTH-1];
    logic [DEST_WIDTH-1:0] ram_dest [0:MAX_DEPTH-1];
    logic [USER_WIDTH-1:0] ram_user [0:MAX_DEPTH-1];
    logic ram_valid [0:MAX_DEPTH-1]; // Validity of the entry in RAM

    // Frame Buffering Logic (if FRAME_FIFO is enabled)
    // We need to know if the current frame is complete to decide when to pop.
    // If FRAME_FIFO=1, we only pop when tlast is seen (or frame is complete).
    // If FRAME_FIFO=0, we pop on every read enable.
    
    logic frame_buffer_full;
    logic frame_buffer_empty;
    logic [LOG2_DEPTH-1:0] frame_buffer_depth;
    
    // Frame State Machine
    logic frame_start;
    logic frame_end;
    logic frame_count; // Count of words in current frame
    logic [LOG2_DEPTH-1:0] frame_max_depth; // Max allowed depth for a frame
    
    // Output FIFO (if OUTPUT_FIFO_ENABLE)
    // If enabled, we buffer the output to the master.
    logic [DATA_WIDTH-1:0] out_fifo_data [0:MAX_DEPTH-1];
    logic [KEEP_WIDTH-1:0] out_fifo_keep [0:MAX_DEPTH-1];
    logic out_fifo_last [0:MAX_DEPTH-1];
    logic [ID_WIDTH-1:0] out_fifo_id [0:MAX_DEPTH-1];
    logic [DEST_WIDTH-1:0] out_fifo_dest [0:MAX_DEPTH-1];
    logic [USER_WIDTH-1:0] out_fifo_user [0:MAX_DEPTH-1];
    logic out_fifo_valid [0:MAX_DEPTH-1];
    logic [LOG2_DEPTH-1:0] out_fifo_write_ptr, out_fifo_read_ptr;
    logic [LOG2_DEPTH-1:0] out_fifo_depth;
    logic out_fifo_full, out_fifo_empty;
    logic out_fifo_write_en, out_fifo_read_en;

    // Status Signals
    assign status_depth = depth;
    assign status_depth_commit = depth_commit;
    assign status_overflow = full;
    assign status_bad_frame = frame_bad;
    assign status_good_frame = frame_complete;

    // --- Frame Logic ---
    
    // Determine frame max depth
    if (FRAME_FIFO) begin
        frame_max_depth = DEPTH; // Or a specific parameter if provided, defaulting to FIFO depth
    end else begin
        frame_max_depth = 1; // No frame buffering, process beat by beat
    end

    // Frame State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_active <= 1'b0;
            frame_complete <= 1'b0;
            frame_oversize <= 1'b0;
            frame_bad <= 1'b0;
            frame_pause_requested <= 1'b0;
            frame_count <= 0;
            frame_start <= 1'b0;
            frame_end <= 1'b0;
        end else begin
            // Detect Frame Start
            if (s_axis_tvalid && !s_axis_tlast && !frame_active) begin
                frame_start <= 1'b1;
                frame_active <= 1'b1;
                frame_count <= 1;
                frame_oversize <= 1'b0;
                frame_bad <= 1'b0;
                frame_pause_requested <= 1'b0;
            end
            // Detect Frame End
            else if (s_axis_tvalid && s_axis_tlast && frame_active) begin
                frame_end <= 1'b1;
                frame_active <= 1'b0;
                // Check for oversize
                if (frame_count > frame_max_depth) begin
                    frame_oversize <= 1'b1;
                end
                // Check for bad frame (user bit)
                if (s_axis_tuser & USER_BAD_FRAME_MASK) begin
                    frame_bad <= 1'b1;
                end
                frame_complete <= 1'b1;
                frame_count <= 0;
            end
            // Update count during reading/writing
            else if (frame_active) begin
                frame_count <= frame_count + 1;
            end
        end
    end

    // --- Main FIFO Logic ---

    // Depth Calculation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_ptr <= 0;
            read_ptr <= 0;
            depth <= 0;
            depth_commit <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            write_ptr <= write_ptr + write_enable;
            read_ptr <= read_ptr + read_enable;
            depth <= write_ptr - read_ptr;
            depth_commit <= write_ptr_commit - read_ptr_commit;
            
            full <= (depth == MAX_DEPTH);
            empty <= (depth == 0);
        end
    end

    // Write Enable Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_enable <= 1'b0;
            write_ptr_commit <= 0;
        end else begin
            // If FRAME_FIFO is enabled, we can only write if the frame is not complete yet
            // AND we are not at the end of the frame (unless it's the last word).
            // Actually, if FRAME_FIFO=1, we buffer the whole frame.
            // If FRAME_FIFO=0, we write every valid beat.
            
            logic can_write;
            
            if (FRAME_FIFO) begin
                // If frame is active, we can write if we haven't reached max depth for the frame
                // But since the FIFO depth is the limit, we just check FIFO full.
                // However, if the frame is already complete, we stop writing until next frame.
                if (frame_active) begin
                    can_write = (!full);
                end else begin
                    can_write = (!full);
                end
            end else begin
                can_write = (!full);
            end

            // Handle Pause Request
            if (PAUSE_ENABLE && pause_req) begin
                write_enable <= 1'b0;
            end else begin
                write_enable <= can_write && s_axis_tvalid;
            end
            
            // Commit logic: If FRAME_FIFO, we commit when frame ends.
            // If FRAME_FIFO=0, we commit every write.
            if (FRAME_FIFO) begin
                if (frame_end) begin
                    write_ptr_commit <= write_ptr;
                end else begin
                    write_ptr_commit <= write_ptr; // Commit immediately if not frame buffered? 
                    // Wait, if FRAME_FIFO=1, we want to commit only when frame ends.
                    // So if frame_active, we don't commit.
                    if (!frame_active) begin
                        write_ptr_commit <= write_ptr;
                    end
                end
            end else begin
                write_ptr_commit <= write_ptr;
            end
        end
    end

    // Read Enable Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_enable <= 1'b0;
            read_ptr_commit <= 0;
        end else begin
            // If FRAME_FIFO is enabled, we only read when the frame is complete.
            // If FRAME_FIFO is disabled, we read whenever m_axis_tready is high.
            
            logic can_read;
            
            if (FRAME_FIFO) begin
                // Only read if frame is complete
                if (frame_complete) begin
                    can_read = m_axis_tready;
                end else begin
                    can_read = 1'b0;
                end
            end else begin
                can_read = m_axis_tready;
            end

            if (can_read) begin
                read_enable <= 1'b1;
            end else begin
                read_enable <= 1'b0;
            end
            
            // Commit logic: If FRAME_FIFO, commit when frame ends.
            if (FRAME_FIFO) begin
                if (frame_end) begin
                    read_ptr_commit <= read_ptr;
                end else begin
                    read_ptr_commit <= read_ptr;
                end
            end else begin
                read_ptr_commit <= read_ptr;
            end
        end
    end

    // RAM Write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (integer i = 0; i < MAX_DEPTH; i = i + 1) begin
                ram_data[i] <= 0;
                ram_keep[i] <= 0;
                ram_last[i] <= 0;
                ram_id[i] <= 0;
                ram_dest[i] <= 0;
                ram_user[i] <= 0;
                ram_valid[i] <= 0;
            end
        end else begin
            if (write_enable) begin
                ram_data[write_ptr] <= s_axis_tdata;
                ram_keep[write_ptr] <= s_axis_tkeep;
                ram_last[write_ptr] <= s_axis_tlast;
                ram_id[write_ptr] <= s_axis_tid;
                ram_dest[write_ptr] <= s_axis_tdest;
                ram_user[write_ptr] <= s_axis_tuser;
                ram_valid[write_ptr] <= 1'b1;
            end else begin
                ram_data[write_ptr] <= ram_data[write_ptr];
                ram_keep[write_ptr] <= ram_keep[write_ptr];
                ram_last[write_ptr] <= ram_last[write_ptr];
                ram_id[write_ptr] <= ram_id[write_ptr];
                ram_dest[write_ptr] <= ram_dest[write_ptr];
                ram_user[write_ptr] <= ram_user[write_ptr];
                ram_valid[write_ptr] <= ram_valid[write_ptr];
            end
        end
    end

    // RAM Read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata <= 0;
            m_axis_tkeep <= 0;
            m_axis_tlast <= 0;
            m_axis_tid <= 0;
            m_axis_tdest <= 0;
            m_axis_tuser <= 0;
            m_axis_tvalid <= 0;
        end else begin
            if (read_enable) begin
                m_axis_tdata <= ram_data[read_ptr];
                m_axis_tkeep <= ram_keep[read_ptr];
                m_axis_tlast <= ram_last[read_ptr];
                m_axis_tid <= ram_id[read_ptr];
                m_axis_tdest <= ram_dest[read_ptr];
                m_axis_tuser <= ram_user[read_ptr];
                m_axis_tvalid <= 1'b1;
            end else begin
                m_axis_tdata <= m_axis_tdata;
                m_axis_tkeep <= m_axis_tkeep;
                m_axis_tlast <= m_axis_tlast;
                m_axis_tid <= m_axis_tid;
                m_axis_tdest <= m_axis_tdest;
                m_axis_tuser <= m_axis_tuser;
                m_axis_tvalid <= 0;
            end
        end
    end

    // AXI-Stream Handshakes
    assign s_axis_tready = (!full) && (!PAUSE_ENABLE || !pause_req);
    assign m_axis_tready = m_axis_tready; // Pass through
    assign m_axis_tvalid = m_axis_tvalid; // Pass through

    // --- Output FIFO Logic (if enabled) ---
    // This buffers the output to the master to handle backpressure from the master.
    if (OUTPUT_FIFO_ENABLE) begin
        always @(posedge clk or posedge rst) begin
            if (rst) begin
                out_fifo_write_ptr <= 0;
                out_fifo_read_ptr <= 0;
                out_fifo_depth <= 0;
                out_fifo_full <= 0;
                out_fifo_empty <= 1;
            end else begin
                out_fifo_write_ptr <= out_fifo_write_ptr + out_fifo_write_en;
                out_fifo_read_ptr <= out_fifo_read_ptr + out_fifo_read_en;
                out_fifo_depth <= out_fifo_write_ptr - out_fifo_read_ptr;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end
        end

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                for (integer i = 0; i < MAX_DEPTH; i = i + 1) begin
                    out_fifo_data[i] <= 0;
                    out_fifo_keep[i] <= 0;
                    out_fifo_last[i] <= 0;
                    out_fifo_id[i] <= 0;
                    out_fifo_dest[i] <= 0;
                    out_fifo_user[i] <= 0;
                    out_fifo_valid[i] <= 0;
                end
            end else begin
                if (out_fifo_write_en) begin
                    out_fifo_data[out_fifo_write_ptr] <= m_axis_tdata;
                    out_fifo_keep[out_fifo_write_ptr] <= m_axis_tkeep;
                    out_fifo_last[out_fifo_write_ptr] <= m_axis_tlast;
                    out_fifo_id[out_fifo_write_ptr] <= m_axis_tid;
                    out_fifo_dest[out_fifo_write_ptr] <= m_axis_tdest;
                    out_fifo_user[out_fifo_write_ptr] <= m_axis_tuser;
                    out_fifo_valid[out_fifo_write_ptr] <= 1'b1;
                end else begin
                    out_fifo_data[out_fifo_write_ptr] <= out_fifo_data[out_fifo_write_ptr];
                    out_fifo_keep[out_fifo_write_ptr] <= out_fifo_keep[out_fifo_write_ptr];
                    out_fifo_last[out_fifo_write_ptr] <= out_fifo_last[out_fifo_write_ptr];
                    out_fifo_id[out_fifo_write_ptr] <= out_fifo_id[out_fifo_write_ptr];
                    out_fifo_dest[out_fifo_write_ptr] <= out_fifo_dest[out_fifo_write_ptr];
                    out_fifo_user[out_fifo_write_ptr] <= out_fifo_user[out_fifo_write_ptr];
                    out_fifo_valid[out_fifo_write_ptr] <= out_fifo_valid[out_fifo_write_ptr];
                end
            end
        end

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                out_fifo_write_en <= 1'b0;
                out_fifo_read_en <= 1'b0;
            end else begin
                // Write to output FIFO if main FIFO has data and output FIFO is not full
                out_fifo_write_en <= m_axis_tvalid && !out_fifo_full;
                
                // Read from output FIFO if master is ready and output FIFO is not empty
                out_fifo_read_en <= m_axis_tready && !out_fifo_empty;
            end
        end

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                m_axis_tdata <= 0;
                m_axis_tkeep <= 0;
                m_axis_tlast <= 0;
                m_axis_tid <= 0;
                m_axis_tdest <= 0;
                m_axis_tuser <= 0;
                m_axis_tvalid <= 0;
            end else begin
                if (out_fifo_read_en) begin
                    m_axis_tdata <= out_fifo_data[out_fifo_read_ptr];
                    m_axis_tkeep <= out_fifo_keep[out_fifo_read_ptr];
                    m_axis_tlast <= out_fifo_last[out_fifo_read_ptr];
                    m_axis_tid <= out_fifo_id[out_fifo_read_ptr];
                    m_axis_tdest <= out_fifo_dest[out_fifo_read_ptr];
                    m_axis_tuser <= out_fifo_user[out_fifo_read_ptr];
                    m_axis_tvalid <= 1'b1;
                end else begin
                    m_axis_tdata <= m_axis_tdata;
                    m_axis_tkeep <= m_axis_tkeep;
                    m_axis_tlast <= m_axis_tlast;
                    m_axis_tid <= m_axis_tid;
                    m_axis_tdest <= m_axis_tdest;
                    m_axis_tuser <= m_axis_tuser;
                    m_axis_tvalid <= 0;
                end
            end
        end
    end else begin
        // If OUTPUT_FIFO_ENABLE is 0, pass through directly
        assign m_axis_tdata = m_axis_tdata;
        assign m_axis_tkeep = m_axis_tkeep;
        assign m_axis_tlast = m_axis_tlast;
        assign m_axis_tid = m_axis_tid;
        assign m_axis_tdest = m_axis_tdest;
        assign m_axis_tuser = m_axis_tuser;
        assign m_axis_tvalid = m_axis_tvalid;
    end

    // --- Pause Logic ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_ack <= 1'b0;
        end else begin
            if (PAUSE_ENABLE) begin
                if (pause_req) begin
                    pause_ack <= 1'b1;
                end else begin
                    pause_ack <= 1'b0;
                end
            end else begin
                pause_ack <= 1'b0;
            end
        end
    end

    // --- Status Logic ---
    // status_bad_frame: Set if frame is bad (user bit) or oversize (if DROP_OVERSIZE_FRAME)
    // status_good_frame: Set if frame is complete and good
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_bad_frame <= 1'b0;
            status_good_frame <= 1'b0;
        end else begin
            if (frame_complete) begin
                if (frame_bad || (frame_oversize && DROP_OVERSIZE_FRAME)) begin
                    status_bad_frame <= 1'b1;
                    status_good_frame <= 1'b0;
                end else begin
                    status_bad_frame <= 1'b0;
                    status_good_frame <= 1'b1;
                end
            end else begin
                status_bad_frame <= 1'b0;
                status_good_frame <= 1'b0;
            end
        end
    end

endmodule
```<|im_end|>
