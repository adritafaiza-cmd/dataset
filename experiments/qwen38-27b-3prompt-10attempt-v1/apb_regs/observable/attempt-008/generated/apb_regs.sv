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

  // APB request fields
  wire        psel   = req_i.psel;
  wire        penable = req_i.penable;
  wire        pwrite = req_i.pwrite;
  wire [ApbAddrWidth-1:0] paddr = req_i.paddr;
  wire [ApbDataWidth-1:0] pwdata = req_i.pwdata;

  // APB response fields
  resp_o.pready = 1'b1;
  resp_o.pslverr = 1'b0;
  resp_o.prdata = '0;

  // Compute register index from address
  wire [ApbAddrWidth-1:0] offset = paddr - base_addr_i;
  wire [ApbAddrWidth-1:0] reg_idx_full = offset / AddrOffset;
  wire [ApbAddrWidth-1:0] reg_idx = reg_idx_full;

  // Valid register index check
  wire valid_idx = (reg_idx < NoApbRegs);

  // Write enable: PSEL & PENABLE & PWRITE & valid index
  wire wr_en = psel & penable & pwrite & valid_idx;

  // Read data: select register based on index
  reg_data_t rd_data;
  always_comb begin
    rd_data = '0;
    for (int unsigned i = 0; i < NoApbRegs; i++) begin
      if (reg_idx == i) begin
        rd_data = reg_q_o[i];
      end
    end
  end

  // Drive read data on APB bus
  assign resp_o.prdata = rd_data[ApbDataWidth-1:0];

  // Register file
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int unsigned i = 0; i < NoApbRegs; i++) begin
        reg_q_o[i] <= reg_init_i[i];
      end
    end else begin
      if (wr_en) begin
        for (int unsigned i = 0; i < NoApbRegs; i++) begin
          if (reg_idx == i) begin
            if (ReadOnly[i]) begin
              // Read-only: keep unchanged
              reg_q_o[i] <= reg_q_o[i];
            end else begin
              // Writable: update with new data
              reg_q_o[i] <= reg_data_t'(pwdata);
            end
          end
        end
      end
    end
  end

endmodule
