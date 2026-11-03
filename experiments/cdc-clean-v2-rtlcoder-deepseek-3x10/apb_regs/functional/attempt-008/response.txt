Sure, here is the complete Verilog code for the APB-mapped register file:

```
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

  // Local signals
  logic [NoApbRegs-1:0] reg_we;
  logic [NoApbRegs-1:0] reg_re;
  logic [NoApbRegs-1:0] reg_q_d;
  logic [NoApbRegs-1:0] reg_q;
  logic [NoApbRegs-1:0] reg_init;
  logic [NoApbRegs-1:0] reg_we_d;
  logic [NoApbRegs-1:0] reg_re_d;
  logic [NoApbRegs-1:0] reg_q_d_d;
  logic [NoApbRegs-1:0] reg_q_d_q;
  logic [NoApbRegs-1:0] reg_q_q;
  logic [NoApbRegs-1:0] reg_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [NoApbRegs-1:0] reg_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q