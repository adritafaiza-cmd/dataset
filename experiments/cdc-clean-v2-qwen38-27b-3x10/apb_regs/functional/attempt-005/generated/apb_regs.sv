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
  wire [ApbDataWidth-1:0] pwdata;
  wire [ApbDataWidth/8-1:0] pstrb;
  wire [ApbAddrWidth-1:0] paddr;

  assign psel    = req_i.psel;
  assign penable = req_i.penable;
  assign pwrite  = req_i.pwrite;
  assign pwdata  = req_i.pwdata;
  assign pstrb   = req_i.pstrb;
  assign paddr   = req_i.paddr;

  // Response
  assign resp_o.pready = 1'b1;
  assign resp_o.pslverr = 1'b0;
  assign resp_o.prdata  = '0; // Read data not required per spec, but drive zero

  // Register storage
  reg_data_t [NoApbRegs-1:0] reg_r;

  // Address decoding
  // Compute offset from base address
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;
  
  // Determine register index
  // Each register is spaced AddrOffset bytes apart
  // So register index = addr_offset / AddrOffset
  // We need to check if the address falls within the valid range for a register
  
  // Number of bits needed to index registers
  localparam int unsigned RegIndexWidth = $clog2(NoApbRegs > 0 ? NoApbRegs : 1);
  
  // Compute register index from address offset
  // addr_offset / AddrOffset
  // Since AddrOffset is a power of 2 (typically), we can use bit shifting
  // But to be safe, let's do division
  
  wire [ApbAddrWidth-1:0] reg_index_raw = addr_offset / AddrOffset;
  
  // Check if address is within bounds
  wire addr_valid = (reg_index_raw < NoApbRegs);
  
  // Check if the lower bits (within the register slot) are zero
  // This ensures we're accessing the start of a register slot
  // Actually, for APB, we typically want to accept any address within the slot
  // but the spec says "Each AddrOffset-byte decoded address range maps to its register"
  // So any address in [base + i*AddrOffset, base + (i+1)*AddrOffset - 1] maps to register i
  
  wire [RegIndexWidth-1:0] reg_index = reg_index_raw[RegIndexWidth-1:0];
  
  // Write enable: during access phase (psel & penable), write operation, valid address
  wire write_en = psel & penable & pwrite & addr_valid;
  
  // Byte strobe handling
  // RegDataWidth may be different from ApbDataWidth
  // We need to map byte strobes from APB data width to register data width
  
  // Number of bytes in register
  localparam int unsigned RegBytes = (RegDataWidth + 7) / 8;
  localparam int unsigned ApbBytes = (ApbDataWidth + 7) / 8;
  
  // For each register, update based on byte strobes
  // We'll create a combinational next-state logic
  
  reg_data_t [NoApbRegs-1:0] reg_next;
  
  always_comb begin
    // Default: keep current values
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_next[i] = reg_r[i];
    end
    
    // If write is enabled, update the target register
    if (write_en) begin
      // Apply byte strobes
      // Map APB byte strobes to register bytes
      // The APB data bus is ApbDataWidth bits wide
      // The register is RegDataWidth bits wide
      // We assume the register is aligned to the APB data bus
      // Byte i of the register corresponds to byte i of the APB data (if i < ApbBytes)
      
      for (int b = 0; b < RegBytes; b++) begin
        if (b < ApbBytes) begin
          if (pstrb[b]) begin
            // Extract byte from pwdata
            reg_next[reg_index][b*8 +: 8] = pwdata[b*8 +: 8];
          end
        end
        // If b >= ApbBytes, the byte is not affected by the APB write
        // (it remains unchanged)
      end
    end
  end

  // Sequential logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) begin
          reg_r[i] <= reg_init_i[i];
        end else begin
          reg_r[i] <= '0;
        end
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) begin
          // Read-only registers always expose reg_init_i
          reg_r[i] <= reg_init_i[i];
        end else begin
          reg_r[i] <= reg_next[i];
        end
      end
    end
  end

  // Output: read-only registers expose reg_init_i, writable registers expose reg_r
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      if (ReadOnly[i]) begin
        reg_q_o[i] = reg_init_i[i];
      end else begin
        reg_q_o[i] = reg_r[i];
      end
    end
  end

endmodule
