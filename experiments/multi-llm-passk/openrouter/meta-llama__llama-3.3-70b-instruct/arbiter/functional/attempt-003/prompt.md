Please act as a professional Verilog designer.

Implement a multi-port request arbiter.

Module name:
    arbiter

Language:
    Verilog-2001

Clocks:
    clk: Single clock.

Resets:
    rst: active-high.

Input ports:
    clk: Clock.
    rst: Active-high reset.
    request: See Behavior.
    acknowledge: See Behavior.

Output ports:
    grant: See Behavior.
    grant_valid: Handshake valid.
    grant_encoded: See Behavior.

Parameters:
    PORTS: See Behavior.
    ARB_TYPE_ROUND_ROBIN: See Behavior.
    ARB_BLOCK: See Behavior.
    ARB_BLOCK_ACK: See Behavior.
    ARB_LSB_HIGH_PRIORITY: See Behavior.

Behavior:
    - Grant one of PORTS requestors.
    - When ARB_TYPE_ROUND_ROBIN is set, rotate priority; otherwise use fixed priority.
    - ARB_LSB_HIGH_PRIORITY selects whether the LSB wins ties.
    - When ARB_BLOCK is set, hold the grant until acknowledge (ARB_BLOCK_ACK nonzero) or until request drops (ARB_BLOCK_ACK zero).
    - grant_valid and grant_encoded must match grant.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

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
