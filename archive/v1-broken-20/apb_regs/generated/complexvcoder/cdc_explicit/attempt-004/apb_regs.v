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

  logic [NoApbRegs-1:0][RegDataWidth-1:0] regs;
  logic [NoApbRegs-1:0] addr_valid;
  logic [NoApbRegs-1:0] write_en;
  logic [NoApbRegs-1:0] read_en;

  // Address decoding
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      addr_valid <= {NoApbRegs{1'b0}};
    end else begin
      addr_valid <= {NoApbRegs{(apb_addr_i >= base_addr_i) && (apb_addr_i < base_addr_i + NoApbRegs * AddrOffset)}};
    end
  end

  // Write enable logic
  assign write_en = addr_valid && req_i && (apb_addr_i[RegDataWidth-1:0] == 1'b0); // Assuming write enable bit is the least significant bit

  // Read enable logic
  assign read_en = addr_valid && req_i && (apb_addr_i[RegDataWidth-1:0] == 1'b1); // Assuming read enable bit is the least significant bit

  // Register write logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      regs <= reg_init_i;
    end else begin
      if (write_en) begin
        regs[apb_addr_i[AddrOffset-1:0]] <= req_i ? reg_data_t {ReadOnly, reg_data_t{RegDataWidth{1'b0}}} : reg_data_t {ReadOnly, reg_data_t{RegDataWidth{1'b0}}};
      end
    end
  end

  // Register read logic
  assign reg_q_o = {NoApbRegs{addr_valid ? regs[apb_addr_i[AddrOffset-1:0]] : reg_data_t{RegDataWidth{1'b0}}}};

  // Response logic
  assign resp_o = addr_valid && req_i;

endmodule
