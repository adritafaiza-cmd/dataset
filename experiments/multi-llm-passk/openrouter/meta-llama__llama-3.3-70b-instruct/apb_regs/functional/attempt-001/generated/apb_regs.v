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

  reg_data_t [NoApbRegs-1:0] reg_file;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_file[i] <= reg_init_i[i];
      end
    end else if (req_i.write) begin
      if (apb_addr_i >= base_addr_i && apb_addr_i < base_addr_i + (NoApbRegs * AddrOffset)) begin
        int index = (apb_addr_i - base_addr_i) / AddrOffset;
        if (!ReadOnly[index]) begin
          reg_file[index] <= apb_data_i;
        end
      end
    end
  end

  always_comb begin
    resp_o = '0;
    apb_data_o = '0;
    if (req_i.read || req_i.write) begin
      if (apb_addr_i >= base_addr_i && apb_addr_i < base_addr_i + (NoApbRegs * AddrOffset)) begin
        int index = (apb_addr_i - base_addr_i) / AddrOffset;
        if (req_i.read) begin
          apb_data_o = reg_file[index];
        end
        if (req_i.write &&!ReadOnly[index]) begin
          resp_o = '1;
        end else if (req_i.write && ReadOnly[index]) begin
          resp_o = '0;
        end
      end else begin
        resp_o = '0;
      end
    end
  end

  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_q_o[i] = reg_file[i];
    end
  end

endmodule
