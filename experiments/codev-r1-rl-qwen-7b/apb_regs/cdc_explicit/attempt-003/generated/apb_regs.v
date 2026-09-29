module apb_regs #(
  parameter int unsigned NoApbRegs    = 32'd0,
  parameter int unsigned ApbAddrWidth = 32'd0,
  parameter int unsigned AddrOffset   = 32'd4,
  parameter int unsigned ApbDataWidth = 32'd0,
  parameter int unsigned RegDataWidth = 32'd0,
  parameter bit [NoApbRegs-1:0] ReadOnly = 32'h0,
  parameter type req_t = logic,
  parameter type resp_t = logic,
  parameter type apb_addr_t = logic[ApbAddrWidth-1:0],
  parameter type reg_data_t = logic[RegDataWidth-1:0]
) (
  input logic pclk_i,
  input logic preset_ni,
  input req_t req_i,
  output resp_t resp_o,
  input apb_addr_t base_addr_i,
  input reg_data_t [NoApbRegs-1:0] reg_init_i,
  output reg_data_t [NoApbRegs-1:0] reg_q_o
);

  // Assuming req_t contains addr, write, data fields
  // Extract fields from req_t (adjust based on actual struct)
  localparam integer AddrWidth = $bits(apb_addr_t);
  localparam integer DataWidth = $bits(reg_data_t);

  // Address offset calculation
  wire [AddrWidth-1:0] addr_offset = req_i.addr - base_addr_i;
  wire aligned = (addr_offset % AddrOffset) == 0;
  localparam integer IndexWidth = $clog2(NoApbRegs);
  wire [IndexWidth-1:0] index = addr_offset / AddrOffset;

  // Valid access check
  wire valid_access = (index < NoApbRegs) && aligned;

  // Response assignment
  assign resp_o = valid_access ? 'OKAY : 'ERROR;

  // Register array
  reg [RegDataWidth-1:0] regs [0:NoApbRegs-1];

  // Read logic
  generate
    genvar i;
    for (i = 0; i < NoApbRegs; i = i + 1) begin : gen_reg_q
      assign reg_q_o[i] = regs[i];
    end
  endgenerate

  // Write and reset logic
  integer j;
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (j = 0; j < NoApbRegs; j = j + 1) begin
        regs[j] <= reg_init_i[j];
      end
    end else begin
      if (valid_access && !ReadOnly[index] && req_i.write) begin
        regs[index] <= req_i.data;
      end
    end
  end

endmodule
