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
  assign resp_o.prdata  = 8'h0; // Not used for writes; reads handled via reg_q_o

  // Address decoding
  // Each register occupies AddrOffset bytes starting at base_addr_i + i*AddrOffset
  // We need to decode which register is being accessed
  // The address offset from base is paddr - base_addr_i
  // Register index = (paddr - base_addr_i) / AddrOffset
  // Valid if (paddr - base_addr_i) % AddrOffset == 0 and index < NoApbRegs

  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;
  
  // Compute register index
  // Since AddrOffset is a power of 2 (typically 4), we can use bit shifting
  // But to be general, we'll use division. However, for efficiency, assume AddrOffset is power of 2.
  // Let's compute the index by right-shifting if AddrOffset is power of 2.
  // For generality, we'll use a simple approach: check if the lower bits (log2(AddrOffset)) are zero.
  
  // Number of bits for offset within a register slot
  localparam int unsigned OffsetBits = (AddrOffset == 1) ? 0 : $clog2(AddrOffset);
  
  // Check if address is aligned to AddrOffset boundary
  wire addr_aligned = (addr_offset[OffsetBits-1:0] == {OffsetBits{1'b0}});
  
  // Register index
  wire [ApbAddrWidth-1:0] reg_index_full = addr_offset >> OffsetBits;
  
  // Check if index is within range
  wire index_valid = (reg_index_full < NoApbRegs);
  
  // Combined valid
  wire addr_valid = addr_aligned & index_valid;
  
  // Write enable for each register
  wire [NoApbRegs-1:0] write_en;
  genvar i;
  generate
    for (i = 0; i < NoApbRegs; i = i + 1) begin : gen_write_en
      assign write_en[i] = psel & penable & pwrite & addr_valid & (reg_index_full == i);
    end
  endgenerate

  // Register storage
  reg_data_t [NoApbRegs-1:0] reg_storage;
  
  // Byte strobe handling
  // For each register, apply byte strobes to update only selected bytes
  // RegDataWidth may be different from ApbDataWidth
  // We need to map the APB data width to the register data width
  
  // Number of bytes in register
  localparam int unsigned RegBytes = (RegDataWidth + 7) / 8;
  localparam int unsigned ApbBytes = (ApbDataWidth + 7) / 8;
  
  // For each register, compute the new value based on byte strobes
  // We'll create a combinational logic to compute the updated value
  
  // Helper function to apply byte strobes
  // The APB data is ApbDataWidth bits wide, register is RegDataWidth bits wide
  // We assume the lower bits of pwdata correspond to the lower bits of the register
  
  // For each byte position in the register, check if the corresponding byte in pwdata should be updated
  
  // Generate the updated register values
  reg_data_t [NoApbRegs-1:0] reg_next;
  
  generate
    for (i = 0; i < NoApbRegs; i = i + 1) begin : gen_reg_update
      if (ReadOnly[i]) begin : gen_ro
        // Read-only: always expose reg_init_i
        assign reg_next[i] = reg_init_i[i];
      end else begin : gen_rw
        // Read-write: update based on byte strobes
        // Start with current value
        reg_data_t next_val;
        assign next_val = reg_storage[i];
        
        // Apply byte strobes
        // For each byte in the register, if the corresponding byte strobe is set,
        // update that byte from pwdata
        // We need to handle the case where ApbDataWidth != RegDataWidth
        // Assume that the APB data is aligned to the register's lower bits
        
        // Number of bytes to update is min(RegBytes, ApbBytes)
        localparam int unsigned NumBytes = (RegBytes < ApbBytes) ? RegBytes : ApbBytes;
        
        // For each byte position
        genvar b;
        for (b = 0; b < NumBytes; b = b + 1) begin : gen_byte
          // Byte strobe for this byte
          wire strobe = pstrb[b];
          // Byte from pwdata
          wire [7:0] data_byte = pwdata[b*8 +: 8];
          // Current byte in register
          wire [7:0] cur_byte = reg_storage[i][b*8 +: 8];
          // Updated byte
          wire [7:0] new_byte = strobe ? data_byte : cur_byte;
          // Assign to next_val
          assign next_val[b*8 +: 8] = new_byte;
        end
        
        // For bytes beyond ApbBytes, keep current value (already done by initialization)
        
        assign reg_next[i] = next_val;
      end
    end
  endgenerate

  // Sequential logic for register storage
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int unsigned j = 0; j < NoApbRegs; j = j + 1) begin
        if (ReadOnly[j]) begin
          reg_storage[j] <= reg_init_i[j];
        end else begin
          reg_storage[j] <= '0;
        end
      end
    end else begin
      for (int unsigned j = 0; j < NoApbRegs; j = j + 1) begin
        if (write_en[j]) begin
          reg_storage[j] <= reg_next[j];
        end
      end
    end
  end

  // Output: read-only registers expose reg_init_i, writable registers expose stored value
  generate
    for (i = 0; i < NoApbRegs; i = i + 1) begin : gen_output
      if (ReadOnly[i]) begin : gen_ro_out
        assign reg_q_o[i] = reg_init_i[i];
      end else begin : gen_rw_out
        assign reg_q_o[i] = reg_storage[i];
      end
    end
  endgenerate

endmodule
