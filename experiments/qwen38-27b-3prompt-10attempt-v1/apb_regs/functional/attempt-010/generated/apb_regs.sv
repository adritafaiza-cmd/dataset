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

  // Extract APB fields from the request type
  // Assuming standard APB3/4 signal names within the struct
  wire [ApbAddrWidth-1:0] paddr  = req_i.paddr;
  wire                    penable = req_i.penable;
  wire                    pwrite  = req_i.pwrite;
  wire [ApbDataWidth-1:0] pwdata  = req_i.pwdata;
  wire [3:0]              pstrb   = req_i.pstrb;

  // Response fields
  resp_o.pready = 1'b1;
  resp_o.pslverr = 1'b0;
  resp_o.prdata  = '0;

  // Register file
  reg_data_t [NoApbRegs-1:0] regs;

  // Address decoding
  // Calculate offset from base address
  wire [ApbAddrWidth-1:0] addr_offset = paddr - base_addr_i;
  
  // Determine register index
  // AddrOffset is in bytes, so shift right by log2(AddrOffset)
  // Assuming AddrOffset is a power of 2
  localparam int unsigned ADDR_SHIFT = $clog2(AddrOffset);
  
  wire [ApbAddrWidth-1:ADDR_SHIFT] reg_idx_raw = addr_offset[ApbAddrWidth-1:ADDR_SHIFT];
  
  // Check if address is within range
  wire addr_valid = (reg_idx_raw < NoApbRegs);
  
  // Register index
  wire [ApbAddrWidth-1:ADDR_SHIFT] reg_idx = addr_valid ? reg_idx_raw : '0;

  // Read data
  wire [RegDataWidth-1:0] read_data = regs[reg_idx];
  
  // Truncate or extend to ApbDataWidth
  wire [ApbDataWidth-1:0] prdata_out;
  generate
    if (RegDataWidth <= ApbDataWidth) begin : gen_read_trunc
      assign prdata_out = read_data[ApbDataWidth-1:0];
    end else begin : gen_read_ext
      assign prdata_out = {{(ApbDataWidth-RegDataWidth){1'b0}}, read_data};
    end
  endgenerate

  assign resp_o.prdata = prdata_out;

  // Write logic
  wire write_en = penable & pwrite & addr_valid;

  // Byte enable mask
  wire [ApbDataWidth-1:0] byte_en = pstrb;

  // Write data with byte enables
  wire [RegDataWidth-1:0] write_data;
  generate
    if (RegDataWidth <= ApbDataWidth) begin : gen_write_trunc
      assign write_data = pwdata[RegDataWidth-1:0];
    end else begin : gen_write_ext
      assign write_data = {{(RegDataWidth-ApbDataWidth){1'b0}}, pwdata};
    end
  endgenerate

  // Apply byte enables
  wire [RegDataWidth-1:0] masked_write_data;
  genvar i;
  generate
    for (i = 0; i < RegDataWidth; i = i + 1) begin : gen_byte_mask
      if (i < ApbDataWidth) begin : gen_valid_byte
        assign masked_write_data[i] = byte_en[i/8] ? write_data[i] : regs[reg_idx][i];
      end else begin : gen_invalid_byte
        assign masked_write_data[i] = regs[reg_idx][i];
      end
    end
  endgenerate

  // Apply read-only mask
  wire [RegDataWidth-1:0] final_write_data;
  generate
    for (i = 0; i < RegDataWidth; i = i + 1) begin : gen_ro_mask
      if (ReadOnly[reg_idx]) begin : gen_ro_bit
        assign final_write_data[i] = regs[reg_idx][i];
      end else begin : gen_rw_bit
        assign final_write_data[i] = masked_write_data[i];
      end
    end
  endgenerate

  // Register update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int unsigned j = 0; j < NoApbRegs; j = j + 1) begin
        regs[j] <= reg_init_i[j];
      end
    end else begin
      if (write_en) begin
        regs[reg_idx] <= final_write_data;
      end
    end
  end

  // Output registers
  always_comb begin
    for (int unsigned j = 0; j < NoApbRegs; j = j + 1) begin
      reg_q_o[j] = regs[j];
    end
  end

endmodule
