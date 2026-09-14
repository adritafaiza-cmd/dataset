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
  reg_data_t [RegDataWidth-1:0] read_data;
  reg_data_t [RegDataWidth-1:0] write_data;
  reg_addr_t [ApbAddrWidth-1:0] addr;

  assign addr = base_addr_i + (paddr_i - base_addr_i) / AddrOffset;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_file <= reg_init_i;
    end else if (req_i) begin
      if (addr < NoApbRegs) begin
        if (pwrite_i) begin
          reg_file[addr] <= pwrite_data_i;
        end
        read_data <= reg_file[addr];
      end
      resp_o <= 1'b1; // Assuming resp_o is high on response
    end else begin
      resp_o <= 1'b0;
    end
  end

  assign reg_q_o = reg_file;

endmodule
