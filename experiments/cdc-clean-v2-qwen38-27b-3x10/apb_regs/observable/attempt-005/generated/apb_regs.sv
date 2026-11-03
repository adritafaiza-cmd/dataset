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

  // APB response
  assign resp_o.pready = 1'b1;
  assign resp_o.pslverr = 1'b0;
  assign resp_o.prdata = 0;

  // Register file
  reg_data_t [NoApbRegs-1:0] regs;

  // Address decoding
  // Each register occupies AddrOffset bytes.
  // The offset within the register bank is (paddr - base_addr_i).
  // The register index is offset / AddrOffset.
  // The byte offset within the register is offset % AddrOffset.

  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;
  wire [ApbAddrWidth-1:0] reg_index_raw = addr_offset / AddrOffset;
  wire [ApbAddrWidth-1:0] byte_offset = addr_offset % AddrOffset;

  // Determine if the address is within the valid register range
  wire addr_valid = (reg_index_raw < NoApbRegs);

  // Write enable: APB write phase (psel & penable & pwrite) and valid address
  wire write_en = psel & penable & pwrite & addr_valid;

  // For each register, determine if it's being written
  // and apply byte strobes

  genvar i;
  generate
    for (i = 0; i < NoApbRegs; i = i + 1) begin : gen_reg
      wire reg_sel = (reg_index_raw == i) & addr_valid;
      wire ro = ReadOnly[i];

      // Byte strobe for this register
      // pstrb has ApbDataWidth/8 bits. We need to map byte_offset to pstrb bits.
      // The byte offset within the register is byte_offset (0 to AddrOffset-1).
      // The pstrb bits correspond to bytes of the APB data bus.
      // We need to extract the relevant strobe bits for this register's data width.

      // The register data width is RegDataWidth bits.
      // The number of bytes in the register is RegDataWidth/8.
      // The byte_offset tells us which byte within the register is being accessed.
      // But pstrb is for the entire APB data bus (ApbDataWidth bits).
      // We need to map the byte_offset to the correct pstrb bit.

      // The APB data bus is ApbDataWidth bits wide.
      // The register data is RegDataWidth bits wide.
      // Typically, RegDataWidth <= ApbDataWidth.
      // The byte_offset is the offset within the register (0 to AddrOffset-1).
      // The pstrb bit for byte b of the APB bus is pstrb[b].
      // The register's byte b corresponds to APB bus byte b (assuming the register is aligned).

      // For simplicity, we assume the register data is aligned to the APB data bus.
      // The byte_offset within the register maps to pstrb[byte_offset] if byte_offset < ApbDataWidth/8.

      // Let's define the number of bytes in the register
      localparam int unsigned RegBytes = RegDataWidth / 8;
      localparam int unsigned ApbBytes = ApbDataWidth / 8;

      // The byte offset within the register
      wire [ApbAddrWidth-1:0] byte_off = byte_offset;

      // For each byte in the register, check if it's being written
      // and if the corresponding pstrb bit is set.

      // We'll build the new value for the register
      reg_data_t new_val;
      reg_data_t old_val = regs[i];

      // Initialize new_val with old_val
      assign new_val = old_val;

      // For each byte in the register
      genvar b;
      generate
        for (b = 0; b < RegBytes; b = b + 1) begin : gen_byte
          // Check if this byte is being written
          wire byte_sel = (byte_off == b) & reg_sel & write_en;
          wire strobe = (b < ApbBytes) ? pstrb[b] : 1'b0;
          wire byte_write = byte_sel & strobe & ~ro;

          // Extract the byte from pwdata
          wire [7:0] pwdata_byte = pwdata[b*8 +: 8];
          wire [7:0] old_byte = old_val[b*8 +: 8];
          wire [7:0] new_byte = byte_write ? pwdata_byte : old_byte;

          assign new_val[b*8 +: 8] = new_byte;
        end
      endgenerate

      // Update the register
      always @(posedge pclk_i or negedge preset_ni) begin
        if (!preset_ni) begin
          if (ro)
            regs[i] <= reg_init_i[i];
          else
            regs[i] <= '0;
        end else if (write_en & reg_sel & ~ro) begin
          regs[i] <= new_val;
        end
      end

      // Output
      assign reg_q_o[i] = regs[i];
    end
  endgenerate

endmodule
