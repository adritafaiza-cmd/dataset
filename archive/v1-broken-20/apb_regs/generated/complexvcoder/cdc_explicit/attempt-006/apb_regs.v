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
  reg_data_t [NoApbRegs-1:0] reg_data;
  reg_data_t [NoApbRegs-1:0] reg_data_q;

  // Initialize registers from reg_init_i
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_data <= reg_init_i;
    end else if (req_i) begin
      // Calculate the address within the register file
      apb_addr_t addr = base_addr_i + (apb_addr_t'(reg_data_q) >> AddrOffset);
      if (addr < NoApbRegs) begin
        if (ReadOnly[addr]) begin
          reg_data[addr] <= reg_data[addr]; // Ignore writes to read-only registers
        end else begin
          reg_data[addr] <= reg_data_t'(req_t); // Write data to the register
        end
      end
    end
  end

  // Drive output with the current register values
  always_ff @(posedge pclk_i) begin
    reg_q_o <= reg_data;
  end

  // Handle response signal
  resp_o <= req_i;

endmodule
