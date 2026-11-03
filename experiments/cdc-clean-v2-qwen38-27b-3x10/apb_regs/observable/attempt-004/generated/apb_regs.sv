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
  wire [ApbDataWidth-1:0] pwdata = req_i.pwdata;
  wire [ApbDataWidth/8-1:0] pstrb = req_i.pstrb;
  wire [ApbAddrWidth-1:0] paddr = req_i.paddr;

  // APB response
  assign resp_o.pready = 1'b1;
  assign resp_o.pslverr = 1'b0;
  assign resp_o.prdata = 0;

  // Register file
  reg_data_t [NoApbRegs-1:0] reg_q;

  // Address decoding
  // Each register occupies AddrOffset bytes starting at base_addr_i + i*AddrOffset
  // The APB address is relative to base_addr_i
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;

  // Determine which register is being accessed
  // addr_offset / AddrOffset gives the register index
  // We need to handle the case where AddrOffset might not be a power of 2, but typically it is.
  // For simplicity, assume AddrOffset is a power of 2 for division.
  // Actually, let's use a more general approach: check if addr_offset falls within [i*AddrOffset, (i+1)*AddrOffset - 1]

  // For each register, check if the address maps to it
  // The byte offset within the register is addr_offset % AddrOffset
  // The register index is addr_offset / AddrOffset

  // Let's compute the register index and byte offset
  // Since we're dealing with byte addresses, and each register is AddrOffset bytes wide
  // reg_idx = addr_offset / AddrOffset
  // byte_off = addr_offset % AddrOffset

  // We'll use a loop to check which register is selected
  logic [NoApbRegs-1:0] reg_sel;
  logic [ApbAddrWidth-1:0] byte_off;

  // Compute byte offset within the register bank
  // This is the lower bits of addr_offset
  // If AddrOffset is a power of 2, byte_off = addr_offset & (AddrOffset - 1)
  // For generality, we'll use modulo
  assign byte_off = addr_offset % AddrOffset;

  // Determine register index
  // reg_idx = addr_offset / AddrOffset
  // We need to check if reg_idx < NoApbRegs

  // For each register i, it is selected if:
  // i * AddrOffset <= addr_offset < (i+1) * AddrOffset
  // i.e., addr_offset >= i*AddrOffset && addr_offset < (i+1)*AddrOffset

  genvar gi;
  generate
    for (gi = 0; gi < NoApbRegs; gi = gi + 1) begin : gen_sel
      wire [ApbAddrWidth-1:0] reg_start = gi * AddrOffset;
      wire [ApbAddrWidth-1:0] reg_end   = reg_start + AddrOffset;
      assign reg_sel[gi] = (addr_offset >= reg_start) && (addr_offset < reg_end);
    end
  endgenerate

  // Write enable: APB write phase (psel & penable & pwrite)
  wire apb_write = psel & penable & pwrite;

  // For each register, handle read/write
  generate
    for (gi = 0; gi < NoApbRegs; gi = gi + 1) begin : gen_reg
      wire is_ro = ReadOnly[gi];
      wire sel   = reg_sel[gi];

      // Byte strobes for this register
      // The byte offset within the register is byte_off
      // pstrb has ApbDataWidth/8 bits
      // We need to map pstrb to the register's byte lanes
      // The register is RegDataWidth bits wide
      // The APB data is ApbDataWidth bits wide
      // We assume ApbDataWidth >= RegDataWidth or they are equal
      // The byte strobes correspond to the bytes of pwdata
      // For a register at byte offset byte_off within its AddrOffset-byte slot,
      // the relevant bytes of pwdata are those at positions byte_off + j for j = 0..RegDataWidth/8-1
      // But actually, the APB write data pwdata is aligned to the APB data bus
      // The register data is RegDataWidth bits
      // We need to extract the relevant bytes from pwdata based on byte_off

      // Let's assume that the register data is aligned such that:
      // reg_data[8*j +: 8] corresponds to pwdata[8*(byte_off + j) +: 8] for j = 0..RegDataWidth/8-1
      // This is a common assumption for APB register files

      // For each byte of the register, determine if it should be updated
      // Byte j of the register is updated if:
      // 1. The register is selected
      // 2. It's a write
      // 3. The register is not read-only
      // 4. The byte strobe for the corresponding APB data byte is set

      // The APB data byte index for register byte j is: byte_off + j
      // The pstrb bit for that byte is pstrb[byte_off + j]

      // We need to handle the case where byte_off + j >= ApbDataWidth/8
      // In that case, the byte is not in the APB data bus, so it should not be updated

      // Let's build the write data for this register
      reg_data_t wdata;
      for (genvar gj = 0; gj < RegDataWidth/8; gj = gj + 1) begin : gen_byte
        wire [ApbAddrWidth-1:0] apb_byte_idx = byte_off + gj;
        wire in_range = (apb_byte_idx < ApbDataWidth/8);
        wire strobe = in_range ? pstrb[apb_byte_idx] : 1'b0;
        assign wdata[8*gj +: 8] = in_range ? pwdata[8*apb_byte_idx +: 8] : reg_q[gi][8*gj +: 8];
      end

      // Write enable for this register
      wire we = apb_write & sel & ~is_ro;

      // Update register
      always @(posedge pclk_i or negedge preset_ni) begin
        if (!preset_ni) begin
          if (is_ro)
            reg_q[gi] <= reg_init_i[gi];
          else
            reg_q[gi] <= '0;
        end else if (we) begin
          // Apply byte strobes
          for (genvar gj = 0; gj < RegDataWidth/8; gj = gj + 1) begin
            wire [ApbAddrWidth-1:0] apb_byte_idx = byte_off + gj;
            wire in_range = (apb_byte_idx < ApbDataWidth/8);
            wire strobe = in_range ? pstrb[apb_byte_idx] : 1'b0;
            if (strobe)
              reg_q[gi][8*gj +: 8] <= pwdata[8*apb_byte_idx +: 8];
          end
        end
      end
    end
  endgenerate

  // Output registers
  assign reg_q_o = reg_q;

endmodule
