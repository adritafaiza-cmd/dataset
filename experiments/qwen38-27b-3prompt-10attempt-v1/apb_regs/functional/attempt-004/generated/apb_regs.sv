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

  // Extract APB fields from req_t
  // Assuming req_t has fields: psel, penable, pwrite, paddr, pwdata
  // We'll use member access if available, otherwise assume packed struct
  // For generic APB, we assume req_t contains:
  //   bit psel
  //   bit penable
  //   bit pwrite
  //   apb_addr_t paddr
  //   logic [ApbDataWidth-1:0] pwdata

  // Since req_t is a type parameter, we need to access its fields.
  // In SystemVerilog, if req_t is a struct, we can use dot notation.
  // Let's assume the standard APB request structure.

  wire        psel    = req_i.psel;
  wire        penable = req_i.penable;
  wire        pwrite  = req_i.pwrite;
  wire [ApbAddrWidth-1:0] paddr = req_i.paddr;
  wire [ApbDataWidth-1:0] pwdata = req_i.pwdata;

  // Response fields
  // Assuming resp_t has: pready, prdata, pslverr
  // We'll drive resp_o fields

  // Compute register index from address
  // Address offset from base
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;
  
  // Convert byte offset to register index
  // AddrOffset is in bytes
  wire [ApbAddrWidth-1:0] reg_index_raw = addr_offset / AddrOffset;
  
  // Check if address is valid
  wire addr_valid = (reg_index_raw < NoApbRegs) && 
                    ((addr_offset % AddrOffset) == 0);

  // Register index
  wire [ApbAddrWidth-1:0] reg_index = reg_index_raw;

  // Read data
  wire [RegDataWidth-1:0] read_data = reg_q_o[reg_index];

  // Write enable
  wire write_en = psel & penable & pwrite & addr_valid;

  // Write data - need to handle width mismatch between ApbDataWidth and RegDataWidth
  // Assume ApbDataWidth >= RegDataWidth or they are equal
  // For simplicity, take lower RegDataWidth bits of pwdata
  wire [RegDataWidth-1:0] write_data = pwdata[RegDataWidth-1:0];

  // Register file
  reg_data_t [NoApbRegs-1:0] reg_q;

  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q[i] <= reg_init_i[i];
      end
    end else begin
      if (write_en) begin
        if (!ReadOnly[reg_index]) begin
          reg_q[reg_index] <= write_data;
        end
      end
    end
  end

  // Drive output
  assign reg_q_o = reg_q;

  // Response
  // pready: ready when in setup phase (psel & !penable) or access phase (psel & penable)
  // For simple APB slave, pready is high when psel is high
  // prdata: read data
  // pslverr: error if address invalid

  // Assuming resp_t has fields: pready, prdata, pslverr
  // We need to construct resp_o

  // Since resp_t is a type parameter, we need to assign its fields
  // Let's assume resp_t is a struct with pready, prdata, pslverr

  // For APB, pready is typically asserted in the setup phase
  // Simple implementation: pready = psel
  // prdata = read_data
  // pslverr = !addr_valid & psel & penable

  // We'll use a continuous assignment to build resp_o
  // But since resp_t is a type, we need to be careful

  // Let's assume resp_t has the following fields:
  //   bit pready
  //   logic [ApbDataWidth-1:0] prdata
  //   bit pslverr

  // Build response
  always_comb begin
    resp_o.pready = psel;
    resp_o.prdata = {((ApbDataWidth - RegDataWidth) {1'b0}), read_data};
    resp_o.pslverr = psel & penable & !addr_valid;
  end

endmodule
