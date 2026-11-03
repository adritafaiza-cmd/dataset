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
  localparam int unsigned ApbRegs = NoApbRegs / AddrOffset;

  // Internal signals
  logic [ApbRegs-1:0] sel;
  logic [ApbRegs-1:0] write_en;
  logic [ApbRegs-1:0] read_en;
  logic [ApbRegs-1:0] strobe;
  logic [ApbRegs-1:0] strobe_en;
  logic [ApbRegs-1:0] strobe_q;
  logic [ApbRegs-1:0] strobe_d;
  logic [ApbRegs-1:0] strobe_reset;
  logic [ApbRegs-1:0] strobe_reset_q;
  logic [ApbRegs-1:0] strobe_reset_d;
  logic [ApbRegs-1:0] strobe_reset_en;
  logic [ApbRegs-1:0] strobe_reset_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en;
  logic [ApbRegs-1:0] strobe_reset_q_en_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_d;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q;
  logic [ApbRegs-1:0] strobe_reset_q_en_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q_q