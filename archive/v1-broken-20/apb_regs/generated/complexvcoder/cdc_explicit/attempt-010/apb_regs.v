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

  logic [NoApbRegs-1:0][RegDataWidth-1:0] reg_file;
  logic [NoApbRegs-1:0] addr_decoded;
  logic [RegDataWidth-1:0] write_data;
  logic [RegDataWidth-1:0] read_data;
  logic [NoApbRegs-1:0] reg_write_en;
  logic [NoApbRegs-1:0] reg_read_en;

  // Decode address
  assign addr_decoded = (base_addr_i[ApbAddrWidth-1:ApbAddrWidth-AddrOffset] == base_addr_i[ApbAddrWidth-1:ApbAddrWidth-AddrOffset+RegDataWidth-1]) ? base_addr_i[ApbAddrWidth-AddrOffset-1:ApbAddrWidth-AddrOffset-RegDataWidth] : {NoApbRegs{1'b0}};

  // Register file write enable
  assign reg_write_en = req_i & ~preset_ni & ~ReadOnly[addr_decoded];

  // Register file read enable
  assign reg_read_en = req_i & ~preset_ni;

  // Write data to register file
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_file <= reg_init_i;
    end else if (reg_write_en) begin
      reg_file[addr_decoded] <= write_data;
    end
  end

  // Read data from register file
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      read_data <= {NoApbRegs{1'b0}};
    end else if (reg_read_en) begin
      read_data <= reg_file[addr_decoded];
    end
  end

  // Assign output
  assign resp_o = reg_read_en;
  assign reg_q_o = read_data;

endmodule
