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

  reg_data_t [NoApbRegs-1:0] registers;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      registers <= reg_init_i;
      reg_q_o <= reg_init_i;
    end else begin
      reg_q_o <= registers;
      if (req_i) begin
        resp_o <= 1'b1; // Assuming resp_o is set to acknowledge the request
        if (registers[base_addr_i/AddrOffset] != ReadOnly[base_addr_i/AddrOffset]) begin
          registers[base_addr_i/AddrOffset] <= reg_data_t'(base_addr_i[ApbAddrWidth-1:ApbAddrWidth-RegDataWidth]);
        end
      end else begin
        resp_o <= 1'b0; // Assuming resp_o is set to indicate no request
      end
    end
  end

endmodule
