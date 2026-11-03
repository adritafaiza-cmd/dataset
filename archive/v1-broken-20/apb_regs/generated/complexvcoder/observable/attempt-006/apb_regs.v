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

  localparam int unsigned RegFileDepth = NoApbRegs;

  logic [RegDataWidth-1:0] reg_data [RegFileDepth-1:0];
  logic [RegDataWidth-1:0] read_data;
  logic [RegDataWidth-1:0] write_data;
  logic write_en;
  logic read_en;
  logic [ApbAddrWidth-1:0] addr;

  assign resp_o = req_i;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_data <= reg_init_i;
    end else begin
      if (write_en) begin
        if (~ReadOnly[addr]) begin
          reg_data[addr] <= write_data;
        end
      end
    end
  end

  always_comb begin
    read_en = 1'b0;
    write_en = 1'b0;
    addr = 0;
    read_data = 0;
    write_data = 0;

    if (req_i) begin
      addr = (base_addr_i - base_addr_i[AddrOffset-1:0]) >> AddrOffset;
      if (addr < RegFileDepth) begin
        if (req_i[1]) begin
          read_en = 1'b1;
          read_data = reg_data[addr];
        end else begin
          write_en = 1'b1;
          write_data = req_i[0] ? req_i[2:31] : 0;
        end
      end
    end
  end

  assign reg_q_o = reg_data;

endmodule
