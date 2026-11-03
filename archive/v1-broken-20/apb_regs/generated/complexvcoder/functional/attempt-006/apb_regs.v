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

  localparam int unsigned RegOffset = RegDataWidth / 8;
  localparam int unsigned NumBytes = NoApbRegs * RegOffset;

  reg_data_t [NoApbRegs-1:0] regs;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      regs <= reg_init_i;
    end else if (req_i) begin
      resp_o <= 1'b1; // Assuming resp_o is 1 for successful write
      if (reg_data_t [ApbAddrWidth-1:ApbAddrWidth-RegOffset] == base_addr_i) begin
        int unsigned index = (reg_data_t [ApbAddrWidth-1:ApbAddrWidth-RegOffset] - base_addr_i) / RegOffset;
        if (ReadOnly[index] == 1'b0) begin
          regs[index] <= reg_data_t [RegOffset-1:0];
        end
      end
    end else begin
      resp_o <= 1'b0; // Assuming resp_o is 0 for no operation
    end
  end

  assign reg_q_o = regs;

endmodule
