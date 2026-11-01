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
  wire        psel   = req_i[0];
  wire        penable= req_i[1];
  wire        pwrite = req_i[2];
  wire [ApbAddrWidth-1:0] paddr = req_i[ApbAddrWidth+2:3];
  wire [ApbDataWidth-1:0] pwdata = req_i[ApbDataWidth+ApbAddrWidth+3:ApbAddrWidth+3];

  // Register index
  wire [ApbAddrWidth-1:0] offset = paddr - base_addr_i;
  wire [ApbAddrWidth-1:0] reg_idx = offset / AddrOffset;
  wire valid_addr = (reg_idx < NoApbRegs);

  // Read data
  wire [RegDataWidth-1:0] rdata = valid_addr ? reg_q_o[reg_idx] : '0;

  // Write enable
  wire wren = psel & penable & pwrite & valid_addr;

  // Register file
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q_o[i] <= reg_init_i[i];
      end
    end else begin
      if (wren) begin
        if (ReadOnly[reg_idx]) begin
          // Read-only: keep unchanged
          reg_q_o[reg_idx] <= reg_q_o[reg_idx];
        end else begin
          reg_q_o[reg_idx] <= pwdata[RegDataWidth-1:0];
        end
      end
    end
  end

  // APB response
  assign resp_o = psel & penable ? 1'b1 : 1'b0;

endmodule
