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
  wire psel    = req_i.psel;
  wire penable = req_i.penable;
  wire pwrite  = req_i.pwrite;
  wire [ApbAddrWidth-1:0] paddr = req_i.paddr;
  wire [ApbDataWidth-1:0] pwdata = req_i.pwdata;
  wire [ApbDataWidth/8-1:0] pstrb = req_i.pstrb;

  // Compute address offset from base
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;

  // Determine register index from address offset
  // Each register is spaced AddrOffset bytes apart
  // We need to extract the register index bits
  // The number of bits needed to index NoApbRegs registers
  localparam int unsigned RegIndexWidth = $clog2(NoApbRegs == 0 ? 1 : NoApbRegs);
  
  // The address offset in bytes, we need to divide by AddrOffset to get register index
  // Since AddrOffset is a power of 2 (typically), we can shift
  // But to be general, we'll use division or bit extraction
  // Let's compute the register index by shifting out the lower bits that correspond to intra-register offset
  // The intra-register offset bits = $clog2(AddrOffset) if AddrOffset is power of 2
  // For generality, we'll use a simple approach: extract bits from addr_offset
  
  // Number of bits for intra-register byte offset
  localparam int unsigned IntraRegOffsetBits = (AddrOffset > 1) ? $clog2(AddrOffset) : 0;
  
  // Register index is the upper bits of addr_offset after removing intra-register offset bits
  wire [ApbAddrWidth-1:0] reg_index_full = addr_offset >> IntraRegOffsetBits;
  
  // Mask to valid register index range
  wire [RegIndexWidth-1:0] reg_index = reg_index_full[RegIndexWidth-1:0];
  
  // Check if address is within valid register range
  wire addr_valid = (reg_index_full < NoApbRegs);

  // Determine if we're in the access phase (write commit)
  wire access_phase = psel & penable;

  // Generate byte strobes for the register data width
  // pstrb has ApbDataWidth/8 bits, we need to map to RegDataWidth/8 bytes
  localparam int unsigned ApbBytes = ApbDataWidth / 8;
  localparam int unsigned RegBytes = RegDataWidth / 8;

  // For each register, determine if it's being written
  wire [NoApbRegs-1:0] write_en;
  genvar gi;
  generate
    for (gi = 0; gi < NoApbRegs; gi = gi + 1) begin : gen_write_en
      assign write_en[gi] = access_phase & pwrite & addr_valid & (reg_index == gi[RegIndexWidth-1:0]) & ~ReadOnly[gi];
    end
  endgenerate

  // Register storage
  reg_data_t [NoApbRegs-1:0] reg_r;

  // Write data preparation
  // For each register, prepare the new value based on byte strobes
  wire [RegDataWidth-1:0] write_data [NoApbRegs];
  genvar gj;
  generate
    for (gj = 0; gj < NoApbRegs; gj = gj + 1) begin : gen_write_data
      // Map pstrb bytes to register bytes
      // The byte position in the register corresponds to the byte position in the APB data
      // Assuming the register is aligned within the APB data bus
      // We need to extract the relevant bytes from pwdata based on pstrb
      // For simplicity, assume RegDataWidth <= ApbDataWidth and the register occupies the lower bytes
      // More generally, we need to handle the byte mapping
      
      // Create a masked write data
      wire [RegDataWidth-1:0] masked_data;
      genvar gb;
      generate
        for (gb = 0; gb < RegBytes; gb = gb + 1) begin : gen_byte
          // Check if this byte is strobed
          // The byte index in APB data corresponds to the byte index in the register
          // Assuming the register starts at byte 0 of the APB data
          wire byte_strobed = (gb < ApbBytes) ? pstrb[gb] : 1'b0;
          assign masked_data[gb*8 +: 8] = byte_strobed ? pwdata[gb*8 +: 8] : reg_r[gj][gb*8 +: 8];
        end
      endgenerate
      assign write_data[gj] = masked_data;
    end
  endgenerate

  // Sequential logic for register updates
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        if (ReadOnly[i])
          reg_r[i] <= reg_init_i[i];
        else
          reg_r[i] <= '0;
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        if (write_en[i])
          reg_r[i] <= write_data[i];
      end
    end
  end

  // Drive outputs
  assign reg_q_o = reg_r;

  // Response: default to OKAY
  // For simplicity, always return OKAY
  assign resp_o.pready = 1'b1;
  assign resp_o.pslverr = 1'b0;

endmodule
