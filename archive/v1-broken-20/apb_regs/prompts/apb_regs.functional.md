Please act as a professional Verilog designer.

Implement an APB-mapped register file.

Module name:
    apb_regs

Language:
    SystemVerilog

Clocks:
    pclk_i: Single clock.

Resets:
    preset_ni: reset.

Input ports:
    pclk_i: Clock.
    preset_ni: Reset reset.
    req_t: See Behavior.
    apb_addr_t: Address.
    reg_data_t: Data payload.

Output ports:
    resp_t: Response status.
    reg_data_t: Data payload.

Parameters:
    NoApbRegs: See Behavior.
    ApbAddrWidth: See Behavior.
    AddrOffset: See Behavior.
    ApbDataWidth: See Behavior.
    RegDataWidth: See Behavior.
    ReadOnly: See Behavior.
    req_t: See Behavior.
    resp_t: See Behavior.
    apb_addr_t: See Behavior.
    reg_data_t: See Behavior.

Behavior:
    - Map NoApbRegs registers of RegDataWidth, spaced AddrOffset bytes apart, starting at base_addr_i.
    - req_i / resp_o use the APB request and response types supplied by the testbench.
    - Initialize from reg_init_i and drive reg_q_o with current values.
    - Read-only bits in ReadOnly must ignore writes.
    - After reset, registers return to reg_init_i.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd0,
  parameter int unsigned        ApbAddrWidth = 32'd0,
  parameter int unsigned        AddrOffset   = 32'd4,
  parameter int unsigned        ApbDataWidth = 32'd0,
  parameter int unsigned        RegDataWidth = 32'd0,
  parameter bit [NoApbRegs-1:0] ReadOnly     = 32'h0,
  parameter type                req_t        = logic,
  parameter type                resp_t       = logic,
  parameter type apb_addr_t                  = logic[ApbAddrWidth-1:0],
  parameter type reg_data_t                  = logic[RegDataWidth-1:0]
) (
  input  logic                      pclk_i,
  input  logic                      preset_ni,
  input  req_t                      req_i,
  output resp_t                     resp_o,
  input  apb_addr_t                 base_addr_i,
  input  reg_data_t [NoApbRegs-1:0] reg_init_i,
  output reg_data_t [NoApbRegs-1:0] reg_q_o
);
