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
  reg_data_t [NoApbRegs-1:0] read_data;
  logic [NoApbRegs-1:0] write_en;

  // Initialize register file with initial values
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_file <= reg_init_i;
    end else if (req_i) begin
      reg_file[write_en] <= read_data;
    end
  end

  // Calculate read data
  always_comb begin
    read_data = 0;
    if (req_i) begin
      read_data = reg_file[base_addr_i[AddrOffset+:$clog2(NoApbRegs)]];
    end
  end

  // Calculate write enable
  always_comb begin
    write_en = 0;
    if (req_i && !ReadOnly[base_addr_i[AddrOffset+:$clog2(NoApbRegs)]]) begin
      write_en = base_addr_i[AddrOffset+:$clog2(NoApbRegs)];
    end
  end

  // Output the register values
  assign reg_q_o = reg_file;

  // Generate response signal
  assign resp_o = req_i;

endmodule
