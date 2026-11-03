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

  // Internal signals
  reg_data_t [NoApbRegs-1:0] regs;
  reg_data_t [NoApbRegs-1:0] regs_next;
  logic [ApbAddrWidth-1:0] addr;
  logic [ApbAddrWidth-1:0] addr_next;
  logic write_en;

  // Address calculation
  assign addr = base_addr_i + (req_i ? (reg_data_t) (req_i * AddrOffset) : 0);

  // Register logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      regs <= reg_init_i;
      addr_next <= 0;
      write_en <= 0;
    end else begin
      if (req_i) begin
        if (addr < NoApbRegs * RegDataWidth) begin
          if (write_en) begin
            regs[addr / RegDataWidth] <= reg_data_t(req_i);
          end
          addr_next <= addr + RegDataWidth;
        end else begin
          addr_next <= 0;
        end
        write_en <= !ReadOnly[addr / RegDataWidth];
      end else begin
        addr_next <= 0;
        write_en <= 0;
      end
    end
  end

  // Output logic
  assign reg_q_o = regs;
  assign resp_o = req_i ? 1'b1 : 1'b0;

endmodule
