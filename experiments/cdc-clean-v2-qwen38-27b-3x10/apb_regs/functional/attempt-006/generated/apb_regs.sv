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

  // Determine register index
  wire [ApbAddrWidth-1:0] reg_index_raw = addr_offset / AddrOffset;
  wire [ApbAddrWidth-1:0] reg_index = reg_index_raw;

  // Check if address is within valid range
  wire addr_valid = (reg_index < NoApbRegs);

  // Determine if this is a write access in the access phase
  wire write_access = psel & penable & pwrite & addr_valid;

  // Determine if this is a read access in the access phase
  wire read_access = psel & penable & ~pwrite & addr_valid;

  // Response
  assign resp_o.pready = 1'b1;
  assign resp_o.pslverr = ~addr_valid;

  // Register file
  reg_data_t [NoApbRegs-1:0] regs;

  // Byte strobe mask for the register being written
  // We need to map the APB data width byte strobes to the register data width
  // The register is RegDataWidth bits wide, APB data is ApbDataWidth bits wide
  // We assume RegDataWidth <= ApbDataWidth or they are equal
  // For simplicity, we handle the case where RegDataWidth may be less than ApbDataWidth

  // Generate byte strobes for the register
  // The number of bytes in the register
  localparam int unsigned RegBytes = (RegDataWidth + 7) / 8;
  localparam int unsigned ApbBytes = (ApbDataWidth + 7) / 8;

  // For each byte position in the register, determine if it should be updated
  // The APB data is aligned such that byte 0 of APB data corresponds to the LSB of the register
  // We need to mask the write data to only the register width

  // Create a mask for the register width within the APB data width
  // If RegDataWidth < ApbDataWidth, we only care about the lower RegDataWidth bits
  // The byte strobes from APB correspond to bytes of the APB data bus

  // For each byte i in the register (0 to RegBytes-1):
  //   The corresponding APB byte strobe is pstrb[i] if i < ApbBytes
  //   The corresponding APB data bytes are pwdata[i*8 +: 8]

  // Write logic
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i])
          regs[i] <= reg_init_i[i];
        else
          regs[i] <= '0;
      end
    end else begin
      if (write_access) begin
        int unsigned idx = reg_index;
        if (!ReadOnly[idx]) begin
          // Apply byte strobes
          for (int b = 0; b < RegBytes; b++) begin
            if (b < ApbBytes && pstrb[b]) begin
              regs[idx][b*8 +: 8] <= pwdata[b*8 +: 8];
            end
          end
        end
      end
    end
  end

  // Output: read-only registers expose reg_init_i, writable registers expose current value
  always @(*) begin
    for (int i = 0; i < NoApbRegs; i++) begin
      if (ReadOnly[i])
        reg_q_o[i] = reg_init_i[i];
      else
        reg_q_o[i] = regs[i];
    end
  end

endmodule
