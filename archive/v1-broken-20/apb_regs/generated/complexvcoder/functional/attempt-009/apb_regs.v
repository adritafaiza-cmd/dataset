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

  logic [NoApbRegs-1:0] regs [0:NoApbRegs-1];

  assign reg_q_o = regs;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      regs <= reg_init_i;
    end else if (req_i) begin
      if (req_i.addr >= base_addr_i && req_i.addr < base_addr_i + NoApbRegs * AddrOffset) begin
        if (req_i.we) begin
          int unsigned reg_index = (req_i.addr - base_addr_i) / AddrOffset;
          if (ReadOnly[reg_index]) begin
            resp_o <= 1'b0; // Write ignored
          end else begin
            regs[reg_index] <= req_i.wdata;
            resp_o <= 1'b1; // Write successful
          end
        end else begin
          resp_o <= 1'b1; // Read successful
        end
      end else begin
        resp_o <= 1'b0; // Address out of range
      end
    end else begin
      resp_o <= 1'b0; // No request
    end
  end

endmodule
