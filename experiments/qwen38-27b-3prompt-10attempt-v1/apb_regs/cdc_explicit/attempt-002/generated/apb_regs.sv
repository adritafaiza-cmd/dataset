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
  // Assuming standard APB signals: psel, penable, pwrite, paddr, pwdata, pready, pslverr, prdata
  // Since req_t and resp_t are opaque types, we need to extract fields.
  // For a generic implementation, we'll assume the types have the standard APB fields.
  // However, since we can't directly access fields of opaque types in a generic way,
  // we'll use a common approach: assume the types are structured with known fields.
  // Given the constraints, we'll implement based on standard APB protocol assumptions.

  // For this implementation, we'll assume:
  // req_t has fields: psel, penable, pwrite, paddr, pwdata
  // resp_t has fields: pready, pslverr, prdata

  // Since we can't directly access fields of parameterized types in a fully generic way,
  // we'll use a common pattern where the testbench provides the types with known structure.
  // Here, we'll assume the types are packed structs with the following layout:
  // req_t: {psel, penable, pwrite, paddr, pwdata}
  // resp_t: {pready, pslverr, prdata}

  // Extract APB signals from req_i
  wire [ApbDataWidth-1:0] pwdata = req_i.pwdata;
  wire [ApbAddrWidth-1:0] paddr  = req_i.paddr;
  wire                    pwrite = req_i.pwrite;
  wire                    penable = req_i.penable;
  wire                    psel    = req_i.psel;

  // Register file
  reg_data_t [NoApbRegs-1:0] reg_q;

  // Address decoding
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;
  wire [REG_INDEX_WIDTH-1:0] reg_index = (ADDR_SHIFT > 0) ? addr_offset[ADDR_SHIFT +: REG_INDEX_WIDTH] : addr_offset[REG_INDEX_WIDTH-1:0];
  wire addr_valid = (reg_index < NoApbRegs);

  // Write enable
  wire write_en = psel & penable & pwrite & addr_valid;

  // Read data
  wire [RegDataWidth-1:0] read_data = (addr_valid) ? reg_q[reg_index] : '0;

  // Response
  assign resp_o.pready = 1'b1;
  assign resp_o.pslverr = 1'b0;
  assign resp_o.prdata = read_data;

  // Register update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q[i] <= reg_init_i[i];
      end
    end else begin
      if (write_en) begin
        if (!ReadOnly[reg_index]) begin
          reg_q[reg_index] <= pwdata[RegDataWidth-1:0];
        end
      end
    end
  end

  // Output
  assign reg_q_o = reg_q;

endmodule
