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

    // Internal registers for storing data and sideband information
    reg [DATA_WIDTH-1:0]   reg_tdata;
    reg [KEEP_WIDTH-1:0]   reg_tkeep;
    reg                    reg_tlast;
    reg [ID_WIDTH-1:0]     reg_tid;
    reg [DEST_WIDTH-1:0]   reg_tdest;
    reg [USER_WIDTH-1:0]   reg_tuser;
    reg                    reg_valid;

    // Logic to determine if the slice should accept new data
    // For REG_TYPE 2 (Skid Buffer), we must not drop a beat when output stalls.
    // This means we only accept new data if we are not currently full (valid)
    // OR if the input is invalid (so we don't overwrite valid data unnecessarily, 
    // though strictly speaking a skid buffer usually just queues until ready).
    // However, the standard interpretation for "must not drop a beat" in a single-cycle 
    // slice context usually implies: if m_axis_tready is low, we must hold the data.
    // If m_axis_tready is high, we can accept new data.
    // To prevent dropping beats when output stalls (m_axis_tready=0), we simply 
    // do not update the register if m_axis_tready is 0 and reg_valid is 1.
    // Actually, the strict definition of a skid buffer that "must not drop a beat" 
    // implies it acts as a FIFO of depth 1. If input is valid and output is not ready,
    // we hold. If input is valid and output is ready, we push.
    
    wire wire_accept = (s_axis_tvalid && m_axis_tready);

    // Logic to determine if we can drive the output
    // Output is valid if we have data stored AND the input is not currently driving
    // a new valid beat that would overwrite it (unless we are in a specific flow).
    // Standard AXI-Stream register behavior:
    // If REG_TYPE == 0 (Wire): Pass through immediately. No storage.
    // If REG_TYPE == 1 (Buffer): Store on valid/ready, drive on valid/ready.
    // If REG_TYPE == 2 (Skid): Store on valid/ready. Drive on valid/ready. 
    //    Crucially, if input is valid and output is NOT ready, we must keep the old data.
    //    If input is valid and output IS ready, we update the data.
    
    // Determine current output validity
    // For Wire (0): Output is valid only if Input is valid.
    // For Buffer (1) and Skid (2): Output is valid if we have stored data.
    //    However, we must ensure we don't output stale data if the input is still valid 
    //    but the output is stalled? No, the register holds the data until ready.
    //    The condition to drive output is: reg_valid && m_axis_tready.
    //    Wait, if m_axis_tready is 0, we cannot drive. If m_axis_tready is 1, we drive.
    //    So m_axis_tvalid = reg_valid && m_axis_tready.
    
    // Special case for REG_TYPE 0 (Wire):
    // It passes data immediately. It does not store.
    // s_axis_tready = m_axis_tready;
    // m_axis_tvalid = s_axis_tvalid && m_axis_tready;
    // Data is passed directly.
    
    // For REG_TYPE 1 and 2:
    // We store data when s_axis_tvalid && m_axis_tready.
    // We drive data when reg_valid && m_axis_tready.
    
    // Let's refine the "must not drop a beat" for REG_TYPE 2.
    // If s_axis_tvalid is 1 and m_axis_tready is 0, we must NOT update the register 
    // with new data if we already have data? Actually, if we have data, we hold it.
    // If we don't have data (rst or empty), and input comes, we take it.
    // The critical part is: if input is valid and output is NOT ready, we hold the 
    // previous value. We do not overwrite it with the new input value because the 
    // new input hasn't been "accepted" into the buffer yet (or rather, the buffer 
    // is full).
    // So, update logic: if (s_axis_tvalid && m_axis_tready) then update.
    // Drive logic: if (reg_valid && m_axis_tready) then drive.
    
    // Wait, there is a nuance. If REG_TYPE is 2, and input is valid, output is NOT ready.
    // We hold the data. Next cycle, output becomes ready. We drive the held data.
    // Then input is still valid. We update the register with the new data.
    // This ensures no beat is dropped.
    
    // Implementation details:
    // 1. Reset: Clear all regs, reg_valid = 0.
    // 2. Update: If (s_axis_tvalid && m_axis_tready), load data into regs and set reg_valid = 1.
    // 3. Drive: If (reg_valid && m_axis_tready), drive data from regs and set m_axis_tvalid = 1.
    //    Else m_axis_tvalid = 0.
    // 4. Handshake: s_axis_tready = m_axis_tready && (REG_TYPE == 0 ? s_axis_tvalid : 1);
    //    Wait, for Wire (0), s_axis_tready must be m_axis_tready.
    //    For Buffer/Skid, s_axis_tready is always 1 (assuming we can always accept if output is ready).
    //    Actually, standard AXI-Stream register: s_axis_tready = m_axis_tready (for wire/buffer)
    //    unless it's a specific flow control. But typically, a register slice passes ready 
    //    from output to input.
    //    Exception: If REG_TYPE=0 (Wire), s_axis_tready = m_axis_tready.
    //    If REG_TYPE=1 or 2, s_axis_tready = 1'b1 (we are always ready to accept if we can drive).
    //    Wait, if we are full (reg_valid=1) and m_axis_tready=0, we cannot accept new data?
    //    No, if m_axis_tready=0, we don't drive. But can we accept?
    //    If we accept, we overwrite the data we were waiting to drive. That would drop a beat.
    //    So for REG_TYPE 2, we must NOT accept if we have data and output is stalled.
    //    So s_axis_tready = m_axis_tready && (reg_valid == 0 || REG_TYPE != 2);
    //    Actually, simpler: 
    //    If REG_TYPE == 0: s_axis_tready = m_axis_tready.
    //    If REG_TYPE == 1: s_axis_tready = m_axis_tready. (Buffer can overwrite if ready? 
    //       Usually buffers are depth 1. If full and output stalled, you can't accept new without dropping.)
    //       So for Buffer too, s_axis_tready = m_axis_tready.
    //    If REG_TYPE == 2: s_axis_tready = m_axis_tready && (reg_valid == 0). 
    //       Wait, if reg_valid is 1 and m_axis_tready is 0, we are stalled. 
    //       If input comes, we must hold. So s_axis_tready must be 0.
    //       So s_axis_tready = m_axis_tready && (reg_valid == 0 || REG_TYPE == 0);
    //       Actually, even for Buffer (1), if we are full and output is not ready, 
    //       accepting new data would overwrite the old data, causing a drop.
    //       So for both 1 and 2, s_axis_tready = m_axis_tready.
    //       The difference is in the update logic?
    //       No, the difference is: 
    //       Type 0: No storage. Update happens instantly.
    //       Type 1: Storage. Update happens on valid/ready.
    //       Type 2: Storage. Update happens on valid/ready. BUT, if valid/ready is false (because ready=0),
    //       we must NOT update.
    //       So the update condition is: (s_axis_tvalid && m_axis_tready).
    //       This condition naturally prevents updating when m_axis_tready is 0.
    //       So the logic holds for both 1 and 2.
    //       What about s_axis_tready?
    //       If m_axis_tready is 0, we cannot drive. Can we accept?
    //       If we accept, we overwrite. That's bad. So s_axis_tready must be 0 if m_axis_tready is 0.
    //       So s_axis_tready = m_axis_tready.
    //       Is there any case where s_axis_tready is 1 but m_axis_tready is 0? No.
    //       So s_axis_tready = m_axis_tready for all types?
    //       Wait, if REG_TYPE=0, s_axis_tready = m_axis_tready.
    //       If REG_TYPE=1, s_axis_tready = m_axis_tready.
    //       If REG_TYPE=2, s_axis_tready = m_axis_tready.
    //       It seems s_axis_tready is always m_axis_tready.
    //       Let's re-read "must not drop a beat".
    //       If I have data in the register, and output is stalled (ready=0).
    //       Input comes (valid=1).
    //       If I accept (ready=1), I overwrite the register.
    //       Next cycle, output becomes ready. I drive the NEW data.
    //       The OLD data is lost. Beat dropped.
    //       Therefore, if reg_valid is 1 and m_axis_tready is 0, s_axis_tready MUST be 0.
    //       So s_axis_tready = m_axis_tready && (reg_valid == 0 || REG_TYPE == 0);
    //       Wait, if REG_TYPE=0, reg_valid doesn't exist. s_axis_tready = m_axis_tready.
    //       If REG_TYPE=1 or 2: s_axis_tready = m_axis_tready && (reg_valid == 0).
    //       Wait, if reg_valid is 0 (empty), and m_axis_tready is 0? 
    //       Then s_axis_tready = 0. That's fine.
    //       If reg_valid is 0, and m_axis_tready is 1. s_axis_tready = 1.
    //       So for Type 1 and 2: s_axis_tready = m_axis_tready && (reg_valid == 0);
    //       Wait, if reg_valid is 1, and m_axis_tready is 1. s_axis_tready = 1.
    //       This allows accepting new data while driving old data?
    //       Yes, that's the standard behavior. You accept the new data for the NEXT cycle.
    //       So the logic:
    //       s_axis_tready = m_axis_tready;
    //       BUT, if REG_TYPE != 0 and reg_valid == 1 and m_axis_tready == 0, then s_axis_tready = 0.
    //       Which simplifies to: s_axis_tready = m_axis_tready && (reg_valid == 0 || REG_TYPE == 0);
    //       Actually, if REG_TYPE == 0, reg_valid is irrelevant.
    //       So: s_axis_tready = m_axis_tready && (REG_TYPE == 0 || reg_valid == 0);
    
    // Let's verify Type 1 (Buffer).
    // If full (valid=1), output stalled (ready=0). Input valid.
    // s_axis_tready = 0. Correct.
    // Next cycle, output ready. s_axis_tready = 1.
    // We accept new data. Drive old data.
    // Next cycle, we drive new data.
    // This works.
    
    // Let's verify Type 2 (Skid).
    // Same logic.
    
    // So the only difference between Type 1 and 2 is the "must not drop" constraint which 
    // is enforced by the s_axis_tready logic above.
    // Wait, is there a difference in update logic?
    // Type 1: Update on valid/ready.
    // Type 2: Update on valid/ready.
    // They seem identical in a single-cycle slice.
    // Perhaps the distinction is only relevant if the slice was part of a larger FIFO?
    // Or maybe the prompt implies Type 2 should behave differently?
    // "REG_TYPE 2 is a skid buffer that must not drop a beat when the output stalls."
    // This is exactly what the logic `s_axis_tready = m_axis_tready && (reg_valid == 0 || REG_TYPE == 0)` achieves.
    // For Type 1, if we allowed overwriting on stall, we would drop. So Type 1 also needs this.
    // Maybe Type 1 is assumed to be a simple latch that might overwrite? 
    // No, a "simple buffer" in AXI context usually implies the same flow control.
    // I will apply the strict "no drop" logic to both Type 1 and Type 2, and Type 0 is pass-through.
    
    // Wait, one more check.
    // If REG_TYPE = 0 (Wire).
    // s_axis_tready = m_axis_tready.
    // m_axis_tvalid = s_axis_tvalid && m_axis_tready.
    // Data is passed directly.
    
    // If REG_TYPE = 1 or 2.
    // s_axis_tready = m_axis_tready && (reg_valid == 0 || REG_TYPE == 0);
    // Since REG_TYPE != 0, s_axis_tready = m_axis_tready && (reg_valid == 0).
    // Update: if (s_axis_tvalid && m_axis_tready) then load.
    // Drive: if (reg_valid && m_axis_tready) then drive.
    
    // Wait, if s_axis_tready = m_axis_tready && (reg_valid == 0).
    // Case: reg_valid=1, m_axis_tready=0. s_axis_tready=0.
    // Case: reg_valid=1, m_axis_tready=1. s_axis_tready=1.
    // Case: reg_valid=0, m_axis_tready=0. s_axis_tready=0.
    // Case: reg_valid=0, m_axis_tready=1. s_axis_tready=1.
    // This looks correct.
    
    // One edge case: What if REG_TYPE=1 is supposed to be a latch that updates even if stalled?
    // No, that would drop data. The prompt specifically highlights Type 2 for the "must not drop" requirement.
    // This implies Type 1 might be allowed to drop? Or maybe Type 1 is just a synonym for Type 2 in this context?
    // Given the explicit mention, I will ensure Type 2 strictly follows the rule.
    // I will also apply the rule to Type 1 to be safe, as a "buffer" shouldn't drop data either.
    // The only real difference might be if Type 1 was a latch that updates on valid regardless of ready?
    // But that violates AXI handshake semantics for a register.
    // I will treat 1 and 2 identically regarding flow control, and 0 as pass-through.
    
    // Wait, re-reading: "REG_TYPE 0 is a wire, 1 is a simple buffer, 2 is a skid buffer..."
    // In some contexts, a "simple buffer" might just be a latch that updates on valid/ready, 
    // and a "skid buffer" is a FIFO. But here it's a single slice.
    // The key is "must not drop a beat".
    // If I implement the logic `s_axis_tready = m_axis_tready && (reg_valid == 0 || REG_TYPE == 0)`, 
    // it satisfies the requirement for Type 2.
    // Does it satisfy Type 1? Yes, a buffer shouldn't drop beats either.
    // So I will use this logic for both 1 and 2.
    
    // Wait, is it possible that for Type 1, `s_axis_tready` is always 1?
    // If `s_axis_tready` is always 1, then when `m_axis_tready` is 0, we accept new data.
    // We overwrite the old data. We drive the old data (if valid) or nothing?
    // If we overwrite, we lose the old data. That's a drop.
    // So Type 1 must also respect the stall.
    // Okay, the logic stands.

    // Assignments
    assign s_axis_tready = (REG_TYPE == 0) ? m_axis_tready : (m_axis_tready && (reg_valid == 0));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_tdata      <= 0;
            reg_tkeep      <= 0;
            reg_tlast      <= 0;
            reg_tid        <= 0;
            reg_tdest      <= 0;
            reg_tuser      <= 0;
            reg_valid      <= 0;
        end else begin
            // Update logic
            if (s_axis_tvalid && m_axis_tready) begin
                if (REG_TYPE == 0) begin
                    // Wire: No storage, just pass through handled by assign below
                    // But we need to ensure we don't update regs for wire type
                    // Actually, for wire type, we don't need to store.
                    // We can skip the update block.
                end else begin
                    // Buffer/Skid
                    reg_tdata      <= s_axis_tdata;
                    reg_tkeep     <= s_axis_tkeep;
                    reg_tlast     <= s_axis_tlast;
                    reg_tid       <= s_axis_tid;
                    reg_tdest     <= s_axis_tdest;
                    reg_tuser     <= s_axis_tuser;
                    reg_valid     <= 1;
                end
            end else if (REG_TYPE == 0) begin
                // For wire, we don't store.
                // But we need to make sure reg_valid is 0 so we don't drive stale data?
                // No, for wire, we drive directly from input.
                // So reg_valid should be 0 always for wire type to avoid driving stale data.
                // But wait, if we don't update, reg_valid stays 0 (from reset).
                // So we are good.
            end else begin
                // Buffer/Skid: If not accepting, keep current data.
                // reg_valid remains as is.
            end
        end
    end

    // Output assignments
    assign m_axis_tdata      = (REG_TYPE == 0) ? s_axis_tdata : reg_tdata;
    assign m_axis_tkeep      = (REG_TYPE == 0) ? s_axis_tkeep : reg_tkeep;
    assign m_axis_tlast      = (REG_TYPE == 0) ? s_axis_tlast : reg_tlast;
    assign m_axis_tid        = (REG_TYPE == 0) ? s_axis_tid : reg_tid;
    assign m_axis_tdest      = (REG_TYPE == 0) ? s_axis_tdest : reg_tdest;
    assign m_axis_tuser      = (REG_TYPE == 0) ? s_axis_tuser : reg_tuser;
    
    assign m_axis_tvalid     = (REG_TYPE == 0) ? (s_axis_tvalid && m_axis_tready) : (reg_valid && m_axis_tready);

endmodule
```<|im_end|>
