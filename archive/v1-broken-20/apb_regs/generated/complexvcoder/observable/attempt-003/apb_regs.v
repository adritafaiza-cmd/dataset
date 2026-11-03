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

  localparam int unsigned RegFileWidth = NoApbRegs * RegDataWidth;
  localparam int unsigned AddrWidth = ApbAddrWidth - AddrOffset;

  reg_data_t reg_file [NoApbRegs-1:0];
  reg_data_t reg_init [NoApbRegs-1:0];
  reg_data_t reg_read [NoApbRegs-1:0];
  reg_data_t reg_write [NoApbRegs-1:0];
  reg_data_t reg_mask [NoApbRegs-1:0];
  req_t reg_req;
  resp_t reg_resp;

  // Initialize register file with initial values
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_file <= reg_init_i;
    end else if (reg_req) begin
      if (reg_resp) begin
        reg_file[reg_mask] <= reg_write[reg_mask];
      end
    end
  end

  // Register file read logic
  always_comb begin
    reg_read = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (base_addr_i[AddrWidth-1:0] == i) begin
        reg_read[i] = reg_file[i];
      end
    end
  end

  // Register file write logic
  always_comb begin
    reg_write = '0;
    reg_mask = '0;
    if (req_i && base_addr_i[AddrWidth-1:0] < NoApbRegs) begin
      reg_write[base_addr_i[AddrWidth-1:0]] = reg_data_t'(reg_data_i);
      reg_mask[base_addr_i[AddrWidth-1:0]] = 1'b1;
    end
  end

  // Register file write enable logic
  always_comb begin
    reg_req = req_i && (reg_mask != '0);
  end

  // Register file response logic
  assign reg_resp = reg_req;

  // Register file output logic
  assign reg_q_o = reg_read;

  // APB interface logic
  assign resp_o = reg_resp;

endmodule
