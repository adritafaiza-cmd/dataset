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
  input  reg_data_t [NoApbRegs-1:0] reg_init_i,
  output reg_data_t [NoApbRegs-1:0] reg_q_o
);

  logic [NoApbRegs-1:0][RegDataWidth-1:0] reg_file;
  logic [NoApbRegs-1:0][RegDataWidth-1:0] reg_file_q;

  assign reg_q_o = reg_file_q;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (~preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_file[i] <= reg_init_i[i];
      end
    end else begin
      if (req_i) begin
        apb_addr_t addr;
        assign addr = apb_addr_i;
        int unsigned idx;
        assign idx = (addr - base_addr_i) / AddrOffset;
        if (idx < NoApbRegs) begin
          if (~ReadOnly[idx]) begin
            reg_file[idx] <= req_i;
          end
        end
      end
    end
  end

  always_ff @(posedge pclk_i) begin
    reg_file_q <= reg_file;
    if (req_i) begin
      apb_addr_t addr;
      assign addr = apb_addr_i;
      int unsigned idx;
      assign idx = (addr - base_addr_i) / AddrOffset;
      if (idx < NoApbRegs) begin
        resp_o <= reg_file_q[idx];
      end else begin
        resp_o <= '0;
      end
    end
  end

endmodule
