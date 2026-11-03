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
  wire        psel    = req_i.psel;
  wire        penable = req_i.penable;
  wire        pwrite  = req_i.pwrite;
  wire [ApbAddrWidth-1:0] paddr = req_i.paddr;
  wire [ApbDataWidth-1:0] pwdata = req_i.pwdata;
  wire [ApbDataWidth/8-1:0] pstrb = req_i.pstrb;

  // Response
  assign resp_o.pready = 1'b1;
  assign resp_o.pslverr = 1'b0;
  assign resp_o.prdata = 8'h0; // Not used in this simplified interface

  // Register storage
  reg_data_t [NoApbRegs-1:0] reg_r;

  // Address decoding
  // Each register occupies AddrOffset bytes starting at base_addr_i + i*AddrOffset
  // The address offset from base determines which register
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;
  
  // Determine register index from address
  // addr_offset / AddrOffset gives the register index
  // We need to handle the division carefully
  wire [ApbAddrWidth-1:0] reg_idx_raw = addr_offset / AddrOffset;
  
  // Check if address is within valid range
  wire addr_valid = (reg_idx_raw < NoApbRegs) && 
                    ((addr_offset % AddrOffset) == 0);

  // Determine which register is being accessed
  wire [ApbAddrWidth-1:0] reg_idx = addr_valid ? reg_idx_raw : 0;

  // Write enable: APB write phase (psel & penable & pwrite)
  wire write_en = psel & penable & pwrite & addr_valid;

  // Read data for response (not fully implemented in this interface)
  // For now, we just need to handle writes correctly

  // Byte strobe handling
  // RegDataWidth may be different from ApbDataWidth
  // We need to map byte strobes from APB data width to register data width
  // Assuming RegDataWidth <= ApbDataWidth, and the register data is aligned to the lower bytes

  // For each register, apply byte strobes
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i])
          reg_r[i] <= reg_init_i[i];
        else
          reg_r[i] <= '0;
      end
    end else begin
      if (write_en) begin
        // Only update the selected register
        if (!ReadOnly[reg_idx]) begin
          // Apply byte strobes
          // The register data width is RegDataWidth bits
          // The APB data width is ApbDataWidth bits
          // We assume the register data is in the lower RegDataWidth bits of the APB data
          // Byte strobes are for ApbDataWidth/8 bytes
          // We need to mask the write data with the strobes and merge with existing data
          
          // Create a masked write data
          reg_data_t masked_wdata;
          reg_data_t existing_data = reg_r[reg_idx];
          
          // For each byte in the register data width
          for (int b = 0; b < RegDataWidth/8; b++) begin
            // Check if this byte is within the APB data width
            if (b < ApbDataWidth/8) begin
              // Check if the byte strobe is set
              if (pstrb[b]) begin
                masked_wdata[b*8 +: 8] = pwdata[b*8 +: 8];
              end else begin
                masked_wdata[b*8 +: 8] = existing_data[b*8 +: 8];
              end
            end else begin
              // Byte is beyond APB data width, retain existing
              masked_wdata[b*8 +: 8] = existing_data[b*8 +: 8];
            end
          end
          
          // Handle remaining bits if RegDataWidth is not a multiple of 8
          if (RegDataWidth % 8 != 0) begin
            int unsigned last_byte = RegDataWidth/8;
            int unsigned rem_bits = RegDataWidth % 8;
            // The last partial byte
            if (last_byte < ApbDataWidth/8) begin
              if (pstrb[last_byte]) begin
                // Take only the valid bits from pwdata
                for (int bit = 0; bit < rem_bits; bit++) begin
                  masked_wdata[last_byte*8 + bit] = pwdata[last_byte*8 + bit];
                end
                // Retain upper bits of the last byte
                for (int bit = rem_bits; bit < 8; bit++) begin
                  masked_wdata[last_byte*8 + bit] = existing_data[last_byte*8 + bit];
                end
              end else begin
                masked_wdata[last_byte*8 +: 8] = existing_data[last_byte*8 +: 8];
              end
            end else begin
              masked_wdata[last_byte*8 +: 8] = existing_data[last_byte*8 +: 8];
            end
          end
          
          reg_r[reg_idx] <= masked_wdata;
        end
      end
    end
  end

  // Output registers
  always @(*) begin
    for (int i = 0; i < NoApbRegs; i++) begin
      if (ReadOnly[i])
        reg_q_o[i] = reg_init_i[i];
      else
        reg_q_o[i] = reg_r[i];
    end
  end

endmodule
