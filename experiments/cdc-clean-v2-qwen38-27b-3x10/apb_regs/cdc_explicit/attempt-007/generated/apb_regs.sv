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

  // Extract APB signals from req_i
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
  assign resp_o.prdata  = 8'h0; // Not used for write-only or read-only via reg_q_o

  // Address decoding
  // Each register is spaced AddrOffset bytes apart
  // The offset within the bank is paddr - base_addr_i
  // Register index = (paddr - base_addr_i) / AddrOffset
  // We need to check if the address falls within the valid range for a register

  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;

  // Number of address bits needed to index registers
  // log2(NoApbRegs) bits for register index, plus log2(AddrOffset) bits for byte offset within register
  // But we just need to check if the address is within the bank and compute the register index

  // Valid address range: 0 to (NoApbRegs * AddrOffset - 1)
  wire [ApbAddrWidth-1:0] max_addr = NoApbRegs * AddrOffset - 1;
  wire addr_in_range = (addr_offset <= max_addr);

  // Register index: upper bits of addr_offset
  // If AddrOffset is a power of 2, we can shift right
  // For general case, we divide by AddrOffset
  // Since AddrOffset is typically a power of 2 (4, 8, etc.), let's use division
  wire [ApbAddrWidth-1:0] reg_index = addr_offset / AddrOffset;

  // Check if reg_index is within bounds
  wire reg_index_valid = (reg_index < NoApbRegs);

  // Write enable for each register
  wire [NoApbRegs-1:0] reg_we;
  genvar i;
  generate
    for (i = 0; i < NoApbRegs; i = i + 1) begin : gen_we
      assign reg_we[i] = psel & penable & pwrite & addr_in_range & reg_index_valid & (reg_index == i) & ~ReadOnly[i];
    end
  endgenerate

  // Register storage
  reg_data_t [NoApbRegs-1:0] reg_r;

  // Byte strobe handling
  // For each register, we need to update only the strobed bytes
  // RegDataWidth may be different from ApbDataWidth
  // We assume RegDataWidth <= ApbDataWidth or they are the same
  // Byte strobes correspond to bytes in the APB data bus

  // For each register, compute the new value based on byte strobes
  // We'll use a combinational block to compute the next value for each register

  // Since RegDataWidth and ApbDataWidth may differ, we need to handle the mapping
  // Typically, the register data is aligned to the APB data bus
  // Let's assume the register data occupies the lower RegDataWidth bits of the APB data bus

  // For each register i, the next value is:
  // If reg_we[i] is high, update the strobed bytes from pwdata
  // Otherwise, keep the current value

  // We'll generate the next value for each register
  reg_data_t [NoApbRegs-1:0] reg_next;

  generate
    for (i = 0; i < NoApbRegs; i = i + 1) begin : gen_next
      // Start with current value
      reg_data_t next_val;
      assign next_val = reg_r[i];

      // If write is enabled, update strobed bytes
      // We need to mask the bytes that are strobed
      // The byte strobes pstrb correspond to bytes in pwdata
      // We need to map these to the register data width

      // For simplicity, assume RegDataWidth <= ApbDataWidth
      // The register data is in the lower RegDataWidth bits of pwdata
      // Byte j of the register corresponds to byte j of pwdata (if j < RegDataWidth/8)

      // Create a mask for the strobed bytes in the register data
      // For each byte position in the register, check if the corresponding APB byte strobe is set

      // We'll build the next value byte by byte
      // Number of bytes in register
      localparam int unsigned RegBytes = (RegDataWidth + 7) / 8;
      localparam int unsigned ApbBytes = (ApbDataWidth + 7) / 8;

      // For each byte in the register
      genvar b;
      for (b = 0; b < RegBytes; b = b + 1) begin : gen_byte
        // The byte in the register at position b
        // Corresponds to byte b in pwdata (assuming alignment)
        // The strobe for this byte is pstrb[b] (if b < ApbBytes)
        wire strobe_active = (b < ApbBytes) ? pstrb[b] : 1'b0;

        // If write is enabled and strobe is active, use the new byte
        // Otherwise, keep the old byte
        // Extract byte from current register value
        wire [7:0] old_byte = reg_r[i][b*8 +: 8];
        wire [7:0] new_byte = pwdata[b*8 +: 8];

        // Select based on write enable and strobe
        wire [7:0] sel_byte = (reg_we[i] & strobe_active) ? new_byte : old_byte;

        // Assign to next_val
        assign next_val[b*8 +: 8] = sel_byte;
      end

      assign reg_next[i] = next_val;
    end
  endgenerate

  // Register update
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int unsigned j = 0; j < NoApbRegs; j = j + 1) begin
        if (ReadOnly[j])
          reg_r[j] <= reg_init_i[j];
        else
          reg_r[j] <= '0;
      end
    end else begin
      for (int unsigned j = 0; j < NoApbRegs; j = j + 1) begin
        if (ReadOnly[j])
          reg_r[j] <= reg_init_i[j];
        else
          reg_r[j] <= reg_next[j];
      end
    end
  end

  // Output
  generate
    for (i = 0; i < NoApbRegs; i = i + 1) begin : gen_out
      if (ReadOnly[i])
        assign reg_q_o[i] = reg_init_i[i];
      else
        assign reg_q_o[i] = reg_r[i];
    end
  endgenerate

endmodule
