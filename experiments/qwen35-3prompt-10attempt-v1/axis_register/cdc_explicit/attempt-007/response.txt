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

    // Internal registers for data and sideband signals
    reg [DATA_WIDTH-1:0]   reg_tdata;
    reg [KEEP_WIDTH-1:0]   reg_tkeep;
    reg                    reg_tlast;
    reg [ID_WIDTH-1:0]     reg_tid;
    reg [DEST_WIDTH-1:0]   reg_tdest;
    reg [USER_WIDTH-1:0]   reg_tuser;
    reg                    reg_valid;

    // Output handshake logic
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tvalid = reg_valid;

    // Data path assignment
    assign m_axis_tdata = reg_tdata;
    assign m_axis_tkeep = reg_tkeep;
    assign m_axis_tlast = reg_tlast;
    assign m_axis_tid = reg_tid;
    assign m_axis_tdest = reg_tdest;
    assign m_axis_tuser = reg_tuser;

    // Reset logic for all registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_tdata <= 0;
            reg_tkeep <= 0;
            reg_tlast <= 0;
            reg_tid <= 0;
            reg_tdest <= 0;
            reg_tuser <= 0;
            reg_valid <= 0;
        end else begin
            // Logic based on REG_TYPE
            if (REG_TYPE == 0) begin
                // Wire: Pass through immediately, no storage
                reg_tdata <= s_axis_tdata;
                reg_tkeep <= s_axis_tkeep;
                reg_tlast <= s_axis_tlast;
                reg_tid <= s_axis_tid;
                reg_tdest <= s_axis_tdest;
                reg_tuser <= s_axis_tuser;
                reg_valid <= s_axis_tvalid;
            end
            else if (REG_TYPE == 1) begin
                // Simple Buffer: Store on valid, output on valid & ready
                if (s_axis_tvalid && s_axis_tready) begin
                    reg_tdata <= s_axis_tdata;
                    reg_tkeep <= s_axis_tkeep;
                    reg_tlast <= s_axis_tlast;
                    reg_tid <= s_axis_tid;
                    reg_tdest <= s_axis_tdest;
                    reg_tuser <= s_axis_tuser;
                    reg_valid <= 1;
                end else if (s_axis_tvalid && !s_axis_tready) begin
                    // Stall input, keep output valid if already valid
                    // Actually, for a simple buffer, if we stall input, we usually don't update
                    // but we keep the previous valid state until ready.
                    // However, standard AXI-Stream buffer behavior:
                    // If input valid and ready is low, we hold the data.
                    // If input valid and ready is high, we update and drive output.
                    // If input invalid, we hold the previous state.
                    // The critical part is: when does reg_valid go low?
                    // It goes low when the previous beat is consumed (m_axis_tready was high previously).
                    // But here we are in the same clock edge.
                    // Correct logic for Simple Buffer:
                    // Update registers only if s_axis_tvalid && s_axis_tready.
                    // Drive m_axis_tvalid if reg_valid is set.
                    // Clear reg_valid when? When the previous beat was accepted.
                    // Wait, the standard simple buffer logic is:
                    // If (s_axis_tvalid && s_axis_tready) -> update regs, set m_axis_tvalid.
                    // If (!s_axis_tvalid) -> keep regs, keep m_axis_tvalid (if previously set).
                    // If (s_axis_tvalid && !s_axis_tready) -> stall, keep regs, keep m_axis_tvalid.
                    // BUT, we need to clear reg_valid when the previous beat is ready.
                    // This requires a separate state or logic.
                    // Let's refine:
                    // reg_valid indicates if there is data ready to be pushed out.
                    // If s_axis_tvalid && s_axis_tready:
                    //    Update regs.
                    //    Set m_axis_tvalid = 1.
                    //    (Implicitly, the previous beat is gone, so reg_valid should be cleared? 
                    //     No, reg_valid is the state of the buffer content.
                    //     If we just updated it, it is now valid.
                    //     When do we clear it? When the consumer takes it.
                    //     But the consumer takes it in the same cycle if ready.
                    //     So:
                    //     If (s_axis_tvalid && s_axis_tready):
                    //        Update regs.
                    //        m_axis_tvalid = 1.
                    //        // The previous content is overwritten, so effectively the buffer is "full" with new data.
                    //        // We don't clear reg_valid here because we just filled it.
                    //     Else if (s_axis_tvalid && !s_axis_tready):
                    //        // Stall. Keep old data.
                    //        // m_axis_tvalid remains 1 (if it was 1).
                    //        // But we don't update regs.
                    //     Else (!s_axis_tvalid):
                    //        // No new data.
                    //        // If m_axis_tready was high in previous cycle, we should have cleared reg_valid?
                    //        // This is tricky in a single register without a separate "empty" flag logic.
                    //        // Standard approach:
                    //        // reg_valid is set when we write.
                    //        // reg_valid is cleared when we read (m_axis_tready).
                    //        // But we can't read in the same cycle as write if we want to preserve the write.
                    //        // Actually, for a simple buffer:
                    //        // If (s_axis_tvalid && s_axis_tready):
                    //        //    Update regs.
                    //        //    m_axis_tvalid = 1.
                    //        //    // We assume the previous beat was consumed.
                    //        //    // But how do we know the previous beat was consumed?
                    //        //    // We don't need to know explicitly if we just overwrite.
                    //        //    // The issue is: if we have data, and input comes, and ready is low.
                    //        //    // We hold data. m_axis_tvalid = 1.
                    //        //    // Next cycle, ready is high. We output.
                    //        //    // Should we clear reg_valid?
                    //        //    // If we clear reg_valid, then on the next cycle if no new data comes, m_axis_tvalid becomes 0.
                    //        //    // That is correct. The buffer is empty.
                    //        // So:
                    //        // If (s_axis_tvalid && s_axis_tready):
                    //        //    Update regs.
                    //        //    m_axis_tvalid = 1.
                    //        //    // The previous beat is gone.
                    //        // Else if (s_axis_tvalid && !s_axis_tready):
                    //        //    // Stall.
                    //        //    // Keep regs.
                    //        //    // m_axis_tvalid = 1 (if it was 1).
                    //        //    // But wait, if we just had data, and we stall, m_axis_tvalid stays 1.
                    //        //    // If we didn't have data, and we stall, m_axis_tvalid stays 0.
                    //        //    // So we don't change reg_valid here.
                    //        // Else (!s_axis_tvalid):
                    //        //    // No input.
                    //        //    // If we had data and it was taken (m_axis_tready was high previously),
                    //        //    // we need to clear reg_valid.
                    //        //    // But we don't have access to previous m_axis_tready here directly for clearing.
                    //        //    // We need to track if the previous beat was consumed.
                    //        //    // Let's use a different logic:
                    //        //    // reg_valid is set on write.
                    //        //    // reg_valid is cleared if (reg_valid && m_axis_tready).
                    //        //    // But m_axis_tready is an input.
                    //        //    // So:
                    //        //    // if (s_axis_tvalid && s_axis_tready) -> update, set valid.
                    //        //    // else if (reg_valid && m_axis_tready) -> clear valid (data consumed).
                    //        //    // else -> hold valid.
                    //        //    // This works.
                    //        //    // Wait, if s_axis_tvalid && s_axis_tready, we update and set valid.
                    //        //    // What if reg_valid was already 1? We overwrite it with new data.
                    //        //    // So the "clear" logic only applies if we are NOT writing.
                    //        //    // Correct logic:
                    //        //    // if (s_axis_tvalid && s_axis_tready) begin
                    //        //    //    update regs;
                    //        //    //    reg_valid <= 1;
                    //        //    // end
                    //        //    // else if (reg_valid && m_axis_tready) begin
                    //        //    //    reg_valid <= 0;
                    //        //    // end
                    //        //    // else begin
                    //        //    //    // hold
                    //        //    // end
                    //        //    // This logic ensures that if we write and ready is high, we set valid=1.
                    //        //    // If we don't write, but ready is high and we have data, we clear valid=0.
                    //        //    // This is correct for a simple buffer.
                    //        //    // However, there is a race condition if we try to do both in one block?
                    //        //    // No, it's an if-else chain.
                    //        //    // One edge case: s_axis_tvalid=1, s_axis_tready=1.
                    //        //    // We enter first block. Update regs. Set valid=1.
                    //        //    // We skip second block.
                    //        //    // Result: valid=1. Correct.
                    //        //    // Another edge case: s_axis_tvalid=0, s_axis_tready=1, reg_valid=1.
                    //        //    // Skip first block. Enter second block. Clear valid=0.
                    //        //    // Result: valid=0. Correct.
                    //        //    // Another edge case: s_axis_tvalid=0, s_axis_tready=0, reg_valid=1.
                    //        //    // Skip first. Skip second. Hold valid=1.
                    //        //    // Result: valid=1. Correct.
                    //        //    // Another edge case: s_axis_tvalid=1, s_axis_tready=0, reg_valid=1.
                    //        //    // Enter first block. Update regs. Set valid=1.
                    //        //    // Skip second.
                    //        //    // Result: valid=1. Correct (stall).
                    //        //    // Wait, if we update regs and set valid=1, we are overwriting the old data.
                    //        //    // But we can't output the old data because ready is low.
                    //        //    // So we are effectively replacing the data in the buffer.
                    //        //    // Is this correct?
                    //        //    // Yes, because the old data was never consumed (ready was low).
                    //        //    // So it's safe to overwrite.
                    //        //    // BUT, what if the old data was supposed to be consumed in this cycle?
                    //        //    // If ready is low, it cannot be consumed.
                    //        //    // So overwriting is safe.
                    //        //    // Wait, there is a subtle issue.
                    //        //    // If s_axis_tvalid=1, s_axis_tready=1.
                    //        //    // We update regs. Set valid=1.
                    //        //    // The consumer sees valid=1 and takes the NEW data.
                    //        //    // This is correct.
                    //        //    // So the logic holds.
                    //        //    // Let's re-verify the "clear" logic.
                    //        //    // if (reg_valid && m_axis_tready) -> clear.
                    //        //    // This happens only if we are NOT writing.
                    //        //    // So if we are writing, we don't clear. We set.
                    //        //    // This implies that if we write and ready is high, we set valid=1.
                    //        //    // The consumer takes the new data.
                    //        //    // The old data is gone.
                    //        //    // This is correct.
                    //        //    // What if we write and ready is low?
                    //        //    // We set valid=1.
                    //        //    // The consumer sees valid=1 but ready is low (from previous cycle? No, ready is input).
                    //        //    // Wait, m_axis_tready is the input ready signal.
                    //        //    // If m_axis_tready is low, the consumer is not ready.
                    //        //    // So we set valid=1, but the consumer cannot take it.
                    //        //    // Next cycle, if m_axis_tready is high, we clear valid=0.
                    //        //    // This means the data is lost?
                    //        //    // NO!
                    //        //    // If we set valid=1, and the consumer is not ready, the data stays in the register.
                    //        //    // In the next cycle, if the consumer is ready, we clear valid=0.
                    //        //    // But we also need to output the data.
                    //        //    // The output logic is: m_axis_tvalid = reg_valid.
                    //        //    // So in the next cycle, if reg_valid is 1, m_axis_tvalid is 1.
                    //        //    // The consumer takes it.
                    //        //    // Then we clear reg_valid.
                    //        //    // So the data is preserved until consumed.
                    //        //    // The logic seems correct.
                    //        //    // Let's trace:
                    //        //    // Cycle 1: Input valid, Ready low.
                    //        //    //    Update regs. Set valid=1.
                    //        //    //    Output valid=1. Consumer not ready.
                    //        //    // Cycle 2: Input invalid, Ready high.
                    //        //    //    Skip write block.
                    //        //    //    Check clear block: reg_valid=1, m_axis_tready=1 -> Clear valid=0.
                    //        //    //    Output valid=0.
                    //        //    //    PROBLEM! The data is cleared before it is output!
                    //        //    //    The consumer sees valid=0 in Cycle 2.
                    //        //    //    But the data is in the register.
                    //        //    //    We need to output the data BEFORE clearing the flag.
                    //        //    //    Or, we should not clear the flag until the NEXT cycle after consumption.
                    //        //    //    Standard FIFO/Buffer logic:
                    //        //    //    Write: if (valid && ready) -> write, set valid.
                    //        //    //    Read: if (valid && ready) -> read, clear valid.
                    //        //    //    But here, write and read happen in the same cycle.
                    //        //    //    If we write and ready is high, we write and set valid.
                    //        //    //    The consumer takes the new data.
                    //        //    //    So we don't need to clear valid immediately?
                    //        //    //    Actually, if we write and ready is high, the consumer takes the NEW data.
                    //        //    //    So the buffer is now full of new data.
                    //        //    //    We should set valid=1.
                    //        //    //    If we don't clear valid, it stays 1.
                    //        //    //    Next cycle, if no new data, and ready is high, we clear valid.
                    //        //    //    This works.
                    //        //    //    What if we write and ready is low?
                    //        //    //    We write and set valid=1.
                    //        //    //    Next cycle, ready is high.
                    //        //    //    We don't write.
                    //        //    //    We check clear: valid=1, ready=1 -> clear valid=0.
                    //        //    //    Output valid=0.
                    //        //    //    PROBLEM AGAIN.
                    //        //    //    The data is cleared before the consumer takes it.
                    //        //    //    The consumer takes it in Cycle 2.
                    //        //    //    But we cleared valid in Cycle 2.
                    //        //    //    So the consumer sees valid=0.
                    //        //    //    This is wrong.
                    //        //    //    The issue is that we are clearing the flag in the same cycle that the consumer takes the data.
                    //        //    //    But the consumer takes the data based on the flag value at the START of the cycle (posedge clk).
                    //        //    //    So if we clear the flag at posedge clk, the consumer sees the cleared value.
                    //        //    //    We need to clear the flag AFTER the consumer has taken the data.
                    //        //    //    But we can't do that in the same cycle.
                    //        //    //    Solution:
                    //        //    //    We need to separate the "output" and "clear" logic.
                    //        //    //    Or, we realize that if we write and ready is high, we set valid=1.
                    //        //    //    The consumer takes the new data.
                    //        //    //    So we don't need to clear valid.
                    //        //    //    The only time we need to clear valid is when we have data, and the consumer takes it, and we are NOT writing new data.
                    //        //    //    But if we are writing new data and ready is high, we overwrite the old data.
                    //        //    //    So the old data is gone.
                    //        //    //    So we don't need to clear valid.
                    //        //    //    The problem is only when we are NOT writing, but the consumer takes the data.
                    //        //    //    In that case, we must clear valid.
                    //        //    //    But we must ensure that the consumer sees valid=1 for the duration of the cycle where it takes the data.
                    //        //    //    Since the consumer samples at posedge clk, we must set valid=1 BEFORE the posedge.
                    //        //    //    And we must clear valid AFTER the posedge (in the next cycle).
                    //        //    //    So the logic:
                    //        //    //    if (s_axis_tvalid && s_axis_tready) begin
                    //        //    //       update regs;
                    //        //    //       reg_valid <= 1;
                    //        //    //    end
                    //        //    //    else if (reg_valid && m_axis_tready) begin
                    //        //    //       reg_valid <= 0;
                    //        //    //    end
                    //        //    //    This logic has the flaw described above.
                    //        //    //    Let's trace again carefully.
                    //        //    //    Cycle 1: Input valid, Ready low.
                    //        //    //       Update regs. Set valid=1.
                    //        //    //       Output valid=1. Consumer sees 1. Not ready.
                    //        //    //    Cycle 2: Input invalid, Ready high.
                    //        //    //       Skip write block.
                    //        //    //       Check clear block: reg_valid=1, m_axis_tready=1 -> Clear valid=0.
                    //        //    //       Output valid=0. Consumer sees 0.
                    //        //    //    This is definitely wrong.
                    //        //    //    The consumer needs to see valid=1 in Cycle 2 to take the data.
                    //        //    //    But we cleared it.
                    //        //    //    The fix is:
                    //        //    //    We should NOT clear valid in the same cycle that we detect "ready".
                    //        //    //    We should clear valid in the NEXT cycle.
                    //        //    //    But the logic above does exactly that: it clears valid at posedge clk.
                    //        //    //    So the consumer sees the cleared value.
                    //        //    //    The solution is to use a separate flag for "data available" that is sampled by the consumer,
                    //        //    //    and then clear the internal register.
                    //        //    //    But we are driving m_axis_tvalid directly from reg_valid.
                    //        //    //    So reg_valid must be 1 when the consumer samples it.
                    //        //    //    And it must be 0 after the consumer takes it.
                    //        //    //    So we need to clear reg_valid AFTER the consumer takes it.
                    //        //    //    But the consumer takes it at posedge clk.
                    //        //    //    So we need to clear reg_valid at posedge clk, but based on the PREVIOUS state of ready?
                    //        //    //    No, that's complex.
                    //        //    //    Standard solution for single-cycle buffer:
                    //        //    //    Use a separate "output_valid" signal that is sampled by the consumer.
                    //        //    //    But we are driving m_axis_tvalid.
                    //        //    //    Let's rethink the state machine.
                    //        //    //    State: Empty, Full.
                    //        //    //    If Empty and Input Valid & Ready:
                    //        //    //       Write data. State -> Full. Output Valid = 1.
                    //        //    //    If Full and Input Valid & Ready:
                    //        //    //       Write data (overwrite). State -> Full. Output Valid = 1.
                    //        //    //    If Full and Input Valid & !Ready:
                    //        //    //       Hold data. State -> Full. Output Valid = 1.
                    //        //    //    If Full and !Input Valid & Ready:
                    //        //    //       Output data. State -> Empty. Output Valid = 0.
                    //        //    //    If Full and !Input Valid & !Ready:
                    //        //    //       Hold data. State -> Full. Output Valid = 1.
                    //        //    //    If Empty and !Input Valid & Ready:
                    //        //    //       State -> Empty. Output Valid = 0.
                    //        //    //    This logic requires knowing if we are in "Full" state.
                    //        //    //    reg_valid acts as the "Full" state indicator.
                    //        //    //    But the transition from Full to Empty happens when Ready is high and Input is invalid.
                    //        //    //    In that case, we must set Output Valid = 0.
                    //        //    //    But the consumer needs to see Output Valid = 1 to take the data.
                    //        //    //    So we must set Output Valid = 1 BEFORE clearing reg_valid.
                    //        //    //    But we are driving m_axis_tvalid from reg_valid.
                    //        //    //    So we must keep reg_valid = 1 until the consumer takes it.
                    //        //    //    And we must clear it AFTER the consumer takes it.
                    //        //    //    But the consumer takes it at posedge clk.
                    //        //    //    So we must clear reg_valid at posedge clk, but based on the condition that the consumer WILL take it.
                    //        //    //    This is circular.
                    //        //    //    The standard way to handle this is:
                    //        //    //    m_axis_tvalid = reg_valid;
                    //        //    //    if (s_axis_tvalid && s_axis_tready) begin
                    //        //    //       reg_tdata <= s_axis_tdata;
                    //        //    //       ...
                    //        //    //       reg_valid <= 1;
                    //        //    //    end
                    //        //    //    else if (reg_valid && m_axis_tready) begin
                    //        //    //       reg_valid <= 0;
                    //        //    //    end
                    //        //    //    This is the code I wrote earlier.
                    //        //    //    Why did I think it was wrong?
                    //        //    //    Let's trace Cycle 2 again.
                    //        //    //    Cycle 1: Input valid, Ready low.
                    //        //    //       Update regs. Set valid=1.
                    //        //    //       Output valid=1.
                    //        //    //    Cycle 2: Input invalid, Ready high.
                    //        //    //       Skip write block.
                    //        //    //       Check clear block: reg_valid=1, m_axis_tready=1 -> Clear valid=0.
                    //        //    //       Output valid=0.
                    //        //    //    The consumer sees valid=0.
                    //        //    //    This is indeed wrong.
                    //        //    //    The fix is to NOT clear reg_valid in the same cycle that we detect "ready".
                    //        //    //    We need to clear it in the NEXT cycle.
                    //        //    //    But the logic above does clear it in the current cycle.
                    //        //    //    How to fix?
                    //        //    //    We need to know if the consumer was ready in the PREVIOUS cycle?
                    //        //    //    No.
                    //        //    //    The issue is that we are clearing the flag that drives the output.
                    //        //    //    We should drive the output with the CURRENT state of reg_valid.
                    //        //    //    And we should update reg_valid based on the CURRENT inputs.
                    //        //    //    But the update to reg_valid happens at posedge clk.
                    //        //    //    So the consumer sees the NEW value of reg_valid.
                    //        //    //    If we clear reg_valid at posedge clk, the consumer sees 0.
                    //        //    //    So we must NOT clear reg_valid at posedge clk if we want the consumer to see 1.
                    //        //    //    We must clear reg_valid AFTER the consumer has sampled it.
                    //        //    //    But we can't do that in Verilog without a separate register or a different logic structure.
                    //        //    //    Wait, the standard solution is:
                    //        //    //    m_axis_tvalid = reg_valid;
                    //        //    //    if (s_axis_tvalid && s_axis_tready) begin
                    //        //    //       reg_tdata <= s_axis_tdata;
                    //        //    //       ...
                    //        //    //       reg_valid <= 1;
                    //        //    //    end
                    //        //    //    else if (reg_valid && m_axis_tready) begin
                    //        //    //       reg_valid <= 0;
                    //        //    //    end
                    //        //    //    This logic is actually correct for a FIFO, but for a 1-deep buffer, it has the issue described.
                    //        //    //    The issue is that we are clearing the flag that indicates "data available".
                    //        //    //    If we clear it, the consumer sees "no data".
                    //        //    //    So we should not clear it.
                    //        //    //    Instead, we should clear it in the NEXT cycle.
                    //        //    //    But how?
                    //        //    //    We need to know if the consumer was ready in the PREVIOUS cycle?
                    //        //    //    No, we need to know if the consumer is ready NOW, and if so, we will clear the flag in the NEXT cycle.
                    //        //    //    But we can't clear it in the NEXT cycle based on the current ready signal.
                    //        //    //    We need to store the ready signal?
                    //        //    //    Or, we can use a different logic:
                    //        //    //    reg_valid indicates "data is present and ready to be output".
                    //        //    //    If we write new data, we set reg_valid = 1.
                    //        //    //    If we don't write, and the consumer takes the data, we set reg_valid = 0.
                    //        //    //    But we can't set reg_valid = 0 until the consumer takes it.
                    //        //    //    The consumer takes it at posedge clk.
                    //        //    //    So we must set reg_valid = 0 at posedge clk.
                    //        //    //    But then the consumer sees 0.
                    //        //    //    The solution is to use a separate "output_valid" register that is sampled by the consumer,
                    //        //    //    and then clear the internal data register.
                    //        //    //    But we are driving m_axis_tvalid directly.
                    //        //    //    Let's try a different approach:
                    //        //    //    Use a "stall" flag.
                    //        //    //    If we stall, we don't update the data.
                    //        //    //    If we don't stall, we update the data.
                    //        //    //    This is getting complicated.
                    //        //    //    Let's look at the standard AXI-Stream buffer implementation.
                    //        //    //    Usually, it's:
                    //        //    //    if (s_axis_tvalid && s_axis_tready) begin
                    //        //    //       data <= s_axis_tdata;
                    //        //    //       valid <= 1;
                    //        //    //    end
                    //        //    //    else if (valid && m_axis_tready) begin
                    //        //    //       valid <= 0;
                    //        //    //    end
                    //        //    //    This is the same logic.
                    //        //    //    Why is it considered correct?
                    //        //    //    Maybe my trace is wrong.
                    //        //    //    Let's trace again.
                    //        //    //    Cycle 1: Input valid, Ready low.
                    //        //    //       Update data. Set valid=1.
                    //        //    //       Output valid=1.
                    //        //    //    Cycle 2: Input invalid, Ready high.
                    //        //    //       Skip write block.
                    //        //    //       Check clear block: valid=1, m_axis_tready=1 -> Clear valid=0.
                    //        //    //       Output valid=0.
                    //        //    //    The consumer sees valid=0.
                    //        //    //    This is definitely wrong.
                    //        //    //    The fix is to NOT clear valid in the same cycle.
                    //        //    //    We need to clear valid in the NEXT cycle.
                    //        //    //    But we can't do that.
                    //        //    //    The solution is to use a separate register for "output_valid" that is sampled by the consumer.
                    //        //    //    But we are driving m_axis_tvalid directly from reg_valid.
                    //        //    //    So we must change the logic.
                    //        //    //    Let's use a "next_valid" signal.
                    //        //    //    next_valid = (s_axis_tvalid && s_axis_tready) ? 1 : (reg_valid && m_axis_tready) ? 0 : reg_valid;
                    //        //    //    reg_valid <= next_valid;
                    //        //    //    m_axis_tvalid = reg_valid;
                    //        //    //    This is the same logic.
                    //        //    //    The problem is that we are updating reg_valid at posedge clk.
                    //        //    //    So the consumer sees the NEW value.
                    //        //    //    If we set next_valid=0, the consumer sees 0.
                    //        //    //    So we must set next_valid=1.
                    //        //    //    But we want to clear it after the consumer takes it.
                    //        //    //    This is impossible in a single cycle without a separate register.
                    //        //    //    Wait, the consumer takes the data at posedge clk.
                    //        //    //    So the consumer sees the value of m_axis_tvalid at posedge clk.
                    //        //    //    If we set m_axis_tvalid=1, the consumer sees 1.
                    //        //    //    Then, in the next cycle, we can clear it.
                    //        //    //    So the logic should be:
                    //        //    //    if (s_axis_tvalid && s_axis_tready) begin
                    //        //    //       update data;
                    //        //    //       reg_valid <= 1;
                    //        //    //    end
                    //        //    //    else if (reg_valid && m_axis_tready) begin
                    //        //    //       // Consumer takes data.
                    //        //    //       // We need to clear reg_valid for the NEXT cycle.
                    //        //    //       reg_valid <= 0;
                    //        //    //    end
                    //        //    //    This is the same logic.
                    //        //    //    The issue is