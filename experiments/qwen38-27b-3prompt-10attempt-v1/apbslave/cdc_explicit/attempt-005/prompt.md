Please act as a professional Verilog designer.

Implement a single-clock APB slave.

Module name:
    apbslave

Language:
    Verilog-2001

Clocks:
    PCLK: Single clock.

Resets:
    PRESETn: active-low.

Input ports:
    PCLK: Clock.
    PRESETn: Active-low reset.
    PSEL: See Behavior.
    PENABLE: See Behavior.
    PADDR: Address.
    PWRITE: See Behavior.
    PWDATA: Data payload.
    PWSTRB: Write strobes.
    PPROT: Protection bits.

Output ports:
    PREADY: Handshake ready.
    PRDATA: Data payload.
    PSLVERR: See Behavior.

Parameters:
    C_APB_ADDR_WIDTH: APB address width.
    C_APB_DATA_WIDTH: APB data width.

Behavior:
    - Accept standard APB setup/access transfers and complete each access by asserting PREADY.
    - Support reads and writes of C_APB_DATA_WIDTH using PWSTRB.
    - PSLVERR may stay low for in-range accesses.
    - After reset the slave must be idle.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module	apbslave #(
		parameter	C_APB_ADDR_WIDTH = 12,
		parameter	C_APB_DATA_WIDTH = 32,
		localparam	AW = C_APB_ADDR_WIDTH,
		localparam	DW = C_APB_DATA_WIDTH,
		localparam	APBLSB = $clog2(C_APB_DATA_WIDTH)-3
	) (
		input	wire			PCLK, PRESETn,
		input	wire			PSEL,
		input	wire			PENABLE,
		output	reg			PREADY,
		input	wire	[AW-1:0]	PADDR,
		input	wire			PWRITE,
		input	wire	[DW-1:0]	PWDATA,
		input	wire	[DW/8-1:0]	PWSTRB,
		input	wire	[2:0]		PPROT,
		output	reg	[DW-1:0]	PRDATA,
		output	wire			PSLVERR
	);
