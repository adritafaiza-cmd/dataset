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

  // Compute address offset from base
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;

  // Determine register index from address offset
  // Each register is spaced AddrOffset bytes apart
  // Number of bits needed to index registers
  localparam int unsigned RegIndexWidth = $clog2(NoApbRegs > 0 ? NoApbRegs : 1);
  localparam int unsigned AddrOffsetLog2 = $clog2(AddrOffset > 1 ? AddrOffset : 1);

  // Register index: shift down by log2(AddrOffset) to get register number
  wire [ApbAddrWidth-1:0] reg_index_full = addr_offset >> AddrOffsetLog2;
  wire [RegIndexWidth-1:0] reg_index = reg_index_full[RegIndexWidth-1:0];

  // Check if address is within valid range
  wire addr_valid = (reg_index < NoApbRegs);

  // Check if address is aligned to register boundary (lower bits of offset are zero)
  wire [AddrOffsetLog2-1:0] addr_low_bits = addr_offset[AddrOffsetLog2-1:0];
  wire addr_aligned = (addr_low_bits == {AddrOffsetLog2{1'b0}});

  // APB access phase: psel and penable both high
  wire apb_access = psel & penable;

  // Write enable for each register
  wire [NoApbRegs-1:0] write_en;
  for (genvar i = 0; i < NoApbRegs; i++) begin : gen_write_en
    assign write_en[i] = apb_access & pwrite & addr_valid & addr_aligned & (reg_index == i[RegIndexWidth-1:0]) & ~ReadOnly[i];
  end

  // Read enable for each register
  wire [NoApbRegs-1:0] read_en;
  for (genvar i = 0; i < NoApbRegs; i++) begin : gen_read_en
    assign read_en[i] = apb_access & ~pwrite & addr_valid & addr_aligned & (reg_index == i[RegIndexWidth-1:0]);
  end

  // Register storage
  reg_data_t [NoApbRegs-1:0] reg_storage;

  // Byte strobe handling: only update strobed bytes
  // For each register, apply byte strobes from pwdata
  wire [ApbDataWidth-1:0] strobed_data;
  for (genvar b = 0; b < ApbDataWidth/8; b++) begin : gen_strobe
    assign strobed_data[b*8 +: 8] = pstrb[b] ? pwdata[b*8 +: 8] : reg_storage[reg_index][b*8 +: 8];
  end

  // Register update logic
  always @(posedge pclk_i or negedge preset_ni) begin
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
        if (write_en[i]) begin
          // Apply byte strobes: only update strobed bytes
          for (int b = 0; b < RegDataWidth/8; b++) begin
            if (b < ApbDataWidth/8) begin
              if (pstrb[b]) begin
                reg_storage[i][b*8 +: 8] <= pwdata[b*8 +: 8];
              end
            end
          end
        end
      end
    end
  end

  // Drive output: read-only registers expose reg_init_i, writable expose stored value
  for (genvar i = 0; i < NoApbRegs; i++) begin : gen_output
    assign reg_q_o[i] = ReadOnly[i] ? reg_init_i[i] : reg_storage[i];
  end

  // APB response: drive pready high (ready immediately)
  assign resp_o.pready = 1'b1;
  assign resp_o.pslverr = 1'b0;

endmodule
