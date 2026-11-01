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

  // APB signals from req_i
  wire        psel   = req_i[0];
  wire        penable= req_i[1];
  wire        pwrite = req_i[2];
  wire [ApbAddrWidth-1:0] paddr = req_i[ApbAddrWidth+2:3];
  wire [ApbDataWidth-1:0] pwdata = req_i[ApbDataWidth+ApbAddrWidth+3:ApbAddrWidth+3];

  // Register file
  reg_data_t [NoApbRegs-1:0] reg_q;

  // Address decoding
  wire [ApbAddrWidth-1:0] offset_addr = paddr - base_addr_i;
  wire [ApbAddrWidth-1:0] reg_index_addr = offset_addr / AddrOffset;
  wire [ApbAddrWidth-1:0] byte_offset = offset_addr % AddrOffset;

  // Valid register index check
  wire valid_reg = (reg_index_addr < NoApbRegs);

  // Write enable
  wire write_en = psel & penable & pwrite & valid_reg;

  // Read data
  reg_data_t read_data;
  assign read_data = valid_reg ? reg_q[reg_index_addr] : '0;

  // APB response
  wire [ApbDataWidth-1:0] prdata = read_data[ApbDataWidth-1:0];
  wire pready = 1'b1;
  wire pslverr = 1'b0;

  // Pack response
  assign resp_o = {pslverr, pready, prdata};

  // Register update logic
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q[i] <= reg_init_i[i];
      end
    end else begin
      if (write_en) begin
        // Only update non-read-only bits
        for (int i = 0; i < NoApbRegs; i++) begin
          if (i == reg_index_addr) begin
            if (ReadOnly[i]) begin
              // Keep read-only bits unchanged
              reg_q[i] <= reg_q[i];
            end else begin
              reg_q[i] <= pwdata[RegDataWidth-1:0];
            end
          end
        end
      end
    end
  end

  // Output registers
  always @(*) begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_q_o[i] = reg_q[i];
    end
  end

endmodule
