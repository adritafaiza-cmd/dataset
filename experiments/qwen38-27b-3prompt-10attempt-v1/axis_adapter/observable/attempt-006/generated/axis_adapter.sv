module axis_adapter #
(
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
    parameter USER_WIDTH = 1
)
(
    input  wire                     clk,
    input  wire                     rst,
    /*
     * AXI input
     */
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
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser
);

    // Determine if we need to upsize, downsize, or same width
    localparam S_BYTES = (S_DATA_WIDTH + 7) / 8;
    localparam M_BYTES = (M_DATA_WIDTH + 7) / 8;
    localparam S_BITS  = S_DATA_WIDTH;
    localparam M_BITS  = M_DATA_WIDTH;

    // We'll use a byte-level approach.
    // The converter works by accumulating bytes from the input and emitting bytes to the output.
    // To handle arbitrary widths, we'll use a shift register approach.

    // State:
    // - A buffer that holds accumulated bytes from input
    // - A counter for how many valid bytes are in the buffer
    // - Sideband signals from the current input beat (to be associated with output beats)

    // Let's define the maximum number of bytes we might need to buffer.
    // In the worst case, we might have up to S_BYTES + M_BYTES - 1 bytes in the buffer.
    localparam BUF_BYTES = S_BYTES + M_BYTES - 1;
    localparam BUF_BITS  = BUF_BYTES * 8;

    // Buffer to hold accumulated data
    reg [BUF_BITS-1:0] buf;
    reg [BUF_BYTES-1:0] buf_valid_bytes; // Number of valid bytes in buffer

    // Sideband signals from the current input beat
    reg s_axis_tlast_r;
    reg [ID_WIDTH-1:0] s_axis_tid_r;
    reg [DEST_WIDTH-1:0] s_axis_tdest_r;
    reg [USER_WIDTH-1:0] s_axis_tuser_r;

    // We need to track which input beat's sideband is currently being processed
    // and whether we've already emitted the tlast for that beat.

    // Let's think about this differently. We'll use a simpler approach:
    // - Accept input when we can make progress
    - Emit output when we have enough data

    // Actually, let's use a more standard approach for width converters.
    // We'll maintain a shift register and track the number of valid bytes.

    // For simplicity and correctness, let's handle the common cases:
    // 1. Same width: direct pass-through
    // 2. Upsize (S < M): accumulate S bytes, emit M bytes
    // 3. Downsize (S > M): emit M bytes from S bytes

    // Let's implement a general byte-level converter.

    // Number of valid bytes in the buffer
    reg [$clog2(BUF_BYTES+1)-1:0] num_valid;

    // Sideband from the beat that is currently being drained
    reg s_axis_tlast_r;
    reg [ID_WIDTH-1:0] s_axis_tid_r;
    reg [DEST_WIDTH-1:0] s_axis_tdest_r;
    reg [USER_WIDTH-1:0] s_axis_tuser_r;

    // We need to know if the current buffer contents include a tlast
    // and whether we've already emitted it.

    // Let's track:
    // - Whether the current buffer has a pending tlast
    // - Whether the tlast has been emitted

    reg tlast_pending;
    reg tlast_emitted;

    // Input ready: we can accept input if we have space in the buffer
    // and we're not in a state where we can't make progress.
    // For simplicity, let's say we can accept input if num_valid < BUF_BYTES.
    // But we also need to ensure we don't deadlock.

    // Let's define:
    // - can_accept: we can accept a new input beat
    // - can_emit: we can emit an output beat

    wire can_accept = (num_valid < BUF_BYTES[$clog2(BUF_BYTES+1)-1:0]);
    wire can_emit = (num_valid >= M_BYTES[$clog2(BUF_BYTES+1)-1:0]);

    // But we need to be more careful. Let's think about when we can accept input.
    // We can accept input if:
    // 1. The buffer has space (num_valid + S_BYTES <= BUF_BYTES)
    // 2. OR we can emit at least one output beat (to make space)

    // Actually, for a single-clock design, we need to be careful about simultaneous accept and emit.
    // Let's allow simultaneous accept and emit if both conditions are met.

    wire accept = s_axis_tvalid && s_axis_tready;
    wire emit = m_axis_tvalid && m_axis_tready;

    // s_axis_tready: we can accept if we have space or can emit
    // Let's say we can accept if num_valid + S_BYTES <= BUF_BYTES OR (num_valid >= M_BYTES && m_axis_tready)
    // But this is getting complex. Let's use a simpler approach:
    // We can accept if num_valid < BUF_BYTES - S_BYTES + 1 (i.e., there's room for a full beat)
    // OR if we can emit (to make room).

    // For now, let's use a conservative approach:
    // s_axis_tready = (num_valid + S_BYTES <= BUF_BYTES) || (num_valid >= M_BYTES && m_axis_tready)
    // But this might not be optimal. Let's just use:
    // s_axis_tready = (num_valid < BUF_BYTES) && (num_valid + S_BYTES <= BUF_BYTES || m_axis_tready)

    // Actually, let's simplify: we'll allow accept if there's room in the buffer.
    // If the buffer is full, we'll wait until we can emit.
    // This is conservative but correct.

    assign s_axis_tready = (num_valid + S_BYTES[$clog2(BUF_BYTES+1)-1:0] <= BUF_BYTES[$clog2(BUF_BYTES+1)-1:0]);

    // m_axis_tvalid: we can emit if we have at least M_BYTES valid bytes
    assign m_axis_tvalid = (num_valid >= M_BYTES[$clog2(BUF_BYTES+1)-1:0]);

    // Output data: take the first M_BYTES from the buffer
    // The buffer is organized with the oldest bytes at the LSB.
    // So the first M_BYTES are buf[M_BYTES*8-1:0].

    assign m_axis_tdata = buf[M_BITS-1:0];

    // Output tkeep: all ones if M_KEEP_ENABLE, else 0
    // For simplicity, let's assume all bytes are valid when emitting.
    // This is correct if we only emit when we have a full M_BYTES.
    assign m_axis_tkeep = M_KEEP_ENABLE ? {M_KEEP_WIDTH{1'b1}} : {M_KEEP_WIDTH{1'b0}};

    // Output tlast: emit tlast if tlast_pending and this is the last beat of the current packet
    // We need to track when the tlast byte is in the current output beat.
    // For simplicity, let's say tlast is emitted when tlast_pending is set and
    // the tlast byte is within the current M_BYTES being emitted.

    // Actually, let's track the position of the tlast byte in the buffer.
    // When we accept a beat with tlast, we set tlast_pending and record the position.

    reg [$clog2(BUF_BYTES)-1:0] tlast_pos; // Position of tlast byte in buffer (0-indexed)

    // tlast is in the current output beat if tlast_pos < M_BYTES
    wire tlast_in_current = tlast_pending && (tlast_pos < M_BYTES[$clog2(BUF_BYTES)-1:0]);

    assign m_axis_tlast = tlast_in_current;

    // Sideband outputs
    assign m_axis_tid = s_axis_tid_r;
    assign m_axis_tdest = s_axis_tdest_r;
    assign m_axis_tuser = s_axis_tuser_r;

    // Next state logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf <= {BUF_BITS{1'b0}};
            num_valid <= 0;
            s_axis_tlast_r <= 1'b0;
            s_axis_tid_r <= {ID_WIDTH{1'b0}};
            s_axis_tdest_r <= {DEST_WIDTH{1'b0}};
            s_axis_tuser_r <= {USER_WIDTH{1'b0}};
            tlast_pending <= 1'b0;
            tlast_emitted <= 1'b0;
            tlast_pos <= 0;
        end else begin
            // Handle accept and emit
            if (accept && emit) begin
                // Shift buffer left by M_BYTES, add S_BYTES from input
                // New buffer = (buf << (M_BYTES*8)) | s_axis_tdata
                // But we need to handle the tlast position.

                // First, shift the buffer
                buf <= (buf << (M_BYTES*8)) | s_axis_tdata;

                // Update num_valid
                num_valid <= num_valid - M_BYTES[$clog2(BUF_BYTES+1)-1:0] + S_BYTES[$clog2(BUF_BYTES+1)-1:0];

                // Update tlast position
                if (tlast_pending) begin
                    if (tlast_in_current) begin
                        // tlast was emitted, clear pending
                        tlast_pending <= 1'b0;
                        tlast_emitted <= 1'b1;
                    end else begin
                        // tlast is still in buffer, adjust position
                        tlast_pos <= tlast_pos - M_BYTES[$clog2(BUF_BYTES)-1:0];
                    end
                end

                // If input has tlast, set pending
                if (s_axis_tlast) begin
                    tlast_pending <= 1'b1;
                    tlast_pos <= num_valid - M_BYTES[$clog2(BUF_BYTES+1)-1:0] + S_BYTES[$clog2(BUF_BYTES+1)-1:0] - 1;
                    // Wait, this is the position after the shift and add.
                    // The new tlast byte is at position (num_valid - M_BYTES + S_BYTES - 1)
                    // But num_valid is being updated, so we need to use the new value.
                    // Let's compute it separately.
                end

                // Update sideband
                s_axis_tlast_r <= s_axis_tlast;
                s_axis_tid_r <= s_axis_tid;
                s_axis_tdest_r <= s_axis_tdest;
                s_axis_tuser_r <= s_axis_tuser;

            end else if (accept) begin
                // Only accept, no emit
                buf <= (buf << (S_BYTES*8)) | s_axis_tdata;
                // Wait, this is wrong. We should append to the buffer, not shift.
                // The buffer should be organized so that new bytes go to the high end.
                // Let's reorganize: buf[BUF_BITS-1:0] with oldest at LSB.
                // When we accept, we shift left by S_BYTES and add new data.
                // But this would lose the old data if we shift too much.
                // Actually, we should just append: buf = (buf << (S_BYTES*8)) | s_axis_tdata
                // But this shifts the old data up, which is correct.

                // Hmm, I think I'm overcomplicating this. Let's use a different approach.
                // Let's use a circular buffer or a simpler shift register.

                // For now, let's just use a simple approach:
                // buf is a shift register. New data goes in at the MSB side.
                // When we emit, we take from the LSB side.

                // Actually, let's restart with a cleaner approach.
            end
        end
    end

    // I realize the above approach is getting messy. Let me rewrite with a cleaner design.

endmodule
