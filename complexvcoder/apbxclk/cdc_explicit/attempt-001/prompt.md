Please act as a professional Verilog designer.

Implement an APB clock-domain bridge.

Module name:
    apbxclk

Language:
    Verilog-2001

Clocks:
    S_APB_PCLK: Independent asynchronous clock (async to M_APB_PCLK). No fixed frequency or phase relationship.
    M_APB_PCLK: Independent asynchronous clock (async to S_APB_PCLK).

Resets:
    S_PRESETn: active-low.

Input ports:
    S_APB_PCLK: Source APB clock.
    S_PRESETn: Active-low source reset.
    S_APB_PSEL: Source APB select.
    S_APB_PENABLE: Source APB enable (access phase).
    S_APB_PADDR: Address.
    S_APB_PWRITE: Source write/read.
    S_APB_PWDATA: Data payload.
    S_APB_PWSTRB: Write strobes.
    S_APB_PPROT: Protection bits.
    M_APB_PCLK: Destination APB clock.
    M_APB_PREADY: Destination APB ready input.
    M_APB_PRDATA: Data payload.
    M_APB_PSLVERR: Destination slave error.

Output ports:
    S_APB_PREADY: Source APB ready. Assert only after the destination transfer completes.
    S_APB_PRDATA: Data payload.
    S_APB_PSLVERR: Source slave error.
    M_PRESETn: Active-low destination reset output.
    M_APB_PSEL: Destination APB select.
    M_APB_PENABLE: Destination APB enable (access phase).
    M_APB_PADDR: Address.
    M_APB_PWRITE: Destination write/read.
    M_APB_PWDATA: Data payload.
    M_APB_PWSTRB: Write strobes.
    M_APB_PPROT: Protection bits.

Parameters:
    C_APB_ADDR_WIDTH: APB address width.
    C_APB_DATA_WIDTH: APB data width.
    OPT_REGISTERED: When set, register crossing payload and response fields. Behavior must stay the same.

Behavior:
    - Accept standard APB transfers on the S_APB interface.
    - Forward each accepted request exactly once to the M_APB interface using a normal APB setup phase followed by an access phase.
    - Keep the downstream request fields stable until M_APB_PREADY completes the transfer.
    - Return read data and slave-error status to the source interface.
    - Assert S_APB_PREADY only when the corresponding downstream transaction has completed.
    - Do not lose, duplicate, or reorder requests.
    - Supporting one outstanding transaction is sufficient.
    - Both interfaces must remain inactive during reset, and reset must not create a transaction.
    - OPT_REGISTERED selects whether crossing payload and response fields are explicitly registered. Both parameter settings must preserve APB behavior.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module	apbxclk #(
		parameter	C_APB_ADDR_WIDTH = 12,
		parameter	C_APB_DATA_WIDTH = 32,
		parameter [0:0]	OPT_REGISTERED = 1'b0,
		localparam	AW = C_APB_ADDR_WIDTH,
		localparam	DW = C_APB_DATA_WIDTH
	) (
		input	wire			S_APB_PCLK, S_PRESETn,
		input	wire			S_APB_PSEL,
		input	wire			S_APB_PENABLE,
		output	reg			S_APB_PREADY,
		input	wire	[AW-1:0]	S_APB_PADDR,
		input	wire			S_APB_PWRITE,
		input	wire	[DW-1:0]	S_APB_PWDATA,
		input	wire	[DW/8-1:0]	S_APB_PWSTRB,
		input	wire	[2:0]		S_APB_PPROT,
		output	wire	[DW-1:0]	S_APB_PRDATA,
		output	wire			S_APB_PSLVERR,
		input	wire			M_APB_PCLK,
		output	reg			M_PRESETn,
		output	reg			M_APB_PSEL,
		output	reg			M_APB_PENABLE,
		input	wire			M_APB_PREADY,
		output	wire	[AW-1:0]	M_APB_PADDR,
		output	wire			M_APB_PWRITE,
		output	wire	[DW-1:0]	M_APB_PWDATA,
		output	wire	[DW/8-1:0]	M_APB_PWSTRB,
		output	wire	[2:0]		M_APB_PPROT,
		input	wire	[DW-1:0]	M_APB_PRDATA,
		input	wire			M_APB_PSLVERR
	);
