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

  // Internal register bank
  logic [RegDataWidth-1:0] reg_data [NoApbRegs-1:0];

  // Initialize registers on reset
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_data <= reg_init_i;
    end else begin
      // Handle read and write requests
      if (req_i) begin
        reg_data[base_addr_i[AddrOffset+ApbAddrWidth-1:AddrOffset]] <= req_i.data;
      end
    end
  end

  // Read-only bits unchanged on writes
  always_comb begin
    resp_o = reg_data[base_addr_i[AddrOffset+ApbAddrWidth-1:AddrOffset]];
    for (int i = 0; i < NoApbRegs; i++) begin
      if (ReadOnly[i]) begin
        resp_o[i] = reg_init_i[i];
      end
    end
  end

  // Output register values
  assign reg_q_o = reg_data;

endmodule
