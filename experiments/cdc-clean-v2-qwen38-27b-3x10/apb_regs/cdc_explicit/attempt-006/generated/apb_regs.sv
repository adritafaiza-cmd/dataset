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
  assign resp_o.prdata  = 8'h0; // Not used in this simple implementation

  // Address decoding
  // Calculate offset from base address
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;

  // Determine which register is being accessed
  // Each register is spaced AddrOffset bytes apart
  // So register index = addr_offset / AddrOffset
  // We need to handle the case where AddrOffset might not be a power of 2
  // For simplicity, assume AddrOffset is a power of 2 (common in APB)
  
  // Calculate the register index
  // If AddrOffset is a power of 2, we can use bit shifting
  // Let's compute the log2 of AddrOffset
  localparam int unsigned ADDR_OFFSET_LOG2 = (AddrOffset == 1) ? 0 :
                                             (AddrOffset == 2) ? 1 :
                                             (AddrOffset == 4) ? 2 :
                                             (AddrOffset == 8) ? 3 :
                                             (AddrOffset == 16) ? 4 :
                                             (AddrOffset == 32) ? 5 :
                                             (AddrOffset == 64) ? 6 :
                                             (AddrOffset == 128) ? 7 :
                                             (AddrOffset == 256) ? 8 :
                                             (AddrOffset == 512) ? 9 :
                                             (AddrOffset == 1024) ? 10 :
                                             (AddrOffset == 2048) ? 11 :
                                             (AddrOffset == 4096) ? 12 :
                                             (AddrOffset == 8192) ? 13 :
                                             (AddrOffset == 16384) ? 14 :
                                             (AddrOffset == 32768) ? 15 :
                                             (AddrOffset == 65536) ? 16 :
                                             (AddrOffset == 131072) ? 17 :
                                             (AddrOffset == 262144) ? 18 :
                                             (AddrOffset == 524288) ? 19 :
                                             (AddrOffset == 1048576) ? 20 :
                                             (AddrOffset == 2097152) ? 21 :
                                             (AddrOffset == 4194304) ? 22 :
                                             (AddrOffset == 8388608) ? 23 :
                                             (AddrOffset == 16777216) ? 24 :
                                             (AddrOffset == 33554432) ? 25 :
                                             (AddrOffset == 67108864) ? 26 :
                                             (AddrOffset == 134217728) ? 27 :
                                             (AddrOffset == 268435456) ? 28 :
                                             (AddrOffset == 536870912) ? 29 :
                                             (AddrOffset == 1073741824) ? 30 :
                                             (AddrOffset == 2147483648) ? 31 : 0;

  // Register index from address offset
  wire [ApbAddrWidth-1:0] reg_index_raw = addr_offset >> ADDR_OFFSET_LOG2;

  // Check if the address is within the valid range
  wire addr_in_range = (reg_index_raw < NoApbRegs);

  // Check if the lower bits (within the register) are zero (aligned access)
  wire [ADDR_OFFSET_LOG2-1:0] addr_low_bits = addr_offset[ADDR_OFFSET_LOG2-1:0];
  wire addr_aligned = (addr_low_bits == {ADDR_OFFSET_LOG2{1'b0}});

  // Valid write condition: in access phase, write, address in range and aligned
  wire write_valid = psel & penable & pwrite & addr_in_range & addr_aligned;

  // Register file
  reg_data_t [NoApbRegs-1:0] regs;

  // Byte strobe for each register
  // The data width of the register is RegDataWidth
  // The APB data width is ApbDataWidth
  // We need to map the APB byte strobes to the register byte strobes

  // Number of bytes in the register
  localparam int unsigned REG_BYTES = (RegDataWidth + 7) / 8;
  // Number of bytes in APB data
  localparam int unsigned APB_BYTES = (ApbDataWidth + 7) / 8;

  // For each register, generate the write enable and data
  genvar i;
  generate
    for (i = 0; i < NoApbRegs; i++) begin : gen_reg
      // Write enable for this register
      wire we = write_valid & (reg_index_raw == i[ApbAddrWidth-1:0]);

      // Byte strobes for this register
      // The APB data is ApbDataWidth bits wide
      // The register is RegDataWidth bits wide
      // We assume that the APB data width is >= RegDataWidth or we need to handle partial writes
      
      // For simplicity, assume that the register data is aligned to the APB data
      // and that we can directly use the APB byte strobes for the lower bytes of the register
      
      // Generate the new register value
      reg_data_t new_val;
      
      if (ReadOnly[i]) begin : gen_ro
        // Read-only register: always expose reg_init_i
        assign new_val = reg_init_i[i];
      end else begin : gen_rw
        // Writable register: update based on byte strobes
        // We need to merge the new data with the old data based on byte strobes
        
        // Create a mask for the bytes that are being written
        // The APB data is ApbDataWidth bits, the register is RegDataWidth bits
        // We'll assume that the register data is in the lower RegDataWidth bits of the APB data
        
        // For each byte in the register, check if the corresponding APB byte strobe is set
        // and if the byte is within the APB data width
        
        // Simplified approach: assume RegDataWidth <= ApbDataWidth and that the register
        // is aligned to the lower bits of the APB data
        
        // Generate the merged value
        always @(*) begin
          new_val = regs[i];
          for (int b = 0; b < REG_BYTES; b++) begin
            if (b < APB_BYTES && pstrb[b]) begin
              // Copy the byte from pwdata
              new_val[b*8 +: 8] = pwdata[b*8 +: 8];
            end
          end
        end
      end
    end
  endgenerate

  // Sequential logic for register updates
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) begin
          regs[i] <= reg_init_i[i];
        end else begin
          regs[i] <= '0;
        end
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (!ReadOnly[i]) begin
          wire we_i = write_valid & (reg_index_raw == i[ApbAddrWidth-1:0]);
          if (we_i) begin
            // Merge with byte strobes
            reg_data_t new_val = regs[i];
            for (int b = 0; b < REG_BYTES; b++) begin
              if (b < APB_BYTES && pstrb[b]) begin
                new_val[b*8 +: 8] = pwdata[b*8 +: 8];
              end
            end
            regs[i] <= new_val;
          end
        end
      end
    end
  end

  // Output: read-only registers expose reg_init_i, writable registers expose regs
  always @(*) begin
    for (int i = 0; i < NoApbRegs; i++) begin
      if (ReadOnly[i]) begin
        reg_q_o[i] = reg_init_i[i];
      end else begin
        reg_q_o[i] = regs[i];
      end
    end
  end

endmodule
