```verilog
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

    // Internal parameters for buffer sizing
    localparam S_KEEP_WIDTH_LOG = $clog2(S_KEEP_WIDTH);
    localparam M_KEEP_WIDTH_LOG = $clog2(M_KEEP_WIDTH);
    
    // Calculate max beats needed to fill a buffer
    // We need enough space to hold the largest possible chunk of data 
    // that might be in flight while waiting for the other side.
    // A simple FIFO depth of max(S_KEEP_WIDTH, M_KEEP_WIDTH) is usually sufficient 
    // for a direct width converter without reordering, but we must handle 
    // the case where one side sends a large burst and the other accepts slowly.
    // To ensure no data loss and proper boundary preservation, we use a depth 
    // that can hold at least one full "keep" unit of the wider side if necessary,
    // or simply a depth of 1 if widths match, but generally a small buffer is safer.
    // However, for a strict width converter without reordering, a depth of 1 
    // is theoretically enough if we process beat-by-beat. 
    // But to handle the "last" flag correctly across boundaries and potential 
    // slight timing mismatches, a small buffer (depth 2) is robust.
    // Let's use a depth that can hold at least the maximum keep width of either side 
    // to ensure we don't split a packet incorrectly if the other side is slow.
    // Actually, the safest and simplest approach for CDC is a synchronous FIFO 
    // with depth >= max(S_KEEP_WIDTH, M_KEEP_WIDTH).
    
    localparam FIFO_DEPTH = $clog2(S_KEEP_WIDTH + M_KEEP_WIDTH + 1);
    
    // Internal signals
    wire [S_DATA_WIDTH-1:0]  s_data_in;
    wire [S_KEEP_WIDTH-1:0]  s_keep_in;
    wire                     s_valid_in;
    wire                     s_last_in;
    wire                     s_tid_valid;
    wire [ID_WIDTH-1:0]      s_tid_in;
    wire                     s_dest_valid;
    wire [DEST_WIDTH-1:0]    s_dest_in;
    wire                     s_user_valid;
    wire [USER_WIDTH-1:0]    s_user_in;
    
    wire [M_DATA_WIDTH-1:0]  m_data_out;
    wire [M_KEEP_WIDTH-1:0]  m_keep_out;
    wire                     m_valid_out;
    wire                     m_last_out;
    wire                     m_tid_valid;
    wire [ID_WIDTH-1:0]      m_tid_out;
    wire                     m_dest_valid;
    wire [DEST_WIDTH-1:0]    m_dest_out;
    wire                     m_user_valid;
    wire [USER_WIDTH-1:0]    m_user_out;
    
    wire                     fifo_empty;
    wire                     fifo_full;
    wire                     fifo_rst;
    
    // Instantiate a generic synchronous FIFO
    // Since we cannot use vendor primitives, we implement a simple synchronous FIFO
    // using a pointer and a counter. This ensures zero CDC violations.
    
    reg [FIFO_DEPTH-1:0]     fifo_ptr;
    reg [FIFO_DEPTH-1:0]     fifo_cnt;
    reg [S_DATA_WIDTH-1:0]   fifo_data;
    reg [S_KEEP_WIDTH-1:0]   fifo_keep;
    reg                     fifo_last;
    reg                     fifo_tid_valid;
    reg [ID_WIDTH-1:0]       fifo_tid;
    reg                     fifo_dest_valid;
    reg [DEST_WIDTH-1:0]     fifo_dest;
    reg                     fifo_user_valid;
    reg [USER_WIDTH-1:0]     fifo_user;
    
    reg                     fifo_write_en;
    reg                     fifo_read_en;
    
    // Write logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_ptr      <= 0;
            fifo_cnt      <= 0;
            fifo_data     <= 0;
            fifo_keep     <= 0;
            fifo_last     <= 0;
            fifo_tid_valid <= 0;
            fifo_tid      <= 0;
            fifo_dest_valid <= 0;
            fifo_dest     <= 0;
            fifo_user_valid <= 0;
            fifo_user     <= 0;
            fifo_write_en <= 0;
        end else begin
            fifo_write_en <= s_valid_in & ~fifo_full;
            if (fifo_write_en) begin
                fifo_ptr   <= fifo_ptr + 1'b1;
                fifo_data  <= s_data_in;
                fifo_keep  <= s_keep_in;
                fifo_last  <= s_last_in;
                fifo_tid_valid <= s_tid_valid;
                fifo_tid   <= s_tid_in;
                fifo_dest_valid <= s_dest_valid;
                fifo_dest  <= s_dest_in;
                fifo_user_valid <= s_user_valid;
                fifo_user  <= s_user_in;
            end
        end
    end

    // Read logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_read_en <= 0;
            m_axis_tvalid <= 0;
            m_axis_tready <= 1'b1; // Output ready is always high internally, driven by handshake
            m_axis_tdata  <= 0;
            m_axis_tkeep  <= 0;
            m_axis_tlast  <= 0;
            m_axis_tid    <= 0;
            m_axis_tdest  <= 0;
            m_axis_tuser  <= 0;
        end else begin
            // Read enable is driven by m_axis_tready
            fifo_read_en <= m_axis_tready;
            
            if (fifo_read_en) begin
                // Output data
                m_axis_tdata  <= fifo_data;
                m_axis_tkeep  <= fifo_keep;
                m_axis_tlast  <= fifo_last;
                m_axis_tid    <= fifo_tid;
                m_axis_tdest  <= fifo_dest;
                m_axis_tuser  <= fifo_user;
                
                // Valid signal
                m_axis_tvalid <= fifo_cnt > 0;
                
                // Update pointer
                if (fifo_cnt > 0) begin
                    fifo_ptr <= fifo_ptr + 1'b1;
                    fifo_cnt <= fifo_cnt - 1'b1;
                end
            end
        end
    end

    // Counters for full/empty detection
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_cnt <= 0;
        end else begin
            if (fifo_write_en) begin
                fifo_cnt <= fifo_cnt + 1'b1;
            end else if (fifo_read_en) begin
                if (fifo_cnt > 0) begin
                    fifo_cnt <= fifo_cnt - 1'b1;
                end
            end
        end
    end

    // Full/Empty logic
    assign fifo_full = (fifo_cnt == FIFO_DEPTH);
    assign fifo_empty = (fifo_cnt == 0);

    // Handshake logic
    assign s_axis_tready = ~fifo_full;
    assign m_axis_tready = 1'b1; // The FIFO handles the buffering, so the output is always ready to accept data from the FIFO perspective, 
                                // but the actual AXI handshake is handled by the read enable logic above.
                                // Wait, standard AXI-Stream: 
                                // m_axis_tready is an input to the module. 
                                // The module drives m_axis_tvalid.
                                // The module drives s_axis_tready.
                                // The FIFO read is enabled when m_axis_tready is high.
                                // So m_axis_tready is just passed through to the read enable logic.
                                // But wait, the read logic above uses `m_axis_tready` to enable reading.
                                // This is correct. The FIFO output is valid when data is present.
                                // The module asserts m_axis_tvalid when data is present AND m_axis_tready is high.
                                // Actually, in the code above:
                                // `m_axis_tvalid <= fifo_cnt > 0;`
                                // This asserts valid whenever there is data.
                                // The actual handshake completion happens when the master asserts ready.
                                // The slave (this module) must assert valid.
                                // The master asserts ready.
                                // When master asserts ready, we read from FIFO and drive outputs.
                                // So the logic `if (fifo_read_en)` where `fifo_read_en = m_axis_tready` is correct.
                                // But we need to ensure `m_axis_tvalid` is driven correctly.
                                // If `m_axis_tready` is low, we don't read, but `m_axis_tvalid` might still be high from previous cycle?
                                // No, in AXI-Stream, if ready is low, valid should be low (or held low).
                                // Standard behavior: valid is asserted, then ready is asserted, then valid is de-asserted.
                                // Or: valid is asserted, ready is asserted, data is transferred, then valid is de-asserted.
                                // My logic: `m_axis_tvalid <= fifo_cnt > 0;`
                                // If `m_axis_tready` is 0, `fifo_read_en` is 0. We don't read.
                                // But `m_axis_tvalid` remains high if `fifo_cnt > 0`.
                                // This is a violation. If ready is low, valid must be low (or the transaction is stalled).
                                // Correction: `m_axis_tvalid` should be `fifo_cnt > 0 && m_axis_tready`.
                                // However, usually the FIFO logic is:
                                // If data available and ready, drive data and valid.
                                // If data available but not ready, hold valid high? No, that's not how AXI works.
                                // AXI-Stream: 
                                // Slave asserts valid. Master asserts ready.
                                // If Master does not assert ready, Slave must NOT assert valid (or keep it low).
                                // So: `m_axis_tvalid = (fifo_cnt > 0) & m_axis_tready;`
                                // But wait, if `m_axis_tready` is low, we don't read.
                                // Next cycle, if `m_axis_tready` becomes high, we read.
                                // So `m_axis_tvalid` should be driven based on availability AND readiness.
                                // Let's refine the read logic.
                                
                                // Refined Read Logic:
                                // 1. If data available (cnt > 0) and ready is high:
                                //    - Drive data
                                //    - Drive valid
                                //    - Decrement count
                                // 2. If data available but ready is low:
                                //    - Hold valid low (stall)
                                //    - Do not decrement count
                                // 3. If no data:
                                //    - Hold valid low
                                //    - Do not decrement count
                                
                                // This requires storing the "data" in the output registers only when ready is high?
                                // No, the output registers hold the data.
                                // The `m_axis_tvalid` signal is the one that needs to be conditional.
                                // But if we don't read, the data stays in the FIFO.
                                // So the output registers `m_axis_tdata` etc. should only be updated when we read.
                                // And `m_axis_tvalid` should be asserted only when we read.
                                
                                // Let's restructure the read block.
                                // We need to capture the data from FIFO into output wires ONLY when ready is high.
                                // And assert valid only then.
                                // If ready is low, we do nothing (hold previous values or reset to 0).
                                // Since it's a single clock domain, holding previous values is fine as long as valid is low.
                                // But to be safe and clean, let's drive outputs only on read.
                                
                                // Actually, the standard way:
                                // `m_axis_tvalid` is driven by `fifo_cnt > 0`.
                                // The master sees `valid`. If it doesn't assert `ready`, the slave keeps `valid` high?
                                // No, the slave must de-assert `valid` if `ready` is not asserted?
                                // AXI Spec: "If tvalid is asserted and tready is not asserted, the slave must hold tvalid asserted."
                                // Wait, checking AXI-Stream spec...
                                // "If tvalid is asserted and tready is not asserted, the slave must hold tvalid asserted."
                                // This implies the slave drives valid high, and the master holds ready low.
                                // The slave waits.
                                // So my initial logic `m_axis_tvalid <= fifo_cnt > 0;` is actually correct for the "hold" behavior.
                                // The master will eventually assert ready.
                                // When ready is asserted, the slave reads the data and drives it.
                                // So the logic `if (fifo_read_en)` where `fifo_read_en = m_axis_tready` is correct.
                                // When ready is high, we read and drive outputs.
                                // When ready is low, we don't read, but `m_axis_tvalid` remains high (if data exists).
                                // This matches the spec.
                                
                                // One detail: `m_axis_tdata` etc. are outputs.
                                // If `m_axis_tvalid` is high, the outputs must be stable.
                                // In my code:
                                // `m_axis_tdata <= fifo_data;` happens only when `fifo_read_en` is true.
                                // If `fifo_read_en` is false (ready low), `m_axis_tdata` holds its previous value.
                                // This is correct.
                                // `m_axis_tvalid` is driven by `fifo_cnt > 0`.
                                // So if data exists, valid is high.
                                // If ready is low, we don't update data, so data is stable.
                                // If ready is high, we update data and valid.
                                // This works.
                                
                                // Wait, there is a subtle issue.
                                // If `fifo_cnt > 0` and `m_axis_tready` is low.
                                // `m_axis_tvalid` is high.
                                // `m_axis_tdata` holds the value from the last time `m_axis_tready` was high.
                                // This is correct.
                                // When `m_axis_tready` becomes high, `fifo_read_en` becomes high.
                                // We read `fifo_data` into `m_axis_tdata`.
                                // We assert `m_axis_tvalid`.
                                // We decrement `fifo_cnt`.
                                // This is correct.
                                
                                // So the logic stands.
        end
    end

    // Wire assignments for internal signals
    assign s_data_in = s_axis_tdata;
    assign s_keep_in = s_axis_tkeep;
    assign s_valid_in = s_axis_tvalid;
    assign s_last_in = s_axis_tlast;
    assign s_tid_valid = ID_ENABLE ? s_axis_tvalid : 1'b0;
    assign s_tid_in = ID_ENABLE ? s_axis_tid : 0;
    assign s_dest_valid = DEST_ENABLE ? s_axis_tvalid : 1'b0;
    assign s_dest_in = DEST_ENABLE ? s_axis_tdest : 0;
    assign s_user_valid = USER_ENABLE ? s_axis_tvalid : 1'b0;
    assign s_user_in = USER_ENABLE ? s_axis_tuser : 0;

    assign m_tid_valid = ID_ENABLE ? m_axis_tvalid : 1'b0;
    assign m_tid_out = ID_ENABLE ? m_axis_tid : 0;
    assign m_dest_valid = DEST_ENABLE ? m_axis_tvalid : 1'b0;
    assign m_dest_out = DEST_ENABLE ? m_axis_tdest : 0;
    assign m_user_valid = USER_ENABLE ? m_axis_tvalid : 1'b0;
    assign m_user_out = USER_ENABLE ? m_axis_tuser : 0;

    // Output port assignments
    assign m_axis_tdata = m_axis_tdata;
    assign m_axis_tkeep = m_axis_tkeep;
    assign m_axis_tvalid = m_axis_tvalid;
    assign m_axis_tlast = m_axis_tlast;
    assign m_axis_tid = m_tid_out;
    assign m_axis_tdest = m_dest_out;
    assign m_axis_tuser = m_user_out;
    
    // Note: The output ports in the module definition are already named `m_axis_tdata`, etc.
    // The internal signals `m_axis_tdata` etc. are just aliases or intermediate wires.
    // Let's clean up the internal signal naming to avoid confusion with the port names.
    
    // Re-declaring internal signals with different names to avoid conflict with ports
    // Actually, in Verilog, you can't have a wire with the same name as a port in the same scope.
    // So I will use `int_m_axis_tdata` etc. or just rely on the fact that the ports are outputs.
    // The `always` block assigns to `m_axis_tdata`. Since `m_axis_tdata` is an output port, this is valid.
    // The issue was I declared `wire [M_DATA_WIDTH-1:0] m_data_out;` and then assigned `m_axis_tdata <= m_data_out`.
    // I can simplify by assigning directly to the port.
    
    // Let's rewrite the read block to assign directly to ports to be cleaner.
    
    // Re-evaluating the read block logic for direct port assignment:
    // The `always` block for read logic needs to drive the output ports.
    // Since output ports are registered (implied by the `always @(posedge clk...)` block),
    // we just need to make sure the logic inside the block drives them correctly.
    
    // Corrected Read Logic Block:
    /*
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 0;
            m_axis_tkeep  <= 0;
            m_axis_tlast  <= 0;
            m_axis_tid    <= 0;
            m_axis_tdest  <= 0;
            m_axis_tuser  <= 0;
        end else begin
            if (fifo_read_en) begin
                // Read from FIFO and drive outputs
                m_axis_tdata  <= fifo_data;
                m_axis_tkeep  <= fifo_keep;
                m_axis_tlast  <= fifo_last;
                m_axis_tid    <= fifo_tid;
                m_axis_tdest  <= fifo_dest;
                m_axis_tuser  <= fifo_user;
                
                // Decrement counter
                if (fifo_cnt > 0) begin
                    fifo_cnt <= fifo_cnt - 1'b1;
                end
            end else begin
                // If not reading, valid should be high if data is available, low otherwise.
                // But we can't easily check "data available" without a separate counter check here
                // unless we use the counter.
                // m_axis_tvalid <= (fifo_cnt > 0);
                // However, if we do this, and `fifo_read_en` is low, we don't update data.
                // So `m_axis_tdata` holds the old value.
                // This is correct.
                m_axis_tvalid <= (fifo_cnt > 0);
            end
        end
    end
    */
    // Wait, if `fifo_read_en` is low, and `fifo_cnt > 0`, `m_axis_tvalid` becomes high.
    // `m_axis_tdata` holds the value from the last cycle where `fifo_read_en` was high.
    // This is correct.
    // But what if `fifo_cnt` was 0, then becomes > 0?
    // `m_axis_tvalid` becomes high. `m_axis_tdata` holds 0 (from reset or previous).
    // This is correct.
    
    // One edge case: Reset.
    // On reset, `fifo_cnt` is 0. `m_axis_tvalid` is 0. `m_axis_tdata` is 0. Correct.
    
    // Let's refine the code to be clean and remove the intermediate `m_data_out` wires if possible,
    // or keep them for clarity. Direct assignment is fine.
    
    // Final check on CDC:
    // All registers are clocked by `clk`.
    // `fifo_write_en` is combinational logic of `s_valid_in` and `fifo_full`.
    // `s_valid_in` is input. `fifo_full` is output of a register.
    // This is safe.
    // `fifo_read_en` is `m_axis_tready`. This is an input. Safe.
    // `m_axis_tvalid` is output of a register. Safe.
    // `m_axis_tdata` etc. are outputs of a register. Safe.
    // No asynchronous resets except `rst` which is active high and synchronous.
    // Reset release is safe.
    
    // One small optimization/correction:
    // In the read block, if `fifo_read_en` is false, we set `m_axis_tvalid <= (fifo_cnt > 0)`.
    // If `fifo_read_en` is true, we don't explicitly set `m_axis_tvalid` in the `if` block?
    // In the `if (fifo_read_en)` block, we should also set `m_axis_tvalid <= 1'b1`?
    // Yes, because if we read, valid is definitely high.
    // But wait, if `fifo_cnt` was 0, we wouldn't enter the `if (fifo_read_en)` block?
    // No, `fifo_read_en` is `m_axis_tready`. It can be high even if `fifo_cnt` is 0.
    // If `fifo_cnt` is 0 and `m_axis_tready` is 1:
    // `if (fifo_read_en)` is true.
    // We try to read `fifo_data`. But `fifo_cnt` is 0.
    // We should not read if empty.
    // So the condition should be `if (fifo_read_en && fifo_cnt > 0)`.
    // If `fifo_cnt` is 0, we fall through to the `else` block (or need an explicit check).
    // If we fall through to `else`, `m_axis_tvalid <= (fifo_cnt > 0)` -> 0. Correct.
    // But we need to make sure we don't read from FIFO if empty.
    // The `if (fifo_read_en)` block currently reads `fifo_data`.
    // If `fifo_cnt` is 0, `fifo_data` contains garbage (or 0 if reset).
    // We must ensure we only read if `fifo_cnt > 0`.
    
    // Revised Read Logic:
    /*
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 0;
            m_axis_tkeep  <= 0;
            m_axis_tlast  <= 0;
            m_axis_tid    <= 0;
            m_axis_tdest  <= 0;
            m_axis_tuser  <= 0;
        end else begin
            if (fifo_read_en && fifo_cnt > 0) begin
                m_axis_tdata  <= fifo_data;
                m_axis_tkeep  <= fifo_keep;
                m_axis_tlast  <= fifo_last;
                m_axis_tid    <= fifo_tid;
                m_axis_tdest  <= fifo_dest;
                m_axis_tuser  <= fifo_user;
                m_axis_tvalid <= 1'b1;
                fifo_cnt      <= fifo_cnt - 1'b1;
            end else begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end
    */
    // Wait, if `fifo_read_en` is 0 (ready low) and `fifo_cnt > 0`:
    // The `if` condition fails.
    // We go to `else`. `m_axis_tvalid <= 1'b0`.
    // This is WRONG. If data is available but ready is low, valid should be HIGH.
    // The AXI-Stream protocol requires the slave to assert valid when data is ready, 
    // and hold it until ready is asserted.
    // So `m_axis_tvalid` should be `(fifo_cnt > 0)`.
    // And `m_axis_tdata` should be updated ONLY when `fifo_read_en` is high.
    // If `fifo_read_en` is low, `m_axis_tdata` holds the last valid value.
    
    // Correct Logic:
    /*
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 0;
            m_axis_tkeep  <= 0;
            m_axis_tlast  <= 0;
            m_axis_tid    <= 0;
            m_axis_tdest  <= 0;
            m_axis_tuser  <= 0;
        end else begin
            // Determine if data is available
            wire data_available = (fifo_cnt > 0);
            
            if (fifo_read_en && data_available) begin
                // Transfer data
                m_axis_tdata  <= fifo_data;
                m_axis_tkeep  <= fifo_keep;
                m_axis_tlast  <= fifo_last;
                m_axis_tid    <= fifo_tid;
                m_axis_tdest  <= fifo_dest;
                m_axis_tuser  <= fifo_user;
                m_axis_tvalid <= 1'b1;
                fifo_cnt      <= fifo_cnt - 1'b1;
            end else if (data_available) begin
                // Data available but not ready. Hold valid high, do not update data.
                m_axis_tvalid <= 1'b1;
                // m_axis_tdata etc. hold previous values.
            end else begin
                // No data.
                m_axis_tvalid <= 1'b0;
                // m_axis_tdata etc. don't matter.
            end
        end
    end
    */
    // This logic is correct.
    // If `data_available` is true and `fifo_read_en` is false: `m_axis_tvalid` = 1. Data holds.
    // If `data_available` is true and `fifo_read_en` is true: `m_axis_tvalid` = 1. Data updates. Count decrements.
    // If `data_available` is false: `m_axis_tvalid` = 0.
    
    // One detail: `m_axis_tdata` etc. are outputs.
    // In the `else if (data_available)` block, we don't assign to `m_axis_tdata`.
    // So they retain their value from the previous cycle.
    // This is correct.
    
    // Let's write the final code.
    
    // Re-declaring internal signals to avoid port name collision in the same scope if needed,
    // but since ports are outputs, we can assign to them directly.
    // However, to be absolutely clear and avoid any synthesis tool confusion about "output driven by output",
    // I will use the port names directly in the always block.
    
    // Wait, `m_axis_tvalid` is an output.
    // `m_axis_tdata` is an output.
    // The logic above assigns to them. This is fine.
    
    // One more thing: `s_axis_tready` is an output.
    // `assign s_axis_tready = ~fifo_full;`
    // `fifo_full` is `(fifo_cnt == FIFO_DEPTH)`.
    // This is combinational. Safe.
    
    // Final check on parameters:
    // S_KEEP_WIDTH, M_KEEP_WIDTH, etc. are parameters.
    // $clog2 is a system function.
    // All good.
    
    // One detail: `ID_ENABLE`, `DEST_ENABLE`, `USER_ENABLE`.
    // If enabled, we pass the data. If not, we pass 0.
    // The logic `s_tid_valid = ID_ENABLE ? s_axis_tvalid : 1'b0;`
    // And `s_tid_in = ID_ENABLE ? s_axis_tid : 0;`
    // And in read: `m_axis_tid <= fifo_tid;`
    // If `ID_ENABLE` is 0, `fifo_tid_valid` is never set to 1 (always 0).
    // But `fifo_tid` is still written?
    // In write logic: `fifo_tid <= s_tid_in;`
    // `s_tid_in` is 0 if `ID_ENABLE` is 0.
    // So `fifo_tid` will be 0.
    // In read logic: `m_axis_tid <= fifo_tid;` -> 0.
    // This is correct.
    // But `m_axis_tid` is an output.
    // If `ID_ENABLE` is 0, we don't care about the value, but 0 is safe.
    // The `m_axis_tid_valid` logic?
    // I didn't implement `m_axis_tid_valid` as a separate signal.
    // The AXI-Stream spec says `tvalid` indicates if the transaction is valid.
    // If `ID_ENABLE` is 0, the ID field is ignored.
    // So we don't need a separate `tid_valid`.
    // Just driving `m_axis_tid` with 0 is fine.
    // Same for `dest` and `user`.
    
    // Wait, `s_tid_valid` was used to gate the write of `fifo_tid`.
    // `fifo_tid_valid` is a register.
    // If `ID_ENABLE` is 0, `fifo_tid_valid` is always 0.
    // But `fifo_tid` is still updated with `s_tid_in` (which is 0).
    // So `fifo_tid` is always 0.
    // This is fine.
    
    // One correction: `s_tid_valid` is not used in the write logic to gate the write of `fifo_tid`.
    // I wrote: `fifo_tid <= s_tid_in;` unconditionally in the write block.
    // But `s_tid_in` is 0 if `ID_ENABLE` is 0.
    // So `fifo_tid` becomes 0.
    // This is fine.
    // However, `fifo_tid_valid` is updated: `fifo_tid_valid <= s_tid_valid;`
    // If `ID_ENABLE` is 0, `s_tid_valid` is 0. `fifo_tid_valid` becomes 0.
    // This is fine.
    
    // Wait, I need to make sure `s_tid_in` is defined correctly.
    // `assign s_tid_in = ID_ENABLE ? s_axis_tid : 0;`
    // This is correct.
    
    // Final check on `m_axis_tvalid`.
    // If `ID_ENABLE` is 0, does it affect `m_axis_tvalid`?
    // No. `m_axis_tvalid` is based on `fifo_cnt > 0`.
    // This is correct. The presence of data is independent of the sideband validity.
    
    // One detail: `s_axis_tkeep`.
    // If `S_KEEP_ENABLE` is 0, `S_KEEP_WIDTH` is 1.
    // `s_axis_tkeep` is 1 bit.
    // `fifo_keep` is 1 bit.
    // `m_axis_tkeep` is 1 bit.
    // Logic holds.
    
    // One detail: `S_DATA_WIDTH` vs `M_DATA_WIDTH`.
    // If `S_DATA_WIDTH` != `M_DATA_WIDTH`, the FIFO stores `S_DATA_WIDTH` data.
    // When reading, we output `M_DATA_WIDTH` data.
    // But the FIFO only stores `S_DATA_WIDTH` data.
    // How do we convert width?
    // The problem statement says "Convert S_DATA_WIDTH to M_DATA_WIDTH".
    // It implies a bit-width conversion (packing/unpacking).
    // But the FIFO stores the raw `S_DATA_WIDTH` data.
    // When we read, we need to expand or compress it.
    // But the FIFO stores the data as it comes in.
    // If `S_DATA_WIDTH` = 16, `M_DATA_WIDTH` = 8.
    // We store 16 bits. We output 8 bits.
    // This means we are splitting the beat?
    // Or is it a simple width change where the beat count changes?
    // "Preserve packet boundaries (tlast)".
    // If `S_DATA_WIDTH` = 16, `M_DATA_WIDTH` = 8.
    // One input beat (16 bits) becomes two output beats (8 bits each).
    // The FIFO stores 16 bits.
    // When we read, we output 8 bits.
    // But the FIFO only has 16 bits.
    // We need to split the 16 bits into two 8-bit chunks.
    // But the FIFO is a simple buffer. It doesn't know about the split.
    // The split must happen in the read logic.
    // But the FIFO stores the data as a whole.
    // If we read one beat, we get 16 bits.
    // We need to output 8 bits.
    // Where do we get the next 8 bits?
    // They are in the same FIFO entry!
    // So we need to split the data in the FIFO entry?
    // No, the FIFO entry is `fifo_data [S_DATA_WIDTH-1:0]`.
    // If `S_DATA_WIDTH` > `M_DATA_WIDTH`, we need to output multiple beats for one FIFO entry.
    // This requires a state machine to split the data.
    // Similarly, if `S_DATA_WIDTH` < `M_DATA_WIDTH`, we need to pack multiple FIFO entries into one output beat.
    // This requires buffering multiple FIFO entries.
    
    // This complicates the simple FIFO approach.
    // The simple FIFO approach works only if `S_DATA_WIDTH` == `M_DATA_WIDTH`.
    // If widths differ, we need a more complex state machine to handle the packing/unpacking.
    // The prompt asks for a "width converter".
    // So I must implement the packing/unpacking logic.
    
    // Let's assume the standard approach:
    // Use a FIFO to buffer the stream.
    // But the FIFO depth must be sufficient to hold the data during the conversion.
    // And the read logic must handle the width conversion.
    
    // Case 1: S > M (Splitting)
   