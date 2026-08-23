Generate synthesizable Verilog-2001 implementing an APB clock-domain bridge:

module apbxclk #(
  parameter C_APB_ADDR_WIDTH = 12,
  parameter C_APB_DATA_WIDTH = 32,
  parameter [0:0] OPT_REGISTERED = 1'b0
)(
  input  wire                         S_APB_PCLK,
  input  wire                         S_PRESETn,
  input  wire                         S_APB_PSEL,
  input  wire                         S_APB_PENABLE,
  output reg                          S_APB_PREADY,
  input  wire [C_APB_ADDR_WIDTH-1:0]  S_APB_PADDR,
  input  wire                         S_APB_PWRITE,
  input  wire [C_APB_DATA_WIDTH-1:0]  S_APB_PWDATA,
  input  wire [C_APB_DATA_WIDTH/8-1:0] S_APB_PWSTRB,
  input  wire [2:0]                   S_APB_PPROT,
  output wire [C_APB_DATA_WIDTH-1:0]  S_APB_PRDATA,
  output wire                         S_APB_PSLVERR,

  input  wire                         M_APB_PCLK,
  output reg                          M_PRESETn,
  output reg                          M_APB_PSEL,
  output reg                          M_APB_PENABLE,
  input  wire                         M_APB_PREADY,
  output wire [C_APB_ADDR_WIDTH-1:0]  M_APB_PADDR,
  output wire                         M_APB_PWRITE,
  output wire [C_APB_DATA_WIDTH-1:0]  M_APB_PWDATA,
  output wire [C_APB_DATA_WIDTH/8-1:0] M_APB_PWSTRB,
  output wire [2:0]                   M_APB_PPROT,
  input  wire [C_APB_DATA_WIDTH-1:0]  M_APB_PRDATA,
  input  wire                         M_APB_PSLVERR
);

S_APB_PCLK and M_APB_PCLK are independent asynchronous clocks.

Accept standard APB transfers on the S_APB interface. Forward each accepted
request exactly once to the M_APB interface using a normal APB setup phase
followed by an access phase. Keep the downstream request fields stable until
M_APB_PREADY completes the transfer.

Return read data and slave-error status to the source interface. Assert
S_APB_PREADY only when the corresponding downstream transaction has completed.
Do not lose, duplicate, or reorder requests. Supporting one outstanding
transaction is sufficient.

S_PRESETn is the active-low source reset. M_PRESETn is an active-low reset
output for the destination domain. Both interfaces must remain inactive during
reset, and reset must not create a transaction.

OPT_REGISTERED selects whether crossing payload and response fields are
explicitly registered. Both parameter settings must preserve APB behavior.

The implementation must be safe for clock-domain and reset-domain crossings
and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
release must be safe in each clock domain, and transferred multi-bit data must
remain coherent. Select the architecture yourself.

Return one complete source file only. Do not include a testbench, explanation,
markdown, vendor primitives, or reference code.
