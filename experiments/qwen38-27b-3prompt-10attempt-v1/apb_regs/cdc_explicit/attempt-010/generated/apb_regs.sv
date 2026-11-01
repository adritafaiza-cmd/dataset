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

  // APB signal extraction from req_t
  // Assuming req_t has fields: psel, penable, pwrite, paddr, pwdata
  // We'll use a struct-like access. Since req_t is a type parameter, we assume it's a struct
  // with the standard APB signals. For generality, we'll cast or access fields.
  // In SystemVerilog, if req_t is a struct, we can access fields directly.
  // Let's assume the struct has: psel, penable, pwrite, paddr, pwdata
  
  // For safety, we'll use a typedef to extract fields. But since req_t is a type parameter,
  // we need to handle it generically. Let's assume the testbench provides a struct with
  // the following fields: psel, penable, pwrite, paddr, pwdata.
  
  // We'll create local signals for the APB signals
  logic        psel;
  logic        penable;
  logic        pwrite;
  apb_addr_t   paddr;
  reg_data_t   pwdata;

  // Extract APB signals from req_i
  // This assumes req_t is a struct with these fields
  assign psel    = req_i.psel;
  assign penable = req_i.penable;
  assign pwrite  = req_i.pwrite;
  assign paddr   = req_i.paddr;
  assign pwdata  = req_i.pwdata;

  // Response signals
  logic        pready;
  logic        pslverr;
  reg_data_t   prdata;

  // Assign response
  assign resp_o.pready  = pready;
  assign resp_o.pslverr = pslverr;
  assign resp_o.prdata  = prdata;

  // Register file
  reg_data_t [NoApbRegs-1:0] regs;

  // Address decoding
  // Calculate register index from address
  // addr_offset = paddr - base_addr_i
  // reg_index = addr_offset / AddrOffset
  apb_addr_t addr_offset;
  logic [REG_INDEX_WIDTH-1:0] reg_index;
  logic addr_valid;

  assign addr_offset = paddr - base_addr_i;
  assign reg_index = addr_offset[REG_INDEX_WIDTH + ADDR_SHIFT - 1 : ADDR_SHIFT];
  assign addr_valid = (reg_index < NoApbRegs) && (addr_offset[ADDR_SHIFT-1:0] == '0);

  // Read data
  assign prdata = addr_valid ? regs[reg_index] : '0;

  // Write enable
  logic write_en;
  assign write_en = psel & penable & pwrite & addr_valid;

  // Register update logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        regs[i] <= reg_init_i[i];
      end
    end else begin
      if (write_en) begin
        if (!ReadOnly[reg_index]) begin
          regs[reg_index] <= pwdata;
        end
      end
    end
  end

  // Drive output
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_q_o[i] = regs[i];
    end
  end

  // APB protocol: pready is always high (single-cycle response)
  assign pready  = 1'b1;
  assign pslverr = 1'b0;

endmodule
