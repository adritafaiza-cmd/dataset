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

  // APB signal definitions
  typedef struct packed {
    logic PSEL;
    logic PENABLE;
    logic PWRITE;
    logic [ApbAddrWidth-1:0] PADDR;
    logic [ApbDataWidth-1:0] PWDATA;
  } req_t;

  typedef struct packed {
    logic PREADY;
    logic [ApbDataWidth-1:0] PRDATA;
  } resp_t;

  // Internal registers
  reg [RegDataWidth-1:0] reg_q [0:NoApbRegs-1];

  // Assign output array
  generate
    genvar i;
    for (i = 0; i < NoApbRegs; i = i + 1) begin : gen_reg_q_o
      assign reg_q_o[i] = reg_q[i];
    end
  endgenerate

  // Address range calculation
  localparam integer REG_SPACE_SIZE = NoApbRegs * AddrOffset;
  wire [ApbAddrWidth-1:0] upper_addr = base_addr_i + REG_SPACE_SIZE;
  wire valid_addr = (req_i.PADDR >= base_addr_i) && (req_i.PADDR < upper_addr);

  // Index calculation
  wire [ApbAddrWidth-1:0] addr_offset = req_i.PADDR - base_addr_i;
  wire [ApbAddrWidth-1:0] idx_raw = addr_offset / AddrOffset;
  wire valid_idx = (idx_raw < NoApbRegs);

  // Write enable logic
  wire write_enable = valid_addr && valid_idx && req_i.PSEL && req_i.PENABLE && 
                      req_i.PWRITE && !ReadOnly[idx_raw];

  // Read data
  wire [RegDataWidth-1:0] read_data = reg_q[idx_raw];

  // Response assignment
  assign resp_o.PREADY = 1'b1;
  assign resp_o.PRDATA = read_data;

  // Register update and reset logic
  integer j;
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (j = 0; j < NoApbRegs; j = j + 1) begin
        reg_q[j] <= reg_init_i[j];
      end
    end else begin
      if (write_enable) begin
        reg_q[idx_raw] <= req_i.PWDATA[RegDataWidth-1:0];
      end
    end
  end

endmodule
