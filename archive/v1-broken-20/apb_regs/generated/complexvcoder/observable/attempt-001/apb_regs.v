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

  localparam int unsigned RegFileSize = NoApbRegs * RegDataWidth;
  reg_data_t reg_file [0:NoApbRegs-1];
  reg_data_t reg_init [0:NoApbRegs-1];
  resp_t resp;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_file <= reg_init;
      resp <= 1'b0;
    end else begin
      if (req_i) begin
        if (base_addr_i[ApbAddrWidth-1:AddrOffset] < NoApbRegs) begin
          reg_file[base_addr_i[ApbAddrWidth-1:AddrOffset]] <= reg_init_i[base_addr_i[ApbAddrWidth-1:AddrOffset]];
        end
        resp <= 1'b1;
      end else begin
        resp <= 1'b0;
      end
    end
  end

  assign reg_q_o = reg_file;
  assign resp_o = resp;

endmodule
