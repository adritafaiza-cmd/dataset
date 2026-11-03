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

  logic [ApbAddrWidth-1:0] reg_addr;
  logic [RegDataWidth-1:0] reg_read_data;
  logic [RegDataWidth-1:0] reg_write_data;
  logic reg_write_en;
  logic reg_read_en;
  logic [NoApbRegs*RegDataWidth-1:0] reg_q;

  // Address decoding
  assign reg_addr = base_addr_i + (req_t[ApbAddrWidth-1:AddrOffset]) * AddrOffset;

  // Register file read
  assign reg_read_en = req_t[ApbAddrWidth-1:ApbAddrWidth-1] == 1'b0;
  assign reg_read_data = reg_q[reg_addr * RegDataWidth +: RegDataWidth];

  // Register file write
  assign reg_write_en = req_t[ApbAddrWidth-1:ApbAddrWidth-1] == 1'b1;
  assign reg_write_data = req_t[RegDataWidth-1:0];
  assign reg_q[reg_addr * RegDataWidth +: RegDataWidth] = ReadOnly[reg_addr] ? reg_q[reg_addr * RegDataWidth +: RegDataWidth] : reg_write_data;

  // Response generation
  assign resp_o = reg_write_en ? (reg_q[reg_addr * RegDataWidth +: RegDataWidth] == reg_write_data) : 1'b1;

  // Register initialization and output
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q <= reg_init_i;
    end else if (reg_write_en) begin
      reg_q[reg_addr * RegDataWidth +: RegDataWidth] <= reg_write_data;
    end
  end

  assign reg_q_o = reg_q;

endmodule
