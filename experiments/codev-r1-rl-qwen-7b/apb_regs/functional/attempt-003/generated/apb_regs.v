module apb_regs #(
  parameter int unsigned NoApbRegs = 32'd0,
  parameter int unsigned ApbAddrWidth = 32'd0,
  parameter int unsigned AddrOffset = 32'd4,
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

  // Internal signals
  logic [ApbAddrWidth-1:0] addr_diff;
  logic valid_access;
  logic [$clog2(NoApbRegs)-1:0] idx;
  logic is_write;
  logic [RegDataWidth-1:0] data_in;

  // Assume req_t has fields: we, addr, data
  // Extract fields from req_i (adjust based on actual structure)
  // For example:
  // struct packed { logic we; logic [ApbAddrWidth-1:0] addr; logic [RegDataWidth-1:0] data; } req_t;

  // Compute address difference from base_addr_i
  assign addr_diff = req_i.addr;

  // Check if the address is in the valid range
  assign valid_access = (addr_diff < (NoApbRegs * AddrOffset)) && (addr_diff >= 0);

  // Compute index
  assign idx = addr_diff / AddrOffset;

  // Check if index is valid
  wire valid_idx = (idx < NoApbRegs);

  // Check if the register is writable
  wire reg_writable = !ReadOnly[idx];

  // Handle writes
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q_o <= reg_init_i;
    end else begin
      if (valid_access && valid_idx && req_i.we && reg_writable) begin
        reg_q_o[idx] <= req_i.data;
      end
    end
  end

  // Handle reads (response is valid if access is valid)
  assign resp_o = valid_access && valid_idx;

endmodule
