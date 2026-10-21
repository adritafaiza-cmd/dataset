```verilog
module axis_register #
(
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
    parameter REG_TYPE = 2
)
(
    input  wire                   clk,
    input  wire                   rst,
    /*
     * AXI Stream input
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
     * AXI Stream output
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser
);

    // Generate enable signals for optional sidebands
    wire keep_enable = KEEP_ENABLE;
    wire last_enable = LAST_ENABLE;
    wire id_enable = ID_ENABLE;
    wire dest_enable = DEST_ENABLE;
    wire user_enable = USER_ENABLE;

    // Calculate total width of the register payload (data + sidebands)
    // We use a packed array or a single large wire to store the state.
    // To ensure CDC safety and structural clarity, we will use separate registers
    // for data and sidebands, driven by a unified valid signal.
    
    reg [DATA_WIDTH-1:0] reg_tdata;
    reg [KEEP_WIDTH-1:0] reg_tkeep;
    reg                   reg_tlast;
    reg [ID_WIDTH-1:0]    reg_tid;
    reg [DEST_WIDTH-1:0]  reg_tdest;
    reg [USER_WIDTH-1:0]  reg_tuser;
    reg                   reg_valid;

    // Logic to determine if we should capture new data
    // This logic is synchronous to clk.
    // We capture data when s_axis_tvalid is high AND (it is the first beat of a packet OR we are not in a skid buffer scenario requiring strict FIFO behavior).
    // For REG_TYPE 2 (Skid Buffer), we must not drop beats. This implies a FIFO-like behavior where we only push if we have space or if we are just buffering.
    // However, the prompt asks for a "single-clock AXI-Stream register slice". 
    // Standard interpretation for REG_TYPE 2 in this context (often used in Xilinx IP) is a 1-beat buffer that holds data if the output is stalled, but does not drop beats (i.e., it acts as a depth-1 FIFO).
    // If REG_TYPE is 0 (Wire) or 1 (Buffer), it is a simple latch.
    
    // Let's define the capture logic.
    // We capture on the rising edge of clk if:
    // 1. s_axis_tvalid is high.
    // 2. (For Wire/Buffer): We capture immediately.
    // 3. (For Skid Buffer): We capture if we are not already holding valid data that is waiting for m_axis_tready? 
    //    Actually, a skid buffer usually implies a depth of 1. If m_axis_tready is low, we hold the data. If m_axis_tready is high, we push.
    //    But the requirement says "must not drop a beat". This means if the input comes in and the output is stalled, we store it. If the output becomes ready, we send it.
    //    The tricky part is the transition. 
    //    Simple approach for Skid Buffer (Depth 1):
    //    - If reg_valid is low, and s_axis_tvalid is high, set reg_valid high and load data.
    //    - If reg_valid is high, and m_axis_tready is high, set reg_valid low and drive output.
    //    - If reg_valid is high, and m_axis_tready is low, hold data.
    //    - If reg_valid is high, and s_axis_tvalid is high (new beat arrives while old is held), this is a conflict for depth 1.
    //    Usually, a skid buffer in AXI-Stream context implies a depth of 1. If a new beat arrives while the buffer is full, the input must wait (s_axis_tready asserted low).
    //    So the logic is: Capture if (!reg_valid && s_axis_tvalid).
    
    // Wait, the prompt says "REG_TYPE 2 is a skid buffer that must not drop a beat when the output stalls".
    // This confirms the depth-1 FIFO behavior.
    // Logic:
    // If (!reg_valid && s_axis_tvalid) -> Capture.
    // If (reg_valid && m_axis_tready) -> Release.
    
    // For Wire (0) and Buffer (1), they are essentially latches. They do not buffer if the output stalls; they just pass through.
    // If output stalls (m_axis_tready low), the input must stall (s_axis_tready low).
    // So for Wire/Buffer: Capture if (s_axis_tvalid && m_axis_tready).
    
    wire capture_enable;
    wire release_enable;

    assign capture_enable = s_axis_tvalid;
    assign release_enable = m_axis_tready;

    // Determine if we should actually update the register based on REG_TYPE
    // Type 0 (Wire): Only update if input valid AND output ready.
    // Type 1 (Buffer): Only update if input valid AND output ready.
    // Type 2 (Skid): Update if input valid (regardless of output ready, effectively buffering).
    
    wire type_is_skid = (REG_TYPE == 2);
    wire type_is_buffer_or_wire = (REG_TYPE == 0 || REG_TYPE == 1);

    // Capture Logic
    // We use a non-blocking assignment for the register update.
    // The condition to update is:
    // If Skid: s_axis_tvalid is high.
    // If Wire/Buffer: s_axis_tvalid is high AND m_axis_tready is high.
    
    wire should_capture;
    assign should_capture = (type_is_skid) ? s_axis_tvalid : (s_axis_tvalid && m_axis_tready);

    // Release Logic
    // We release data if:
    // 1. We have valid data (reg_valid).
    // 2. Output is ready (m_axis_tready).
    // 3. (Optional optimization for Skid) If a new beat arrives while holding, do we overwrite? 
    //    No, a depth-1 FIFO cannot overwrite. The input must wait. So we only release if m_axis_tready is high.
    //    If m_axis_tready is low, we hold. If s_axis_tvalid is high while holding, s_axis_tready must be low.
    //    So release condition is simply: reg_valid && m_axis_tready.
    
    wire should_release;
    assign should_release = reg_valid && m_axis_tready;

    // Sequential Logic
    // Reset sets everything to 0 (empty).
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_valid <= 1'b0;
            reg_tdata <= 1'b0;
            reg_tkeep <= 1'b0;
            reg_tlast <= 1'b0;
            reg_tid <= 1'b0;
            reg_tdest <= 1'b0;
            reg_tuser <= 1'b0;
        end else begin
            if (should_capture) begin
                // Capture new data
                reg_valid <= 1'b1;
                reg_tdata <= s_axis_tdata;
                reg_tkeep <= s_axis_tkeep;
                reg_tlast <= s_axis_tlast;
                reg_tid <= s_axis_tid;
                reg_tdest <= s_axis_tdest;
                reg_tuser <= s_axis_tuser;
            end else if (should_release) begin
                // Release data (only happens if we have data and output is ready)
                // Note: For Skid buffer, if a new beat arrives while we are holding, we don't capture yet.
                // We only capture when we release the current one.
                // This ensures the "no drop" behavior naturally by stalling input until output is ready.
                reg_valid <= 1'b0;
                reg_tdata <= 1'b0;
                reg_tkeep <= 1'b0;
                reg_tlast <= 1'b0;
                reg_tid <= 1'b0;
                reg_tdest <= 1'b0;
                reg_tuser <= 1'b0;
            end
            // For Wire/Buffer, if m_axis_tready is low, we do nothing (hold state), 
            // but since we only capture when m_axis_tready is high, the register won't update.
            // Effectively, the register holds the last valid value, and we drive that value out.
            // Wait, for Wire/Buffer, if m_axis_tready is low, we must NOT capture. 
            // The logic above handles this: should_capture requires m_axis_tready for non-skid types.
        end
    end

    // Output Logic
    // Drive outputs based on reg_valid.
    // If reg_valid is high, drive the stored values.
    // If reg_valid is low, drive 0s (or high-Z, but 0 is standard for AXI-Stream idle).
    
    assign m_axis_tvalid = reg_valid;
    assign m_axis_tdata = reg_valid ? reg_tdata : 1'b0;
    assign m_axis_tkeep = reg_valid ? reg_tkeep : 1'b0;
    assign m_axis_tlast = reg_valid ? reg_tlast : 1'b0;
    assign m_axis_tid = reg_valid ? reg_tid : 1'b0;
    assign m_axis_tdest = reg_valid ? reg_tdest : 1'b0;
    assign m_axis_tuser = reg_valid ? reg_tuser : 1'b0;

    // Handshake Logic
    // s_axis_tready is asserted if we are ready to accept data.
    // We are ready if:
    // 1. We are empty (reg_valid == 0).
    // 2. OR (We are full (reg_valid == 1) AND we are a Skid Buffer AND output is ready).
    //    Actually, if we are full and output is NOT ready, we are NOT ready to accept new data.
    //    If we are full and output IS ready, we will release immediately, so we are effectively ready to accept the next beat in the next cycle.
    //    However, in the current cycle, if we are full and output is ready, we release. 
    //    Can we accept a new beat in the same cycle? 
    //    In a single-cycle register, if we release in the same cycle, the register becomes empty at the end of the cycle. 
    //    So, if m_axis_tready is high, we release. At the end of the cycle, reg_valid is 0.
    //    So s_axis_tready should be 1 if (reg_valid == 0) OR (reg_valid == 1 && m_axis_tready == 1).
    //    Wait, if reg_valid is 1 and m_axis_tready is 1, we release. The register becomes 0. 
    //    So we are ready to accept the next beat.
    //    If reg_valid is 1 and m_axis_tready is 0, we hold. We are NOT ready to accept.
    
    // Simplified Ready Logic:
    // If reg_valid is 0, we are always ready.
    // If reg_valid is 1:
    //    If Skid Buffer: We are ready ONLY if m_axis_tready is 1 (because we need to make room).
    //    If Wire/Buffer: We are NEVER ready if reg_valid is 1 (because we don't buffer, we just pass through. If output stalls, input must stall).
    
    wire is_empty = !reg_valid;
    wire is_full = reg_valid;
    
    assign s_axis_tready = is_empty | (is_full && m_axis_tready && type_is_skid);
    
    // Re-evaluating the capture logic with the ready logic:
    // If type is Wire/Buffer:
    //   Capture = s_axis_tvalid && m_axis_tready.
    //   Ready = !reg_valid.
    //   This creates a transparent latch behavior. If m_axis_tready is low, we don't capture, and we aren't ready. Correct.
    
    // If type is Skid:
    //   Capture = s_axis_tvalid.
    //   Ready = !reg_valid | (reg_valid && m_axis_tready).
    //   Scenario A: Empty. Ready=1. Capture=1 (if valid). Next cycle: Full.
    //   Scenario B: Full, Output Ready. Ready=1. Capture=1 (if valid). 
    //      In this cycle, we capture new data AND release old data.
    //      Is this safe? 
    //      If we capture new data, reg_valid becomes 1. If we release old data, reg_valid becomes 0.
    //      The net result depends on the order of evaluation in the always block.
    //      In Verilog non-blocking:
    //      If we capture, reg_valid <= 1.
    //      If we release, reg_valid <= 0.
    //      If both happen, reg_valid stays 1 (last assignment wins? No, they are separate statements).
    //      Actually, if both conditions are true, we have a race in the logic description.
    //      Better logic for Skid:
    //      If we are full and output is ready, we release.
    //      If we are empty, we capture.
    //      If we are full and output is NOT ready, we hold.
    //      What if we are full, output is ready, AND new data arrives?
    //      We should release the old data, and then capture the new data.
    //      So:
    //      If (reg_valid && m_axis_tready) -> Release.
    //      Else If (!reg_valid && s_axis_tvalid) -> Capture.
    //      This prevents overwriting before releasing.
      
    // Let's refine the always block for REG_TYPE 2 to ensure correct FIFO behavior.
    
    // Re-writing the sequential block to handle the Skid Buffer edge case explicitly.
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_valid <= 1'b0;
            reg_tdata <= 1'b0;
            reg_tkeep <= 1'b0;
            reg_tlast <= 1'b0;
            reg_tid <= 1'b0;
            reg_tdest <= 1'b0;
            reg_tuser <= 1'b0;
        end else begin
            if (type_is_skid) begin
                // Skid Buffer Logic (Depth 1)
                if (reg_valid && m_axis_tready) begin
                    // Release current data
                    reg_valid <= 1'b0;
                    reg_tdata <= 1'b0;
                    reg_tkeep <= 1'b0;
                    reg_tlast <= 1'b0;
                    reg_tid <= 1'b0;
                    reg_tdest <= 1'b0;
                    reg_tuser <= 1'b0;
                end else if (!reg_valid && s_axis_tvalid) begin
                    // Capture new data
                    reg_valid <= 1'b1;
                    reg_tdata <= s_axis_tdata;
                    reg_tkeep <= s_axis_tkeep;
                    reg_tlast <= s_axis_tlast;
                    reg_tid <= s_axis_tid;
                    reg_tdest <= s_axis_tdest;
                    reg_tuser <= s_axis_tuser;
                end
                // If full and not ready, do nothing (hold).
            end else begin
                // Wire (0) or Buffer (1) Logic
                // Only capture if input valid AND output ready.
                if (s_axis_tvalid && m_axis_tready) begin
                    reg_valid <= 1'b1;
                    reg_tdata <= s_axis_tdata;
                    reg_tkeep <= s_axis_tkeep;
                    reg_tlast <= s_axis_tlast;
                    reg_tid <= s_axis_tid;
                    reg_tdest <= s_axis_tdest;
                    reg_tuser <= s_axis_tuser;
                end else if (reg_valid && m_axis_tready) begin
                    // This case is covered by the capture block above because if m_axis_tready is high,
                    // and we are not capturing (because s_axis_tvalid is low), we just hold the value.
                    // Wait, if s_axis_tvalid is low, we don't enter the first if.
                    // If reg_valid is high and m_axis_tready is high, we want to keep the value.
                    // The first if condition (s_axis_tvalid && m_axis_tready) will be false if s_axis_tvalid is low.
                    // So we fall through and do nothing. The register keeps the value.
                    // This is correct for a buffer: it holds the value until output is ready, then passes it.
                    // But wait, if output is ready, we want to pass it. 
                    // The output logic drives the register value. So if reg_valid is 1, m_axis_tvalid is 1.
                    // The consumer sees the data.
                    // The only issue is if the consumer is ready, do we need to clear the register?
                    // No, for a buffer, we just need to ensure we don't capture new data while output is stalled.
                    // If output is ready, we are fine.
                    // What if s_axis_tvalid is high, m_axis_tready is low?
                    // We don't capture. We don't release. We hold. s_axis_tready becomes 0. Correct.
                    // What if s_axis_tvalid is low, m_axis_tready is high?
                    // We don't capture. We don't release. We hold. m_axis_tvalid is 1. Correct.
                    // So the logic simplifies to:
                    // Capture if (s_axis_tvalid && m_axis_tready).
                    // Else hold.
                    // But wait, if we hold, and m_axis_tready is high, we are driving the old data.
                    // Is there any scenario where we need to clear the register?
                    // Only if we want to reset it. But the reset is handled by rst.
                    // So for Wire/Buffer, the logic is just:
                    // if (s_axis_tvalid && m_axis_tready) load;
                    // else hold;
                    
                    // However, consider the case where we want to ensure the register is cleared if the stream ends?
                    // AXI-Stream doesn't have an explicit end-of-stream signal for the register itself, 
                    // it relies on the tlast flag. The register just buffers the last beat.
                    // So the simple logic holds.
                    
                    // Wait, I need to check the "Buffer" definition again.
                    // "1 is a simple buffer". Usually, a buffer implies no storage if the output is stalled?
                    // No, a buffer in this context usually means a 1-cycle delay or a latch that passes data only when ready.
                    // If the output is not ready, the input must not proceed.
                    // So the behavior is identical to Wire regarding the handshake, except Wire might imply 0 latency?
                    // In a single-clock implementation, Wire and Buffer are functionally identical unless we consider pipeline stages.
                    // Given the constraints, they behave the same: Capture only on valid+ready.
                    
                    // Let's stick to the unified logic for Wire/Buffer:
                    // Capture if (s_axis_tvalid && m_axis_tready).
                    // This ensures we never capture if the downstream is stalled.
                end
            end
        end
    end

    // Re-evaluating the Ready signal for Skid Buffer with the new logic
    // If type is Skid:
    //   Ready = !reg_valid | (reg_valid && m_axis_tready)
    //   If reg_valid is 1 and m_axis_tready is 1 -> Ready = 1.
    //   In this cycle, we release (reg_valid becomes 0) and potentially capture (if s_axis_tvalid is 1).
    //   If we capture, reg_valid becomes 1.
    //   So at the end of the cycle, if we captured, reg_valid is 1.
    //   If we didn't capture (s_axis_tvalid was 0), reg_valid is 0.
    //   This seems correct.
    
    // One edge case: If reg_valid is 1, m_axis_tready is 1, and s_axis_tvalid is 1.
    // We release (reg_valid <= 0) and Capture (reg_valid <= 1).
    // The net result is reg_valid = 1.
    // This means we successfully pipelined the data.
    // Ready signal calculation:
    // s_axis_tready = (!reg_valid) | (reg_valid && m_axis_tready && type_is_skid);
    // At the start of the cycle: reg_valid=1, m_axis_tready=1.
    // s_axis_tready = 0 | (1 && 1 && 1) = 1.
    // So we accept the new data.
    // This is correct for a skid buffer.

    // Final check on Wire/Buffer Ready signal.
    // If type is Wire/Buffer:
    //   Ready = !reg_valid.
    //   If reg_valid is 1, Ready is 0.
    //   This forces the input to stall if there is data in the register.
    //   This is correct for a buffer that doesn't queue.

    // Wait, for Wire/Buffer, if reg_valid is 1, and m_axis_tready is 1, we are driving data.
    // The input is stalled because Ready is 0.
    // In the next cycle, m_axis_tready might still be 1.
    // But s_axis_tvalid is 0 (because we stalled).
    // So we don't capture.
    // We hold the data.
    // This creates a 1-cycle latency.
    // Is this desired?
    // "1 is a simple buffer". Yes, a buffer introduces latency.
    // "0 is a wire". A wire should ideally have 0 latency.
    // But in a single-clock register implementation, you cannot have 0 latency without a latch that is transparent.
    // If we use a latch, we need to be careful about setup times.
    // However, the prompt asks for a "register slice". Registers imply clocked storage.
    // If REG_TYPE 0 is a wire, maybe it should act as a latch?
    // But latches are not safe for CDC without careful design (transparent during enable).
    // Given the requirement "pass structural CDC/RDC analysis", latches are risky if not strictly controlled.
    // Usually, in these IP blocks, "Wire" means "Pass through with 1 cycle latency" (same as buffer) but without the buffering logic of a FIFO?
    // Or does it mean "Transparent"?
    // If it means transparent, we need a latch.
    // But the prompt says "single-clock AXI-Stream register slice".
    // Let's assume "Wire" means "No buffering, just pass through".
    // If we use a register, we inherently have 1 cycle latency.
    // If the user wants 0 latency, they shouldn't use a register.
    // Perhaps for REG_TYPE 0, we should NOT store the data if the output is ready?
    // No, that's impossible with a register.
    // Let's assume REG_TYPE 0 behaves exactly like REG_TYPE 1 (Buffer) in terms of timing (1 cycle), but the distinction might be in how it handles the "empty" state or specific sideband logic?
    // Actually, looking at Xilinx AXI-Stream Register Slice IP:
    // REG_TYPE 0: Wire. Passes data immediately. If output stalls, input stalls.
    // REG_TYPE 1: Buffer. Buffers data. If output stalls, input stalls.
    // REG_TYPE 2: Skid Buffer. Buffers data. If output stalls, input stalls.
    // Wait, if Wire passes immediately, how does it stall input if output stalls?
    // It can't, unless it uses a latch.
    // If it uses a latch, it's not a "register" in the strict sense of a flip-flop, but a latch.
    // However, the prompt asks for a "register slice".
    // Let's assume the standard interpretation for these parameters in a register-based implementation:
    // All types use flip-flops.
    // Type 0 (Wire): The register is bypassed? No, that's not a register slice.
    // Maybe Type 0 means "Do not buffer, but still use a register for CDC safety"?
    // In that case, Type 0 and Type 1 are identical.
    // Let's assume Type 0 and Type 1 are identical (1-cycle latency, stall on output stall).
    // Type 2 is the only one that allows input to proceed while output is stalled (by holding the data).
    
    // Wait, if Type 0 is a wire, and we use a register, we introduce latency.
    // If the requirement is strict "Wire", we might need a latch.
    // But latches are bad for CDC.
    // Let's stick to the register implementation for all types to ensure CDC safety, 
    // and assume "Wire" in this context means "No FIFO depth > 1", i.e., depth 1.
    // Which is exactly what Type 1 does.
    // So Type 0 and Type 1 are functionally identical in a register-based implementation.
    // The distinction might be theoretical or for specific IP compatibility where "Wire" implies no buffering logic at all (which is impossible with a register).
    // I will implement Type 0 and Type 1 identically (Capture only on valid+ready).
    // Type 2 will implement the skid buffer logic (Capture on valid, Release on ready).

    // Re-checking the logic for Type 0/1:
    // If s_axis_tvalid is 1, m_axis_tready is 0.
    // We don't capture. reg_valid stays 1 (if it was 1) or 0 (if it was 0).
    // If it was 0, it stays 0. s_axis_tready = 0. Correct.
    // If it was 1, it stays 1. s_axis_tready = 0. Correct.
    // If s_axis_tvalid is 1, m_axis_tready is 1.
    // We capture. reg_valid becomes 1. s_axis_tready = 1. Correct.
    // If s_axis_tvalid is 0, m_axis_tready is 1.
    // We don't capture. reg_valid stays 1. s_axis_tready = 1? 
    // Wait, if reg_valid is 1, and we don't capture, s_axis_tready should be 0 for Type 0/1.
    // My previous logic: s_axis_tready = !reg_valid.
    // So if reg_valid is 1, s_axis_tready is 0.
    // This means if there is data in the buffer, we stall the input, even if the output is ready?
    // No, if the output is ready, we should drive the data.
    // The input should be allowed to proceed ONLY if the buffer is empty.
    // If the buffer is full, we stall the input.
    // This is correct for a buffer.
    // But what if the output is ready? We drive the data.
    // The input is stalled because the buffer is full.
    // In the next cycle, the buffer becomes empty (we released), and we can capture.
    // This is correct.

    // One correction:
    // For Type 0 (Wire), if the output is ready, we should ideally pass the data immediately.
    // If we use a register, we have 1 cycle latency.
    // If the input is valid and output is ready, we capture.
    // If the input is valid and output is NOT ready, we stall.
    // This is the same as Type 1.
    // So Type 0 and Type 1 are the same.
    
    // Final Logic Summary:
    // Type 0, 1: Capture if (s_axis_tvalid && m_axis_tready). Ready if (!reg_valid).
    // Type 2: Capture if (s_axis_tvalid). Ready if (!reg_valid || (reg_valid && m_axis_tready)).
    
    // Wait, for Type 2, if reg_valid is 1 and m_axis_tready is 1, we are ready.
    // We release the data.
    // If s_axis_tvalid is also 1, we capture new data.
    // This works.

    // One detail: The prompt says "After reset the slice is empty."
    // My reset logic sets reg_valid to 0. Correct.

    // One more detail: "Preserve tdata and enabled sidebands."
    // My logic preserves all sidebands (keep, last, id, dest, user) when capturing.
    // And drives them when releasing.
    // When empty, they are driven to 0.
    // This is correct.

    // Wait, for Type 0 (Wire), if we want to avoid the 1-cycle latency, we would need a latch.
    // But since the prompt asks for a "register slice" and "pass structural CDC", 
    // using flip-flops is the only safe way.
    // So Type 0 and Type 1 are effectively the same.
    // I will proceed with this implementation.

    // Re-verifying the "Wire" definition.
    // In some contexts, "Wire" means "No buffering".
    // If I implement it as a register, it buffers for 1 cycle.
    // Is there a way to make it non-buffering?
    // Only with a latch.
    // But latches are not safe for CDC without specific constraints.
    // Given the strict CDC requirement, I must use flip-flops.
    // Therefore, "Wire" in this context likely means "No FIFO depth", i.e., depth 1.
    // Which is what I have implemented for Type 0 and 1.

    // Wait, I need to check the "Ready" logic for Type 0/1 again.
    // If reg_valid is 1, s_axis_tready is 0.
    // This means if there is data in the register, we stall the input.
    // Even if m_axis_tready is 1?
    // Yes, because the register is full. We can't accept new data until we release the old one.
    // But if m_axis_tready is 1, we release the old one in the same cycle.
    // So in the next cycle, the register is empty, and we can accept.
    // This is correct.

    // One edge case: What if m_axis_tready is 1, but we don't release?
    // My logic: if (reg_valid && m_axis_tready) release.
    // So we always release if ready.
    // So the register will become empty in the next cycle.
    // So s_axis_tready will become 1 in the next cycle.
    // This is correct.

    // Final check on Type 2 (Skid).
    // If reg_valid is 1, m_axis_tready is 0.
    // Ready = 0.
    // We hold.
    // If s_axis_tvalid is 1, we don't capture (because we are full).
    // So s_axis_tready is 0. Correct.
    // If reg_valid is 1, m_axis_tready is 1.
    // Ready = 1.
    // We release.
    // If s_axis_tvalid is 1, we capture.
    // So we swap data. Correct.

    // One small issue:
    // In the always block for Type 2, I have:
    // if (reg_valid && m_axis_tready) release;
    // else if (!reg_valid && s_axis_tvalid) capture;
    // What if reg_valid is 1, m_axis_tready is 1, and s_axis_tvalid is 1?
    // We enter the first if, release.
    // We do NOT enter the else if.
    // So we do NOT capture.
    // This is WRONG. We should capture the new data after releasing the old one.
    // We need to allow both actions in the same cycle for Type 2.
    
    // Corrected Logic for Type 2:
    // if (reg_valid && m_axis_tready) begin
    //    release;
    // end
    // if (!reg_valid && s_axis_tvalid) begin
    //    capture;
    // end
    // Note: The second if checks !reg_valid.
    // If we released in the first block, reg_valid is still 1 (non-blocking).
    // So the second if will be false.
    // We need to check the condition BEFORE the update, or use a different structure.
    
    // Better structure for Type 2:
    // wire release_req = reg_valid && m_axis_tready;
    // wire capture_req = s_axis_tvalid;
    // 
    // if (release_req) begin
    //    release;
    // end
    // if (capture_req && !release_req) begin
    //    capture;
    // end
    // Wait, if release_req is true, we release.
    // If capture_req is true, we want to capture.
    // If both are true, we release AND capture.
    // So:
    // if (release_req) release;
    // if (capture_req) capture;
    // But if we release, reg_valid becomes 0.
    // If we capture, reg_valid becomes 1.
    // If both happen, reg_valid becomes 1 (last assignment).
    // This is correct.
    // But wait, if we release, we clear the data.
    // If we capture, we load new data.
    // If we do both, we clear then load.
    // This is correct.
    
    // However, my previous code had:
    // if (reg_valid && m_axis_tready) release;
    // else if (!reg_valid && s_axis_tvalid) capture;
    // The 'else if' prevents capturing if we are releasing.
    // This is the bug.
    // For Type 2, we should allow capturing even if we are releasing.
    
    // Revised always block for Type 2:
    // if (reg_valid && m_axis_tready) begin
    //    release;
    // end
    // if (!reg_valid && s_axis_tvalid) begin
    //    capture;
    // end
    // Wait, if reg_valid is 1 and m_axis_tready is 1, we release.
    // reg_valid is still 1 at the time of the second if check (non-blocking).
    // So !reg_valid is 0.
    // So we don't capture.
    // This is still wrong.
    
    // We need to check the conditions based on the state at the beginning of the cycle.
    // Let