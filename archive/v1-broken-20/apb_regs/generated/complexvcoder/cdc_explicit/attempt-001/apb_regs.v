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

  // Local parameters for convenience
  localparam int unsigned ADDR_WIDTH = ApbAddrWidth;
  localparam int unsigned DATA_WIDTH = RegDataWidth;
  localparam int unsigned ADDR_SIZE  = NoApbRegs;
  localparam int unsigned ADDR_MASK  = ADDR_SIZE - 1;

  // Register file
  reg_data_t [NoApbRegs-1:0] reg_file;

  // Internal signals
  logic [DATA_WIDTH-1:0] read_data;
  logic [DATA_WIDTH-1:0] write_data;
  logic [ADDR_WIDTH-1:0] reg_addr;
  logic reg_en;
  logic [DATA_WIDTH-1:0] mask;

  // Assign initial values to register file
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_file <= reg_init_i;
    end else begin
      if (reg_en) begin
        reg_file[reg_addr] <= write_data;
      end
    end
  end

  // Generate read and write enable
  assign reg_en = req_i && (reg_addr < ADDR_SIZE);

  // Generate read address
  assign reg_addr = (base_addr_i >> AddrOffset) & ADDR_MASK;

  // Generate write data
  assign write_data = req_i ? req_i.write_data : 0;

  // Generate mask for read-only bits
  assign mask = ReadOnly << reg_addr;

  // Generate read data
  assign read_data = reg_file[reg_addr] & ~mask;

  // Assign output
  assign resp_o = read_data;

  // Assign register output
  assign reg_q_o = reg_file;

endmodule
