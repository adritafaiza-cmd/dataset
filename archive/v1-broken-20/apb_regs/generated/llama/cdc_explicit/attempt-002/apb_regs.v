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
  input  apb_addr_t                 apb_addr_i,
  input  reg_data_t                 apb_data_i,
  output reg_data_t                 apb_data_o,
  input  reg_data_t [NoApbRegs-1:0] reg_init_i,
  output reg_data_t [NoApbRegs-1:0] reg_q_o
);

  logic [NoApbRegs-1:0] reg_q;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q[i] <= reg_init_i[i];
      end
    end else if (req_i) begin
      if (apb_addr_i >= (apb_addr_t'(AddrOffset * (NoApbRegs - 1)))) begin
        resp_o <= '0;
      end else if (apb_addr_i % AddrOffset == 0) begin
        int idx = apb_addr_i / AddrOffset;
        if (!ReadOnly[idx]) begin
          reg_q[idx] <= apb_data_i;
        end
        resp_o <= '1;
      end else begin
        resp_o <= '0;
      end
    end
  end

  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      if (apb_addr_i == (apb_addr_t'(AddrOffset * i))) begin
        apb_data_o = reg_q[i];
      end else begin
        apb_data_o = '0;
      end
    end
    reg_q_o = reg_q;
  end

endmodule
