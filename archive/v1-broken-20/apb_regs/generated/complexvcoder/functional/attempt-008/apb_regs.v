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
  reg_data_t [RegDataWidth-1:0] data_in;
  reg_data_t [RegDataWidth-1:0] data_out;
  apb_addr_t addr;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_file <= reg_init_i;
    end else if (req_i) begin
      addr = base_addr_i / AddrOffset;
      data_in = data_out;
      if (addr < NoApbRegs) begin
        if (ReadOnly[addr]) begin
          reg_file[addr] <= reg_file[addr]; // Ignore write
        end else begin
          reg_file[addr] <= data_in;
        end
      end
    end
  end

  always_comb begin
    data_out = reg_file[base_addr_i / AddrOffset];
  end

  assign resp_o = req_i;

  assign reg_q_o = reg_file;

endmodule
