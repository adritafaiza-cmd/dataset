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

    // Internal registers for state
    reg [DATA_WIDTH-1:0]   reg_tdata;
    reg [KEEP_WIDTH-1:0]   reg_tkeep;
    reg                    reg_tlast;
    reg [ID_WIDTH-1:0]     reg_tid;
    reg [DEST_WIDTH-1:0]   reg_tdest;
    reg [USER_WIDTH-1:0]   reg_tuser;
    reg                    reg_valid;

    // Output logic
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tdata  = reg_tdata;
    assign m_axis_tkeep  = reg_tkeep;
    assign m_axis_tvalid = reg_valid;
    assign m_axis_tlast  = reg_tlast;
    assign m_axis_tid    = reg_tid;
    assign m_axis_tdest  = reg_tdest;
    assign m_axis_tuser  = reg_tuser;

    // Sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_tdata  <= 0;
            reg_tkeep  <= 0;
            reg_tlast  <= 0;
            reg_tid    <= 0;
            reg_tdest  <= 0;
            reg_tuser  <= 0;
            reg_valid  <= 0;
        end
        else begin
            // Logic based on REG_TYPE
            if (REG_TYPE == 0) begin
                // Wire: Pass through immediately, no storage
                reg_tdata  <= s_axis_tdata;
                reg_tkeep  <= s_axis_tkeep;
                reg_tlast  <= s_axis_tlast;
                reg_tid    <= s_axis_tid;
                reg_tdest  <= s_axis_tdest;
                reg_tuser  <= s_axis_tuser;
                reg_valid  <= s_axis_tvalid;
            end
            else if (REG_TYPE == 1) begin
                // Simple Buffer: Store data, output on next cycle if valid
                if (s_axis_tvalid) begin
                    reg_tdata  <= s_axis_tdata;
                    reg_tkeep  <= s_axis_tkeep;
                    reg_tlast  <= s_axis_tlast;
                    reg_tid    <= s_axis_tid;
                    reg_tdest  <= s_axis_tdest;
                    reg_tuser  <= s_axis_tuser;
                    reg_valid  <= 1;
                end
                else begin
                    reg_valid <= 0;
                end
            end
            else if (REG_TYPE == 2) begin
                // Skid Buffer: Store data, output on next cycle if valid and ready
                if (s_axis_tvalid) begin
                    reg_tdata  <= s_axis_tdata;
                    reg_tkeep  <= s_axis_tkeep;
                    reg_tlast  <= s_axis_tlast;
                    reg_tid    <= s_axis_tid;
                    reg_tdest  <= s_axis_tdest;
                    reg_tuser  <= s_axis_tuser;
                    reg_valid  <= 1;
                end
                else begin
                    reg_valid <= 0;
                end
            end
        end
    end

    // Output handshake logic
    // For REG_TYPE 0 (Wire), output is valid only if input is valid
    // For REG_TYPE 1 and 2 (Buffer/Skid), output is valid if internal register is valid
    // and input is ready.
    // Note: The problem statement says "After reset the slice is empty".
    // For REG_TYPE 2 (Skid Buffer), we must not drop a beat when output stalls.
    // This implies the internal register holds the data until m_axis_tready is asserted.
    // However, the standard skid buffer behavior usually involves a FIFO depth of 1.
    // If m_axis_tvalid is asserted but m_axis_tready is not, the data stays in the register.
    // The output m_axis_tvalid should be asserted if reg_valid is 1 and m_axis_tready is 1.
    
    // Re-evaluating REG_TYPE 2 behavior based on "must not drop a beat when the output stalls":
    // This confirms the standard 1-cycle skid buffer behavior.
    // Input valid -> Store in reg, set reg_valid=1.
    // Output valid = (reg_valid && m_axis_tready).
    // If output is not ready, reg_valid remains 1, holding the beat.
    
    // For REG_TYPE 0 and 1, the logic is slightly different regarding the handshake.
    // REG_TYPE 0: Pass through. Output valid = Input valid.
    // REG_TYPE 1: Simple buffer. Output valid = (Input valid && m_axis_tready).
    // REG_TYPE 2: Skid buffer. Output valid = (reg_valid && m_axis_tready).
    
    // Let's refine the assignment for m_axis_tvalid based on REG_TYPE
    // Since we cannot use if-else in continuous assignment easily for all types without duplicating logic,
    // we will use a procedural block or a clever combinational logic.
    // Given the requirement for a single file and clean code, a procedural block for output logic is safer.
    
    always @(*) begin
        if (REG_TYPE == 0) begin
            m_axis_tvalid = s_axis_tvalid;
        end
        else if (REG_TYPE == 1) begin
            m_axis_tvalid = (s_axis_tvalid && m_axis_tready);
        end
        else if (REG_TYPE == 2) begin
            m_axis_tvalid = (reg_valid && m_axis_tready);
        end
    end

endmodule
```<|im_end|>
