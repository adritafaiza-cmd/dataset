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

  // APB signals
  logic        psel;
  logic        penable;
  logic        pwrite;
  logic [ApbAddrWidth-1:0] paddr;
  logic [ApbDataWidth-1:0] pwdata;
  logic [3:0]  pstrb;
  logic        pready;
  logic [ApbDataWidth-1:0] prdata;
  logic [1:0]  pslverr;

  // Extract APB signals from req_t
  assign psel    = req_i[0];
  assign penable = req_i[1];
  assign pwrite  = req_i[2];
  assign paddr   = req_i[3 +: ApbAddrWidth];
  assign pwdata  = req_i[3 + ApbAddrWidth +: ApbDataWidth];
  assign pstrb   = req_i[3 + ApbAddrWidth + ApbDataWidth +: 4];

  // Register file
  reg_data_t [NoApbRegs-1:0] reg_q;

  // Address decoding
  logic [ApbAddrWidth-1:0] offset_addr;
  logic [NoApbRegs-1:0]    reg_sel;
  logic                    valid_addr;

  assign offset_addr = paddr - base_addr_i;
  assign valid_addr  = (offset_addr % AddrOffset == 0) &&
                       (offset_addr / AddrOffset < NoApbRegs);

  genvar i;
  generate
    for (i = 0; i < NoApbRegs; i = i + 1) begin : gen_reg_sel
      assign reg_sel[i] = valid_addr && (offset_addr / AddrOffset == i);
    end
  endgenerate

  // Write enable
  logic [NoApbRegs-1:0] write_en;
  assign write_en = penable & pwrite & reg_sel;

  // Read data
  logic [ApbDataWidth-1:0] read_data;
  always_comb begin
    read_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (reg_sel[i]) begin
        // Truncate or extend reg_data to ApbDataWidth
        if (RegDataWidth <= ApbDataWidth)
          read_data = ApbDataWidth'(reg_q[i]);
        else
          read_data = reg_q[i][ApbDataWidth-1:0];
      end
    end
  end

  // APB response
  assign prdata  = read_data;
  assign pslverr = valid_addr ? 2'b00 : 2'b01;
  assign pready  = penable;

  // Build resp_t
  assign resp_o = {pslverr, pready, prdata};

  // Register update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q[i] <= reg_init_i[i];
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (write_en[i] && !ReadOnly[i]) begin
          // Apply byte strobes
          reg_data_t new_val = reg_q[i];
          if (RegDataWidth <= 32) begin
            for (int b = 0; b < RegDataWidth/8; b++) begin
              if (pstrb[b]) begin
                new_val[b*8 +: 8] = pwdata[b*8 +: 8];
              end
            end
          end else begin
            // For wider registers, apply strobes up to 4 bytes
            for (int b = 0; b < 4; b++) begin
              if (pstrb[b]) begin
                new_val[b*8 +: 8] = pwdata[b*8 +: 8];
              end
            end
          end
          reg_q[i] <= new_val;
        end
      end
    end
  end

  assign reg_q_o = reg_q;

endmodule
