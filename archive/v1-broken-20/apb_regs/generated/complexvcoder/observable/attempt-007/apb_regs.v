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

  // Internal signals
  logic [ApbAddrWidth-1:0] addr;
  logic [RegDataWidth-1:0] data_in;
  logic [RegDataWidth-1:0] data_out;
  logic [NoApbRegs-1:0] reg_bank;
  logic [NoApbRegs-1:0] reg_bank_next;
  logic [RegDataWidth-1:0] mask;

  // Address decoding
  assign addr = base_addr_i + AddrOffset;

  // Write enable and data mask
  assign data_in = req_i ? reg_bank_next : reg_bank;
  assign mask = ~ReadOnly;

  // Register bank logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_bank <= reg_init_i;
    end else if (req_i && addr < NoApbRegs) begin
      reg_bank_next <= reg_bank;
      reg_bank_next[addr] <= (req_i && addr < NoApbRegs) ? (data_in & mask) : reg_bank[addr];
    end
  end

  // Output the register bank
  assign reg_q_o = reg_bank;

  // Response signal
  assign resp_o = req_i;

endmodule
