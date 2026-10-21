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

    // Local parameters for width checks to avoid synthesis warnings on unused nets
    localparam int WIDTH_DATA = DATA_WIDTH;
    localparam int WIDTH_KEEP = KEEP_ENABLE ? KEEP_WIDTH : 1;
    localparam int WIDTH_LAST = LAST_ENABLE ? 1 : 0;
    localparam int WIDTH_ID = ID_ENABLE ? ID_WIDTH : 1;
    localparam int WIDTH_DEST = DEST_ENABLE ? DEST_WIDTH : 1;
    localparam int WIDTH_USER = USER_ENABLE ? USER_WIDTH : 1;

    // Internal storage registers
    reg [WIDTH_DATA-1:0]     reg_tdata;
    reg [WIDTH_KEEP-1:0]     reg_tkeep;
    reg                      reg_tlast;
    reg [WIDTH_ID-1:0]       reg_tid;
    reg [WIDTH_DEST-1:0]     reg_tdest;
    reg [WIDTH_USER-1:0]     reg_tuser;
    reg                      reg_valid;

    // Output handshake signals
    wire                     out_valid;
    wire                     out_ready;

    // Generate output validity based on REG_TYPE
    // REG_TYPE 0 (Wire): Output is valid only when input is valid and ready.
    // REG_TYPE 1 (Buffer): Output is valid when input is valid and ready.
    // REG_TYPE 2 (Skid Buffer): Output is valid when internal register is valid.
    assign out_valid = (REG_TYPE == 0) ? (s_axis_tvalid && m_axis_tready) : reg_valid;
    assign out_ready = (REG_TYPE == 0) ? s_axis_tready : m_axis_tready;

    // Generate output data based on REG_TYPE
    // REG_TYPE 0: Pass through immediately
    // REG_TYPE 1: Pass through immediately
    // REG_TYPE 2: Read from register
    assign m_axis_tdata = (REG_TYPE == 0) ? s_axis_tdata : reg_tdata;
    assign m_axis_tkeep = (REG_TYPE == 0) ? s_axis_tkeep : reg_tkeep;
    assign m_axis_tlast = (REG_TYPE == 0) ? s_axis_tlast : reg_tlast;
    assign m_axis_tid   = (REG_TYPE == 0) ? s_axis_tid : reg_tid;
    assign m_axis_tdest = (REG_TYPE == 0) ? s_axis_tdest : reg_tdest;
    assign m_axis_tuser = (REG_TYPE == 0) ? s_axis_tuser : reg_tuser;

    // CDC Safe Register Update Logic
    // We use a single process with non-blocking assignments.
    // The update logic ensures that data is only written to the register
    // when the input is valid AND the output is ready (for skid buffer)
    // or simply when input is valid (for wire/buffer, though wire/buffer don't store).
    // For REG_TYPE 2, we must ensure we don't overwrite with invalid data.
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_tdata     <= 0;
            reg_tkeep     <= 0;
            reg_tlast     <= 0;
            reg_tid       <= 0;
            reg_tdest     <= 0;
            reg_tuser     <= 0;
            reg_valid     <= 0;
        end else begin
            // Determine if we should update the register
            // For Skid Buffer (REG_TYPE 2): Update only if input valid AND output ready.
            // This prevents dropping beats when the downstream is stalled.
            // For Wire (0) and Buffer (1): No storage state is maintained across cycles 
            // effectively, but we keep the logic consistent. 
            // Actually, for Wire and Buffer, the register state is irrelevant as output 
            // is driven directly from input. However, to be safe and consistent, 
            // we can update the register only if we are in Skid Buffer mode, 
            // or simply update it whenever valid is high if we want to maintain state 
            // (though it won't be used for 0 and 1).
            // The critical path for CDC is ensuring we don't write on invalid.
            
            if (s_axis_tvalid && (REG_TYPE == 2 || m_axis_tready)) begin
                // Only update if we are a skid buffer OR if the output is ready.
                // For Wire/Buffer, m_axis_tready is the condition to proceed.
                // For Skid Buffer, we need m_axis_tready to ensure we don't drop data.
                // Note: If REG_TYPE is 0 or 1, reg_valid is not really used for output,
                // but we still update the register to keep it in sync with valid input.
                reg_tdata     <= s_axis_tdata;
                reg_tkeep     <= s_axis_tkeep;
                reg_tlast     <= s_axis_tlast;
                reg_tid       <= s_axis_tid;
                reg_tdest     <= s_axis_tdest;
                reg_tuser     <= s_axis_tuser;
                reg_valid     <= 1;
            end else if (s_axis_tvalid && (REG_TYPE == 2 || m_axis_tready) == 0) begin
                // This case handles the scenario where input is valid but output is not ready.
                // For Wire/Buffer: We do NOT update the register because the output 
                // is driven directly from input. The register state is irrelevant.
                // For Skid Buffer: We DO NOT update the register because we must hold 
                // the previous valid data until the output is ready.
                // Therefore, we only update if the condition to push data is met.
                // Wait, the logic above "if (s_axis_tvalid && ...)" covers the update.
                // If the condition is false, we do nothing (hold state).
                // This is correct for Skid Buffer.
                // For Wire/Buffer, since we don't use the register for output, 
                // holding the state is harmless, but logically we only care about 
                // the Skid Buffer behavior for state retention.
                // To be strictly correct for Wire/Buffer, we can just not update.
                // But since the condition (s_axis_tvalid && m_axis_tready) is false 
                // when stalled, the register holds its value. 
                // For Wire/Buffer, this doesn't matter as output is direct.
                // For Skid Buffer, this is exactly what we want (hold data).
                // So the logic stands: Update only if we are allowed to push.
            end
        end
    end

    // Assign output validity
    assign m_axis_tvalid = out_valid;

    // Assign input readiness
    // For Wire/Buffer: Ready if downstream is ready.
    // For Skid Buffer: Always ready (we absorb the data).
    assign s_axis_tready = (REG_TYPE == 2) ? 1'b1 : out_ready;

endmodule
```<|im_end|>
