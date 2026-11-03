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

  reg_data_t [NoApbRegs-1:0] reg_file;
  reg_data_t [NoApbRegs-1:0] reg_init;
  reg_data_t [NoApbRegs-1:0] reg_q;
  reg [ApbAddrWidth-1:0] addr;

  assign addr = base_addr_i + AddrOffset;
  assign reg_init = reg_init_i;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_file <= reg_init;
      resp_o <= 1'b0;
    end else begin
      if (req_i) begin
        reg_data_t data_in;
        data_in = reg_init[addr[ApbAddrWidth-1:AddrOffset]] | (reg_file[addr[ApbAddrWidth-1:AddrOffset]] & ~ReadOnly);
        reg_file[addr[ApbAddrWidth-1:AddrOffset]] <= data_in;
        resp_o <= 1'b1;
      end else begin
        resp_o <= 1'b0;
      end
    end
  end

  assign reg_q_o = reg_file;

endmodule
