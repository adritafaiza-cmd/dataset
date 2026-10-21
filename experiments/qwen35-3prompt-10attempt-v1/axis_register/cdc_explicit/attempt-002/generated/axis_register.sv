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

    // Internal registers for state and data
    reg [DATA_WIDTH-1:0]     reg_tdata;
    reg [KEEP_WIDTH-1:0]     reg_tkeep;
    reg                      reg_tlast;
    reg [ID_WIDTH-1:0]       reg_tid;
    reg [DEST_WIDTH-1:0]     reg_tdest;
    reg [USER_WIDTH-1:0]     reg_tuser;
    reg                      reg_valid;

    // Output handshake signals
    wire                     wire_ready;
    wire                     wire_valid;

    // Generate ready signal based on REG_TYPE
    // REG_TYPE 0 (Wire): Pass-through, no buffering. Ready is always 1.
    // REG_TYPE 1 (Buffer): Simple buffer. Ready is always 1.
    // REG_TYPE 2 (Skid Buffer): Must not drop a beat when output stalls.
    //                       Ready is driven by internal valid state.
    assign wire_ready = (REG_TYPE == 2) ? ~reg_valid : 1'b1;

    // Generate valid signal based on REG_TYPE
    // REG_TYPE 0 (Wire): Pass-through. Valid is driven by input valid.
    // REG_TYPE 1 (Buffer): Simple buffer. Valid is driven by input valid.
    // REG_TYPE 2 (Skid Buffer): Valid is driven by internal state.
    assign wire_valid = (REG_TYPE == 2) ? reg_valid : s_axis_tvalid;

    // Sequential logic for REG_TYPE 2 (Skid Buffer)
    // For REG_TYPE 0 and 1, we can use a simple combinational assignment or a trivial register
    // to ensure CDC compliance, but the behavior is effectively pass-through.
    // To strictly adhere to "single-clock" and "safe CDC", we implement the state machine
    // for all types, but for 0 and 1, the state machine collapses to pass-through behavior
    // when ready is always 1. However, to be explicit and safe:
    
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
            if (s_axis_tvalid && wire_ready) begin
                // Capture data
                reg_tdata      <= s_axis_tdata;
                reg_tkeep      <= s_axis_tkeep;
                reg_tlast      <= s_axis_tlast;
                reg_tid        <= s_axis_tid;
                reg_tdest      <= s_axis_tdest;
                reg_tuser      <= s_axis_tuser;
                reg_valid      <= 1'b1;
            end else if (REG_TYPE == 2) begin
                // Skid buffer: clear valid if not ready (input stalled)
                // Note: If input is valid but output not ready, we hold the data.
                // If input is not valid, we clear the register.
                if (!s_axis_tvalid) begin
                    reg_valid <= 1'b0;
                end
                // If s_axis_tvalid is 1 and wire_ready is 0, reg_valid stays 1.
                // If s_axis_tvalid is 0 and wire_ready is 1, reg_valid becomes 0.
            end
        end
    end

    // Output assignments
    assign s_axis_tready = wire_ready;
    assign m_axis_tdata  = reg_tdata;
    assign m_axis_tkeep  = reg_tkeep;
    assign m_axis_tvalid = wire_valid;
    assign m_axis_tlast  = reg_tlast;
    assign m_axis_tid    = reg_tid;
    assign m_axis_tdest  = reg_tdest;
    assign m_axis_tuser  = reg_tuser;

endmodule
```<|im_end|>
