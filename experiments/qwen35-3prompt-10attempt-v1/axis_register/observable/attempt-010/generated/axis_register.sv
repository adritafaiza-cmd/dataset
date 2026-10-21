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

    // Internal state registers
    reg [DATA_WIDTH-1:0]     reg_data;
    reg [KEEP_WIDTH-1:0]     reg_keep;
    reg                      reg_last;
    reg [ID_WIDTH-1:0]       reg_id;
    reg [DEST_WIDTH-1:0]     reg_dest;
    reg [USER_WIDTH-1:0]     reg_user;
    reg                      reg_valid;

    // Control signals
    wire                     is_wire;
    wire                     is_buffer;
    wire                     is_skid;

    assign is_wire   = (REG_TYPE == 0);
    assign is_buffer = (REG_TYPE == 1);
    assign is_skid   = (REG_TYPE == 2);

    // Logic to determine if we should capture new data
    // For Wire: Capture on valid & ready
    // For Buffer: Capture on valid & ready (acts like wire but holds state if needed? 
    //               Actually, standard AXI-Stream Buffer usually implies holding data until ready, 
    //               but in single-cycle context, Wire=through, Buffer=hold on stall, Skid=always hold one cycle.
    //               Interpretation:
    //               Wire: Pass through immediately.
    //               Buffer: Hold data in register until output ready (stall input if output not ready).
    //               Skid: Always hold one cycle of data regardless of output ready (decouples timing).
    
    // Re-evaluating standard definitions based on "behaves as wire, buffer, or skid buffer":
    // Wire: s_axis_tvalid & s_axis_tready -> pass immediately. No storage.
    // Buffer: If m_axis_tready is low, hold data and stall s_axis_tvalid (if possible) or just hold.
    //         Usually, a buffer implies: Capture on (s_valid & s_ready). Output on (m_valid & m_ready).
    //         If m_ready is low, data stays in reg. If s_valid is high and s_ready is low, we stall s_valid?
    //         In a single register slice, "Buffer" typically means: 
    //         Capture when s_valid && s_ready. Output when m_valid && m_ready. 
    //         If m_ready is low, we keep data. If s_valid is high and s_ready is low, we must stall s_valid 
    //         to prevent overwriting, UNLESS it's a skid buffer which ignores s_ready for capture.
    //         Let's refine:
    //         Wire: s_valid & s_ready -> capture & output.
    //         Buffer: Capture on s_valid & s_ready. Output on m_valid & m_ready. 
    //                 If s_valid & s_ready is true, we capture. If m_ready is low, we hold.
    //                 If s_valid is high and s_ready is low, we stall s_valid (set s_ready=0).
    //         Skid: Always capture on s_valid (ignoring s_ready). Output on m_valid & m_ready.
    //               This decouples the two sides completely.

    wire                     s_capture_enable;
    wire                     s_stall;

    assign s_stall = (is_buffer || is_skid) && reg_valid && !m_axis_tready;
    assign s_capture_enable = (is_wire) ? (s_axis_tvalid && s_axis_tready)
                                      : (is_buffer) ? (s_axis_tvalid && s_axis_tready)
                                      : (is_skid) ? s_axis_tvalid
                                      : 1'b1; // Default fallback

    // State Update Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_data      <= 0;
            reg_keep      <= 0;
            reg_last      <= 0;
            reg_id        <= 0;
            reg_dest      <= 0;
            reg_user      <= 0;
            reg_valid     <= 0;
        end else begin
            if (s_capture_enable) begin
                reg_data      <= s_axis_tdata;
                reg_keep      <= s_axis_tkeep;
                reg_last      <= s_axis_tlast;
                reg_id        <= s_axis_tid;
                reg_dest      <= s_axis_tdest;
                reg_user      <= s_axis_tuser;
                reg_valid     <= 1;
            end else if (is_wire) begin
                // Wire mode: If not capturing, we must clear valid if it was set?
                // Actually, in wire mode, if s_ready is low, s_valid is stalled (handled by s_stall logic above? No, wire doesn't stall).
                // For Wire: s_ready is always 1 if s_valid is 1 and data is valid? 
                // No, Wire just passes. If m_ready is low, s_ready is low.
                // If s_valid is high and s_ready is low, we don't capture.
                // But we also don't hold? 
                // Standard Wire: s_valid & s_ready -> capture & output.
                // If s_valid & !s_ready -> s_ready = 0 (stall).
                // If !s_valid -> clear.
                // However, the prompt says "Keep pending data... through a stall".
                // Wire usually doesn't hold. But if we interpret "Wire" as "Pass through with no buffering", 
                // then if m_ready is low, we stall s_valid.
                // Let's assume Wire acts like Buffer but with specific timing? 
                // Actually, let's stick to the definitions:
                // Wire: s_valid & s_ready -> capture & output.
                // Buffer: Capture on s_valid & s_ready. Hold if m_ready low.
                // Skid: Capture on s_valid. Hold if m_ready low.
                
                // Correction for Wire: 
                // If is_wire, we don't need to hold data across cycles if s_ready is low? 
                // But if s_valid is high and s_ready is low, we must stall s_valid.
                // So s_capture_enable logic above handles the "don't capture" part.
                // What about clearing? 
                // If s_valid is 0, we clear.
                // If s_valid is 1 and s_ready is 0, we stall (s_capture_enable is 0).
                // Do we clear reg_valid? No, because s_valid is still 1.
                // But if s_valid becomes 0, we clear.
                // Wait, if s_valid is 1 and s_ready is 0, we are stalled. 
                // Next cycle, if s_valid is still 1, we try again.
                // If s_valid becomes 0, we clear.
                // This seems correct for all types.
                
                // One edge case: Wire mode. If s_valid=1, s_ready=0. We stall.
                // If s_valid=0, we clear.
                // This is consistent.
                
                // However, some definitions of "Wire" imply no storage at all.
                // But in AXI-Stream, you can't pass data without storage if there's a stall.
                // So "Wire" here likely means "No extra buffering beyond the pipeline stage", 
                // i.e., capture and output in the same cycle if ready.
                
                // Let's refine the clear condition.
                // If we are NOT capturing, do we clear?
                // Only if the input is invalid.
                // If input is valid but we are stalled (s_ready=0), we keep data.
                // If input is invalid, we clear data.
                
                // Logic:
                // If (s_axis_tvalid) -> Keep data (if we are capturing or stalled).
                // If (!s_axis_tvalid) -> Clear data.
                
                // But wait, if is_wire and s_axis_tvalid=1, s_axis_tready=0.
                // s_capture_enable = 0.
                // We do NOT update registers.
                // We do NOT clear registers.
                // This is correct: we hold the data until ready.
                
                // What if is_wire and s_axis_tvalid=0?
                // s_capture_enable = 0.
                // We should clear registers.
                // So: if (!s_axis_tvalid) clear.
                
                // Let's adjust the always block logic to be explicit.
            end
        end
    end

    // Re-implementing the always block with clearer logic for all types
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_data      <= 0;
            reg_keep      <= 0;
            reg_last      <= 0;
            reg_id        <= 0;
            reg_dest      <= 0;
            reg_user      <= 0;
            reg_valid     <= 0;
        end else begin
            // Determine if we should update registers
            wire update_reg = 0;
            
            if (is_wire) begin
                // Wire: Update only if s_valid and s_ready.
                // If s_valid and !s_ready, we stall (don't update, don't clear).
                // If !s_valid, we clear.
                if (s_axis_tvalid && s_axis_tready)
                    update_reg <= 1;
                else if (!s_axis_tvalid)
                    update_reg <= 0; // Will trigger clear below
                else
                    update_reg <= 0; // Stalled, keep data
            end
            else if (is_buffer) begin
                // Buffer: Update if s_valid and s_ready.
                // If s_valid and !s_ready, stall (keep data).
                // If !s_valid, clear.
                if (s_axis_tvalid && s_axis_tready)
                    update_reg <= 1;
                else if (!s_axis_tvalid)
                    update_reg <= 0;
                else
                    update_reg <= 0;
            end
            else if (is_skid) begin
                // Skid: Always update if s_valid (ignores s_ready).
                // If !s_valid, clear.
                if (s_axis_tvalid)
                    update_reg <= 1;
                else
                    update_reg <= 0;
            end

            if (update_reg) begin
                reg_data      <= s_axis_tdata;
                reg_keep      <= s_axis_tkeep;
                reg_last      <= s_axis_tlast;
                reg_id        <= s_axis_tid;
                reg_dest      <= s_axis_tdest;
                reg_user      <= s_axis_tuser;
                reg_valid     <= 1;
            end else begin
                // Only clear if input is invalid
                if (!s_axis_tvalid) begin
                    reg_data      <= 0;
                    reg_keep      <= 0;
                    reg_last      <= 0;
                    reg_id        <= 0;
                    reg_dest      <= 0;
                    reg_user      <= 0;
                    reg_valid     <= 0;
                end
                // If s_axis_tvalid is high but we are not updating (stall), keep data.
            end
        end
    end

    // Output Logic
    assign m_axis_tdata      = reg_valid ? reg_data      : 0;
    assign m_axis_tkeep      = reg_valid ? reg_keep      : 0;
    assign m_axis_tvalid     = reg_valid && m_axis_tready;
    assign m_axis_tlast      = reg_valid ? reg_last      : 0;
    assign m_axis_tid        = reg_valid ? reg_id        : 0;
    assign m_axis_tdest      = reg_valid ? reg_dest      : 0;
    assign m_axis_tuser      = reg_valid ? reg_user      : 0;

    // Input Ready Logic
    // Wire: Ready if s_valid is low OR (s_valid is high and m_ready is high).
    //       Actually, if s_valid is high and m_ready is low, we must assert s_ready=0 to stall.
    //       So s_ready = (!s_axis_tvalid) || m_axis_tready;
    // Buffer: Same as Wire.
    // Skid: Same as Wire.
    // Note: If s_axis_tvalid is 0, s_axis_tready can be 1 (ready to accept).
    //       If s_axis_tvalid is 1 and m_axis_tready is 1, s_axis_tready = 1.
    //       If s_axis_tvalid is 1 and m_axis_tready is 0, s_axis_tready = 0.
    
    assign s_axis_tready = (!s_axis_tvalid) || m_axis_tready;

endmodule
```<|im_end|>
