Implement the SystemVerilog module `cdc_counter_display_top`.

//   Nexys A7 FPGA demonstration of clock domain crossing (CDC) using async

Functional contract and interface notes:

Module: cdc_counter_display_top
Purpose: //   Nexys A7 FPGA demonstration of clock domain crossing (CDC) using async
Module: cdc_counter_display_top
Description:
Nexys A7 FPGA demonstration of clock domain crossing (CDC) using async
handshake protocol. Features a debounced button counter in the button
clock domain that safely transfers count values to the display clock
domain via pulse-based CDC handshake, then displays on 7-segment displays.
Features:
- Dual independent clock domains (button domain @ 10Hz, display @ 1kHz)
- Button debouncing with configurable debounce time
- 8-bit counter with rollover
- Safe CDC handshake using pulse synchronizer
- Dual 7-segment hex displays (2 digits)
- Visual heartbeat LED indicators for each clock domain
- Reset button support
Clock Domains:
- btn_clk_domain: 10 Hz (100ms period) - Button sampling rate
- disp_clk_domain: 1 kHz (1ms period) - Display refresh rate
Integration:
Uses rtldesignsherpa library modules:
- debounce.sv (common/) - Button debouncing
- counter_bin.sv (common/) - Binary up counter
- cdc_4_phase_handshake.sv (rtl/cdc/) - CDC bus transfer with handshake
- hex_to_7seg.sv (common/) - Hex to 7-segment decoder
- clock_divider.sv (common/) - Clock generation from 100MHz system clock
Educational Notes:
This design demonstrates CRITICAL CDC concepts:
1. **Clock Domain Isolation:**
- btn_clk (10Hz) and disp_clk (1kHz) are completely independent
2. **Handshake-Based CDC:**
- Counter increment triggers CDC handshake protocol
- cdc_4_phase_handshake safely transfers counter bus to disp_clk domain
- Full 4-phase handshake: src_valid → dst_valid → dst_ready → src_ready
- Guarantees exactly one transfer per button press
3. **Data Transfer Strategy:**
- Counter value latched in source domain on src_valid
- Multi-bit bus synchronized via handshake protocol
- Destination samples data when dst_valid asserted
- Avoids metastability through proper FSM-based synchronization
4. **Why Use Full Handshake:**
- Production-quality CDC for multi-bit bus transfer
- Demonstrates industry-standard async handshake protocol
- Provides explicit flow control and transfer acknowledgement
- Better than simple synchronizers for learning CDC protocols
5. **Heartbeat Indicators:**
- Each domain has LED toggling at its clock rate
- Visual confirmation of independent clock operation
- Helps debug clock generation issues
Timing Analysis:
Button Press to Display Update Latency:
1. Button debounce: ~20ms (200 btn_clk cycles @ 10Hz)
2. Counter update: 100ms (1 btn_clk cycle)
3. CDC handshake: ~6-8ms (6-8 disp_clk cycles @ 1kHz for complete handshake)
4. Display update: 1ms (1 disp_clk cycle)
Total: ~27-29ms typical
Maximum Button Press Rate:
- Limited by: max(debounce time, CDC handshake completion)
- Debounce time: ~20ms
- Handshake completion: ~8ms
- Practical limit: ~50 presses/second (20ms minimum)
- Human limit: ~10 presses/second
Physical Connections (Nexys A7):
Inputs:
- btnC (center button): Counter increment
- btnU (up button): System reset
- CLK100MHZ: 100 MHz system clock
Outputs:
- seg[6:0]: 7-segment display segments (CA-CG)
- an[7:0]: 7-segment display anodes (digit select)
- led[1:0]: Heartbeat indicators
- led[0]: btn_clk domain heartbeat (toggles @ 5Hz)
- led[1]: disp_clk domain heartbeat (toggles @ 500Hz)
Display Format:
- AN7-AN2: OFF (unused digits)
- AN1: Counter high nibble (0-F)
- AN0: Counter low nibble (0-F)
Example: Counter = 0x3A → Display shows "3A"
Parameters:
SYS_CLK_FREQ_MHZ:
Description: System clock frequency in MHz
Type: int
Range: 50 to 200
Default: 100 (Nexys A7 default)
BTN_CLK_FREQ_HZ:
Description: Button domain clock frequency in Hz
Type: int
Range: 1 to 1000
Default: 10 (100ms period, good for visual confirmation)
DISP_CLK_FREQ_HZ:
Description: Display domain clock frequency in Hz
Type: int
Range: 100 to 10000
Default: 1000 (1ms period, sufficient for multiplexing)
DEBOUNCE_TIME_MS:
Description: Button debounce time in milliseconds
Type: int
Range: 10 to 100
Default: 20 (typical mechanical button settling time)
COUNTER_WIDTH:
Description: Counter bit width
Type: int
Range: 4 to 16
Default: 8 (allows 0-255, displays as 00-FF hex)
Derived Parameters (localparam - computed automatically):
BTN_CLK_DIV_RATIO: Clock divider ratio for button clock
DISP_CLK_DIV_RATIO: Clock divider ratio for display clock
HEARTBEAT_BTN_DIV: Button domain heartbeat divider
HEARTBEAT_DISP_DIV: Display domain heartbeat divider
CDC Safety Analysis:
Crossing #1: Counter value bus (btn_clk → disp_clk)
- Method: cdc_4_phase_handshake (4-phase async handshake protocol)
- Signals crossed: r_count_value[COUNTER_WIDTH-1:0]
- Safety: Full FSM-based handshake with 3-stage synchronizers
- Latency: 6-8 disp_clk cycles (complete req→ack→req_clear→ack_clear)
- MTBF: >10^12 hours (3-stage synchronizers on req/ack signals)
Crossing #2: None (display outputs are purely in disp_clk domain)
ASYNCHRONOUS CLOCK GROUPS (for timing constraints):
- btn_clk and disp_clk are asynchronous (must be declared)
FALSE PATHS (for timing constraints):
- Internal handshake signals are already properly synchronized
- No additional false paths needed (handled by cdc_4_phase_handshake)

Required clock and reset behavior:

- Clock ports: CLK100MHZ.
- Reset ports: none; retain the declared initialization behavior.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_4_phase_handshake: cdc_4_phase_handshake #( .DATA_WIDTH(COUNTER_WIDTH) ) u_counter_cdc ( .clk_src (btn_clk), .rst_src_n (sys_rst_n), .src_valid (cdc_src_valid), .src_ready (cdc_src_ready), .src_data (r_count_value), .clk_dst (disp_clk), .rst_dst_n (sys_rst_n), .src_timeout (), .dst_valid (cdc_dst_valid), .dst_ready (cdc_dst_ready), .dst_data (cdc_dst_data) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_counter_display_top #(
    parameter int SYS_CLK_FREQ_MHZ = 100,
    parameter int BTN_CLK_FREQ_HZ = 10,
    parameter int DISP_CLK_FREQ_HZ = 1000,
    parameter int DEBOUNCE_TIME_MS = 20,
    parameter int COUNTER_WIDTH = 8
) (
    // System inputs
    input  logic        CLK100MHZ,      // 100 MHz system clock (Nexys A7)
    input  logic        btnC,           // Center button - increment counter
    input  logic        btnU,           // Up button - reset
    // 7-segment display outputs
    output logic [6:0]  seg,            // Segment drivers (CA-CG)
    output logic [7:0]  an,             // Anode drivers (digit select)
    // LED outputs
    output logic [1:0]  led             // Heartbeat indicators
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
