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

  // Extract APB signals from req_t
  wire psel;
  wire penable;
  wire pwrite;
  wire [ApbAddrWidth-1:0] paddr;
  wire [ApbDataWidth-1:0] pwdata;
  wire [ApbDataWidth/8-1:0] pstrb;

  assign psel    = req_i.psel;
  assign penable = req_i.penable;
  assign pwrite  = req_i.pwrite;
  assign paddr   = req_i.paddr;
  assign pwdata  = req_i.pwdata;
  assign pstrb   = req_i.pstrb;

  // Response
  assign resp_o.pready = 1'b1;
  assign resp_o.pslverr = 1'b0;
  assign resp_o.prdata  = 8'h0; // Not used for write, but must be driven

  // Register storage
  reg_data_t [NoApbRegs-1:0] reg_r;

  // Address decoding
  // Calculate offset from base address
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;
  
  // Determine register index
  // Each register is spaced AddrOffset bytes apart
  // So index = addr_offset / AddrOffset
  // We need to check if the address falls within the valid range for a register
  wire [ApbAddrWidth-1:0] reg_index_raw = addr_offset / AddrOffset;
  
  // Check if the address is within the register bank
  wire addr_valid = (reg_index_raw < NoApbRegs) && 
                    ((addr_offset % AddrOffset) == 0);
  
  // Only decode when in access phase
  wire in_access_phase = psel & penable;
  wire write_valid = in_access_phase & pwrite & addr_valid;
  
  // Register index for current access
  wire [ApbAddrWidth-1:0] reg_index = reg_index_raw;
  
  // Byte strobe handling
  // RegDataWidth may be different from ApbDataWidth
  // We need to map the APB data and strobes to the register width
  
  // For simplicity, assume RegDataWidth <= ApbDataWidth and aligned
  // The register is RegDataWidth bits wide
  // APB data is ApbDataWidth bits wide
  // We take the lower RegDataWidth bits of pwdata and pstrb
  
  wire [RegDataWidth-1:0] reg_wdata = pwdata[RegDataWidth-1:0];
  wire [RegDataWidth/8-1:0] reg_wstrb = pstrb[RegDataWidth/8-1:0];
  
  // Write logic
  integer i;
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (i = 0; i < NoApbRegs; i = i + 1) begin
        if (ReadOnly[i])
          reg_r[i] <= reg_init_i[i];
        else
          reg_r[i] <= '0;
      end
    end else begin
      if (write_valid) begin
        // Write to the selected register
        for (i = 0; i < RegDataWidth/8; i = i + 1) begin
          if (reg_wstrb[i]) begin
            reg_r[reg_index][i*8 +: 8] <= reg_wdata[i*8 +: 8];
          end
        end
      end
    end
  end

  // Output register values
  // Read-only registers expose reg_init_i, writable registers expose reg_r
  generate
    for (genvar i = 0; i < NoApbRegs; i = i + 1) begin : gen_reg_out
      if (ReadOnly[i])
        assign reg_q_o[i] = reg_init_i[i];
      else
        assign reg_q_o[i] = reg_r[i];
    end
  endgenerate

endmodule
