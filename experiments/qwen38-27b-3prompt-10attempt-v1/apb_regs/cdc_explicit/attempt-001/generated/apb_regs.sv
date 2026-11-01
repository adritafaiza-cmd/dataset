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

  // Local parameters
  localparam int unsigned ADDR_SHIFT = (AddrOffset == 1) ? 0 : $clog2(AddrOffset);
  localparam int unsigned REG_INDEX_WIDTH = (NoApbRegs > 1) ? $clog2(NoApbRegs) : 1;
  localparam int unsigned DATA_WIDTH = RegDataWidth;

  // APB signal extraction (assuming standard APB3/4 structure)
  // We need to extract: psel, penable, pwrite, paddr, pwdata, pready, preslverr, prdata
  // Since req_t and resp_t are opaque types, we assume they follow a standard APB structure.
  // For a generic implementation, we'll assume the request type has fields:
  //   .psel, .penable, .pwrite, .paddr, .pwdata
  // And response type has:
  //   .pready, .preslverr, .prdata

  // Extract APB signals from req_i
  wire        psel;
  wire        penable;
  wire        pwrite;
  wire [ApbAddrWidth-1:0] paddr;
  wire [ApbDataWidth-1:0] pwdata;

  assign psel    = req_i.psel;
  assign penable = req_i.penable;
  assign pwrite  = req_i.pwrite;
  assign paddr   = req_i.paddr;
  assign pwdata  = req_i.pwdata;

  // Response signals
  wire        pready;
  wire        preslverr;
  wire [ApbDataWidth-1:0] prdata;

  assign resp_o.pready    = pready;
  assign resp_o.preslverr = preslverr;
  assign resp_o.prdata    = prdata;

  // Register file
  reg_data_t [NoApbRegs-1:0] regs;

  // Address decoding
  // Calculate register index from address
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;
  wire [ApbAddrWidth-1:0] reg_index_raw = (ADDR_SHIFT > 0) ? addr_offset[ApbAddrWidth-1:ADDR_SHIFT] : addr_offset;
  wire [REG_INDEX_WIDTH-1:0] reg_index = reg_index_raw[REG_INDEX_WIDTH-1:0];
  wire addr_valid = (reg_index < NoApbRegs);

  // Read data
  wire [DATA_WIDTH-1:0] read_data = (addr_valid) ? regs[reg_index] : '0;

  // Write enable
  wire write_en = psel & penable & pwrite & addr_valid;

  // Write data (mask out read-only bits)
  wire [DATA_WIDTH-1:0] write_data = pwdata[DATA_WIDTH-1:0];
  wire [DATA_WIDTH-1:0] ro_mask = {DATA_WIDTH{1'b0}};
  // Build read-only mask for the selected register
  wire [DATA_WIDTH-1:0] ro_mask_reg = '0;
  generate
    for (genvar i = 0; i < NoApbRegs; i++) begin : gen_ro_mask
      if (ReadOnly[i]) begin
        // For simplicity, assume all bits are read-only if ReadOnly[i] is set
        // In a real implementation, you might have per-bit read-only masks
        assign ro_mask_reg = (reg_index == i) ? {DATA_WIDTH{1'b1}} : ro_mask_reg;
      end
    end
  endgenerate

  wire [DATA_WIDTH-1:0] masked_write_data = write_data & ~ro_mask_reg;

  // Register update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        regs[i] <= reg_init_i[i];
      end
    end else begin
      if (write_en) begin
        regs[reg_index] <= masked_write_data;
      end
    end
  end

  // Drive output
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_q_o[i] = regs[i];
    end
  end

  // APB response
  // In APB, pready is typically asserted in the same cycle as penable for a simple register file
  assign pready    = 1'b1;
  assign preslverr = 1'b0;
  assign prdata    = (pwrite) ? '0 : read_data[ApbDataWidth-1:0];

endmodule
