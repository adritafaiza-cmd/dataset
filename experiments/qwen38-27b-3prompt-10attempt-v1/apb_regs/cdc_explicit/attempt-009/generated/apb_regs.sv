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

  // APB signal extraction from req_t
  // Assuming req_t has fields: psel, penable, pwrite, paddr, pwdata
  // We'll use a typedef or direct field access. Since req_t is a parameter type,
  // we assume it's a struct with these fields.
  
  // For APB, we need to decode the request
  // APB protocol:
  // - PSEL: select
  // - PENABLE: enable
  // - PWRITE: write (1) or read (0)
  // - PADDR: address
  // - PWDATA: write data
  // - PREADY: ready
  // - PRESP: response (0=OKAY, 1=ERROR)
  
  // We'll assume req_t is a struct with these fields.
  // Since we can't directly access struct fields without knowing the exact type,
  // we'll use a localparam to define the expected structure.
  
  // Actually, since req_t is a parameter type, we need to handle it generically.
  // The testbench will provide the type. Let's assume it has the standard APB fields.
  
  // For simplicity and to work with the given interface, let's assume:
  // req_t has: psel, penable, pwrite, paddr, pwdata
  // resp_t has: pready, presp
  
  // We'll create local signals to extract these
  wire        psel;
  wire        penable;
  wire        pwrite;
  wire [ApbAddrWidth-1:0] paddr;
  wire [ApbDataWidth-1:0] pwdata;
  
  // Extract from req_t - this assumes req_t is a struct with these fields
  // Since we can't do this generically without knowing the exact type,
  // we'll use a case where the testbench defines req_t appropriately.
  
  // For a robust implementation, we'll assume the following field names:
  // req_t: psel, penable, pwrite, paddr, pwdata
  // resp_t: pready, presp
  
  // Let's use a local typedef to help with extraction
  // Actually, in SystemVerilog, if req_t is a struct, we can access fields directly.
  
  // Let's assume the standard APB field names
  assign psel    = req_i.psel;
  assign penable = req_i.penable;
  assign pwrite  = req_i.pwrite;
  assign paddr   = req_i.paddr;
  assign pwdata  = req_i.pwdata;
  
  // Response signals
  wire        pready;
  wire        presp;
  
  assign resp_o.pready = pready;
  assign resp_o.presp  = presp;
  
  // Register file
  reg_data_t [NoApbRegs-1:0] reg_q;
  
  // Address decoding
  // Calculate register index from address
  // addr_offset in bytes, so we need to shift by log2(AddrOffset)
  // The address is relative to base_addr_i
  
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;
  
  // Extract register index
  // If AddrOffset is a power of 2, we can shift
  // Otherwise, we need to divide
  // For simplicity, assume AddrOffset is a power of 2 (common case: 4)
  
  wire [REG_INDEX_WIDTH-1:0] reg_index;
  
  if (ADDR_SHIFT > 0) begin
    assign reg_index = addr_offset[ADDR_SHIFT +: REG_INDEX_WIDTH];
  end else begin
    assign reg_index = addr_offset[REG_INDEX_WIDTH-1:0];
  end
  
  // Check if address is valid
  wire addr_valid = (reg_index < NoApbRegs);
  
  // APB state machine
  // APB has two phases: SETUP and ACCESS
  // In SETUP: PSEL=1, PENABLE=0
  // In ACCESS: PSEL=1, PENABLE=1
  
  wire apb_setup  = psel & ~penable;
  wire apb_access = psel & penable;
  
  // Ready signal - always ready in this simple implementation
  assign pready = 1'b1;
  
  // Response - OKAY for valid addresses, ERROR for invalid
  assign presp = ~addr_valid;
  
  // Write enable
  wire write_en = apb_access & pwrite & addr_valid;
  
  // Read data
  wire [DATA_WIDTH-1:0] read_data;
  
  // Generate read data
  generate
    if (NoApbRegs > 0) begin : gen_read
      assign read_data = reg_q[reg_index];
    end else begin : gen_read_empty
      assign read_data = '0;
    end
  endgenerate
  
  // Register update logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q[i] <= reg_init_i[i];
      end
    end else begin
      if (write_en) begin
        // Mask out read-only bits
        reg_q[reg_index] <= (reg_q[reg_index] & {DATA_WIDTH{ReadOnly[reg_index]}}) |
                             (pwdata[DATA_WIDTH-1:0] & {DATA_WIDTH{~ReadOnly[reg_index]}});
      end
    end
  end
  
  // Output registers
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_q_o[i] = reg_q[i];
    end
  end
  
endmodule
