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

  // APB signal extraction
  // Assuming req_t has fields: psel, penable, pwrite, paddr, pwdata
  // Assuming resp_t has field: pready
  // We'll use direct field access based on common APB conventions

  wire psel    = req_i.psel;
  wire penable = req_i.penable;
  wire pwrite  = req_i.pwrite;
  wire [ApbAddrWidth-1:0] paddr = req_i.paddr;
  wire [ApbDataWidth-1:0] pwdata = req_i.pwdata;

  // Address decoding
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;
  wire [ApbAddrWidth-1:0] reg_index_raw = addr_offset >> ADDR_SHIFT;
  wire [REG_INDEX_WIDTH-1:0] reg_index = reg_index_raw[REG_INDEX_WIDTH-1:0];
  wire addr_valid = (reg_index < NoApbRegs) && (addr_offset == (reg_index << ADDR_SHIFT));

  // Write enable
  wire write_en = psel & penable & pwrite & addr_valid;

  // Register file
  reg_data_t [NoApbRegs-1:0] regs;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        regs[i] <= reg_init_i[i];
      end
    end else begin
      if (write_en) begin
        if (!ReadOnly[reg_index]) begin
          // Mask data to RegDataWidth
          regs[reg_index] <= pwdata[RegDataWidth-1:0];
        end
      end
    end
  end

  // Drive outputs
  assign reg_q_o = regs;

  // Response: pready is high when in SETUP phase (psel high, penable low)
  // or when write is complete
  assign resp_o.pready = psel & ~penable;

endmodule
