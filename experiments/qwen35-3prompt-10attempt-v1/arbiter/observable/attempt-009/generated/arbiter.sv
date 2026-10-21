```verilog
module arbiter #
(
    parameter PORTS = 4,
    parameter ARB_TYPE_ROUND_ROBIN = 0,
    parameter ARB_BLOCK = 0,
    parameter ARB_BLOCK_ACK = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 0
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [PORTS-1:0]         request,
    input  wire [PORTS-1:0]         acknowledge,
    output wire [PORTS-1:0]         grant,
    output wire                     grant_valid,
    output wire [$clog2(PORTS)-1:0] grant_encoded
);

    localparam LOG_PORTS = $clog2(PORTS);
    localparam LSB_HIGH = ARB_LSB_HIGH_PRIORITY;

    // State encoding
    // 0: IDLE
    // 1: GRANTING (Grant is active, waiting for ack or timeout)
    // 2: BLOCKED (Grant is blocked, waiting for release event)
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] GRANTING = 2'b01;
    localparam [1:0] BLOCKED = 2'b10;

    reg [1:0] state;
    reg [LOG_PORTS-1:0] next_state;
    reg [LOG_PORTS-1:0] rr_index;
    reg [PORTS-1:0] grant;
    reg [PORTS-1:0] next_grant;
    reg grant_valid;
    reg next_grant_valid;
    reg [LOG_PORTS-1:0] next_rr_index;

    // Priority logic
    // If LSB_HIGH_PRIORITY is 1, port 0 is highest. If 0, port PORTS-1 is highest.
    // We generate a priority mask based on current request.
    generate
        genvar i;
        for (i = 0; i < PORTS; i = i + 1) begin : gen_priority
            wire is_highest;
            assign is_highest = (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH ? (i == 0) : (i == PORTS-1)) ? 1'b1 : 
                (request[i] && 
                (LSB_HIGH