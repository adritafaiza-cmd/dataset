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

  // Internal signals
  reg_data_t reg_data [NoApbRegs-1:0];
  reg_data_t write_data;
  reg_data_t read_data;
  logic write_enable;
  logic read_enable;

  // Register initialization
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_data <= reg_init_i;
    end else if (write_enable) begin
      reg_data[write_data[AddrOffset+:$clog2(NoApbRegs)-1]] <= write_data[RegDataWidth-1:0];
    end
  end

  // Write logic
  assign write_enable = req_i && (base_addr_i[ApbAddrWidth-1:ApbAddrWidth-$clog2(NoApbRegs)] == base_addr_i[ApbAddrWidth-1:ApbAddrWidth-$clog2(NoApbRegs)]);
  assign write_data = {req_i, base_addr_i[$clog2(NoApbRegs)-1:0], req_i ? req_i : reg_data[base_addr_i[$clog2(NoApbRegs)-1:0]]};

  // Read logic
  assign read_enable = req_i && (base_addr_i[ApbAddrWidth-1:ApbAddrWidth-$clog2(NoApbRegs)] == base_addr_i[ApbAddrWidth-1:ApbAddrWidth-$clog2(NoApbRegs)]);
  assign read_data = reg_data[base_addr_i[$clog2(NoApbRegs)-1:0]];

  // Output logic
  assign reg_q_o = reg_data;
  assign resp_o = write_enable || read_enable;

endmodule
