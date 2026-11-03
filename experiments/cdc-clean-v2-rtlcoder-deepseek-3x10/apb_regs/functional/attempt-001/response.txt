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

  // Local parameters
  localparam int unsigned ApbRegWidth = ApbDataWidth / 8;
  localparam int unsigned ApbRegs     = ApbRegWidth * NoApbRegs;

  // Internal signals
  logic [ApbRegs-1:0] reg_q;
  logic [ApbRegs-1:0] reg_d;
  logic [ApbRegs-1:0] reg_we;
  logic [ApbRegs-1:0] reg_re;
  logic [ApbRegs-1:0] reg_strobe;
  logic [ApbRegs-1:0] reg_strobe_d;
  logic [ApbRegs-1:0] reg_strobe_q;
  logic [ApbRegs-1:0] reg_strobe_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] reg_strobe_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q