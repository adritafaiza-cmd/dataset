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
  assign resp_o.prdata = 8'h0; // Not used for writes, but must be driven
  assign resp_o.pslverr = 1'b0;

  // Address decoding
  // Compute offset from base address
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;

  // Determine register index
  // Each register is spaced AddrOffset bytes apart
  // We need to find which register the address falls into
  // reg_index = addr_offset / AddrOffset
  // But we also need to check if the address is within the valid range for that register

  // Number of bits needed to represent AddrOffset
  // We'll use a simple approach: for each register, check if the address matches

  // Generate register index from address
  // The address offset divided by AddrOffset gives the register index
  // We need to handle the case where AddrOffset might not be a power of 2

  // For simplicity and correctness, we'll decode by checking each register's address range
  // reg i is at base_addr_i + i * AddrOffset, and spans AddrOffset bytes

  // Compute the register index
  wire [ApbAddrWidth-1:0] reg_index_raw = addr_offset / AddrOffset;

  // Check if the address is within the valid range for the computed register
  // The address should be in [base_addr_i + reg_index * AddrOffset, base_addr_i + (reg_index + 1) * AddrOffset)
  wire [ApbAddrWidth-1:0] reg_base_addr = base_addr_i + reg_index_raw * AddrOffset;
  wire [ApbAddrWidth-1:0] reg_end_addr  = reg_base_addr + AddrOffset;

  // Check if address is within the register's range
  wire addr_in_range = (paddr >= reg_base_addr) && (paddr < reg_end_addr);

  // Check if register index is valid
  wire reg_index_valid = (reg_index_raw < NoApbRegs);

  // Combined valid address
  wire addr_valid = addr_in_range && reg_index_valid;

  // Write enable for each register
  wire [NoApbRegs-1:0] reg_we = '0;
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      if (psel && penable && pwrite && addr_valid && (reg_index_raw == i)) begin
        reg_we[i] = 1'b1;
      end else begin
        reg_we[i] = 1'b0;
      end
    end
  end

  // Register storage
  reg_data_t [NoApbRegs-1:0] reg_storage;

  // Byte strobe handling
  // For each register, apply byte strobes to the write data
  // The write data is ApbDataWidth bits wide, but the register is RegDataWidth bits wide
  // We need to mask the write data with the byte strobes

  // Generate the masked write data for each register
  reg_data_t [NoApbRegs-1:0] reg_wdata_masked;

  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_wdata_masked[i] = '0;
      if (reg_we[i]) begin
        // Apply byte strobes
        // The number of bytes in the register
        localparam int unsigned RegBytes = (RegDataWidth + 7) / 8;
        localparam int unsigned ApbBytes = (ApbDataWidth + 7) / 8;
        
        // For each byte in the register, check if the corresponding byte strobe is set
        // and if the byte is within the APB data width
        for (int b = 0; b < RegBytes; b++) begin
          if (b < ApbBytes) begin
            if (pstrb[b]) begin
              // Copy the byte from pwdata
              reg_wdata_masked[i][b*8 +: 8] = pwdata[b*8 +: 8];
            end else begin
              // Keep the old value
              reg_wdata_masked[i][b*8 +: 8] = reg_storage[i][b*8 +: 8];
            end
          end else begin
            // Byte is beyond APB data width, keep old value
            reg_wdata_masked[i][b*8 +: 8] = reg_storage[i][b*8 +: 8];
          end
        end
      end else begin
        reg_wdata_masked[i] = reg_storage[i];
      end
    end
  end

  // Register update logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) begin
          reg_storage[i] <= reg_init_i[i];
        end else begin
          reg_storage[i] <= '0;
        end
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) begin
          // Read-only registers always expose reg_init_i
          reg_storage[i] <= reg_init_i[i];
        end else if (reg_we[i]) begin
          reg_storage[i] <= reg_wdata_masked[i];
        end
      end
    end
  end

  // Output: read-only registers expose reg_init_i, writable registers expose stored value
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      if (ReadOnly[i]) begin
        reg_q_o[i] = reg_init_i[i];
      end else begin
        reg_q_o[i] = reg_storage[i];
      end
    end
  end

endmodule
