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

  // Determine which register is being accessed
  // Each register occupies AddrOffset bytes
  wire [ApbAddrWidth-1:0] reg_index_raw = addr_offset / AddrOffset;
  
  // Clamp register index to valid range
  wire [ApbAddrWidth-1:0] reg_index = (reg_index_raw < NoApbRegs) ? reg_index_raw : '0;
  wire in_range = (reg_index_raw < NoApbRegs);

  // Byte offset within the register
  wire [ApbAddrWidth-1:0] byte_offset = addr_offset % AddrOffset;

  // Register storage
  reg_data_t [NoApbRegs-1:0] reg_r;

  // Output register values
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      if (ReadOnly[i])
        reg_q_o[i] = reg_init_i[i];
      else
        reg_q_o[i] = reg_r[i];
    end
  end

  // Write logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_r[i] <= '0;
      end
    end else begin
      // APB write occurs when psel and penable are both high and it's a write
      if (psel && penable && pwrite && in_range) begin
        if (!ReadOnly[reg_index]) begin
          // Apply byte strobes
          reg_data_t new_val = reg_r[reg_index];
          for (int b = 0; b < RegDataWidth/8; b++) begin
            // Check if this byte is within the strobe range
            // pstrb has ApbDataWidth/8 bits, corresponding to bytes of the APB data bus
            // We need to map byte_offset + b to the strobe
            if (b < ApbDataWidth/8) begin
              if (pstrb[b]) begin
                new_val[b*8 +: 8] = pwdata[b*8 +: 8];
              end
            end
          end
          reg_r[reg_index] <= new_val;
        end
      end
    end
  end

  // Response
  assign resp_o.pready = 1'b1;
  assign resp_o.pslverr = 1'b0;
  assign resp_o.prdata = '0;

endmodule
