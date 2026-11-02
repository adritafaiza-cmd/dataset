Please act as a professional Verilog designer.

Implement Transfer a timestamp and phase relationship between input, output, and sampling clock domains.

Module name:
    ptp_clock_cdc

Language:
    Verilog

Clocks:
    input_clk: Clock input for a source, destination, or sample domain.
    output_clk: Clock input for a source, destination, or sample domain.
    sample_clk: Clock input for a source, destination, or sample domain.

Resets:
    input_rst: Reset input for the declared domain.
    output_rst: Reset input for the declared domain.

Input ports:
    input_clk: Clock input for a source, destination, or sample domain.
    input_rst: Reset input for the declared domain.
    output_clk: Clock input for a source, destination, or sample domain.
    output_rst: Reset input for the declared domain.
    sample_clk: Clock input for a source, destination, or sample domain.
    input_ts: Synchronized output or status.
    input_ts_step: Synchronized output or status.

Output ports:
    output_ts: Synchronized output or status.
    output_ts_step: Synchronized output or status.
    output_pps: Synchronized output or status.
    locked: Synchronized output or status.

Parameters:
    Preserve each source parameter and its stated width or pipeline effect.

Behavior:
    - Preserve the level_sync, toggle_sync, bundled_data crossing mechanism and keep every asynchronous signal synchronized before it is consumed.
    - Maintain the source-defined pipeline, toggle, payload, and sampling relationships without introducing a second crossing path.
    - Preserve the source reset or initialization behavior exactly.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module ptp_clock_cdc #
(
    parameter TS_WIDTH = 96,
    parameter NS_WIDTH = 4,
    parameter LOG_RATE = 3,
    parameter PIPELINE_OUTPUT = 0
)
(
    input  wire                 input_clk,
    input  wire                 input_rst,
    input  wire                 output_clk,
    input  wire                 output_rst,
    input  wire                 sample_clk,

    /*
     * Timestamp inputs from source PTP clock
     */
    input  wire [TS_WIDTH-1:0]  input_ts,
    input  wire                 input_ts_step,

    /*
     * Timestamp outputs
     */
    output wire [TS_WIDTH-1:0]  output_ts,
    output wire                 output_ts_step,

    /*
     * PPS output
     */
    output wire                 output_pps,

    /*
     * Status
     */
    output wire                 locked
);
