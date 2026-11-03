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
  assign resp_o.prdata  = 8'h0; // Not used for write-only or read-only via reg_q_o

  // Address decoding
  // Each register is spaced AddrOffset bytes apart
  // The address offset from base determines which register
  // We need to compute: (paddr - base_addr_i) / AddrOffset
  // But we must handle the case where paddr < base_addr_i (invalid)

  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;
  wire [ApbAddrWidth-1:0] reg_index_raw = addr_offset / AddrOffset;

  // Valid register index check
  wire reg_index_valid = (reg_index_raw < NoApbRegs) && (paddr >= base_addr_i);

  // Byte strobe mapping
  // RegDataWidth may be less than ApbDataWidth
  // We need to map the byte strobes to the register's byte lanes
  // The register occupies RegDataWidth bits, so it has RegDataWidth/8 bytes
  // The APB data bus has ApbDataWidth/8 bytes
  // We assume the register is aligned to its byte boundary within the data bus

  localparam int unsigned RegBytes = RegDataWidth / 8;
  localparam int unsigned ApbBytes = ApbDataWidth / 8;

  // For each register, determine which bytes of the APB data bus map to it
  // The register's byte offset within the APB data word is determined by
  // the lower bits of the address that fall within the AddrOffset range
  // Specifically, the byte offset within the register slot is:
  //   byte_offset = (paddr - base_addr_i) % AddrOffset
  // But since each register is AddrOffset bytes apart, and the register is
  // RegDataWidth bits wide, we need to figure out which bytes of pwdata
  // correspond to the register.

  // Actually, in a typical APB register file, the register is aligned such that
  // the least significant byte of the register corresponds to the least significant
  // byte of the data bus when the address offset within the slot is 0.
  // The byte offset within the slot is: (paddr - base_addr_i) % AddrOffset
  // This tells us which byte of the APB data bus to use for the LSB of the register.

  wire [ApbAddrWidth-1:0] byte_offset_in_slot = addr_offset % AddrOffset;

  // For simplicity and correctness, we'll handle the byte strobe mapping as follows:
  // The register's byte i (0-indexed from LSB) maps to APB data byte (byte_offset_in_slot + i)
  // if that byte index is within ApbBytes.

  // Generate the write enable and data for each register
  reg_data_t [NoApbRegs-1:0] reg_next;
  logic [NoApbRegs-1:0] reg_we;

  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_we[i] = 1'b0;
      reg_next[i] = reg_q_o[i];
    end

    if (psel && penable && pwrite && reg_index_valid) begin
      int unsigned idx = reg_index_raw;
      if (!ReadOnly[idx]) begin
        reg_we[idx] = 1'b1;
        // Apply byte strobes
        for (int b = 0; b < RegBytes; b++) begin
          int unsigned apb_byte_idx = byte_offset_in_slot + b;
          if (apb_byte_idx < ApbBytes) begin
            if (pstrb[apb_byte_idx]) begin
              reg_next[idx][b*8 +: 8] = pwdata[apb_byte_idx*8 +: 8];
            end
          end
        end
      end
    end
  end

  // Register update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) begin
          reg_q_o[i] <= reg_init_i[i];
        end else begin
          reg_q_o[i] <= '0;
        end
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (reg_we[i]) begin
          reg_q_o[i] <= reg_next[i];
        end
      end
    end
  end

endmodule
