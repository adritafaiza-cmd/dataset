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

  logic [NoApbRegs-1:0][RegDataWidth-1:0] reg_q;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q[i] <= reg_init_i[i];
      end
    end else if (req_i) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (base_addr_i == (base_addr_i + (i * (RegDataWidth / 8))) && !ReadOnly[i]) begin
          reg_q[i] <= req_i;
        end
      end
    end
  end

  assign reg_q_o = reg_q;

  always_comb begin
    resp_o = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (base_addr_i == (base_addr_i + (i * (RegDataWidth / 8)))) begin
        resp_o = reg_q[i];
      end
    end
  end

endmodule
