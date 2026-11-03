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
  reg_data_t [NoApbRegs*RegDataWidth-1:0] reg_q;
  reg_data_t reg_addr;
  reg_data_t reg_data;
  reg_data_t reg_data_out;
  bit reg_read;
  bit reg_write;
  reg_data_t reg_read_data;
  reg_data_t reg_write_data;

  // Register file logic
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q <= reg_init_i;
    end else begin
      if (req_i) begin
        reg_addr <= base_addr_i + (req_i.addr / AddrOffset);
        reg_data <= req_i.data;
        reg_read <= req_i.read;
        reg_write <= req_i.write;
      end
      if (reg_read) begin
        reg_data_out <= reg_q[reg_addr * RegDataWidth +: RegDataWidth];
        resp_o <= resp_t.OK;
      end else if (reg_write) begin
        if (!ReadOnly[reg_addr]) begin
          reg_q[reg_addr * RegDataWidth +: RegDataWidth] <= reg_data;
        end
        resp_o <= resp_t.OK;
      end else begin
        resp_o <= resp_t.ERROR;
      end
    end
  end

  // Output assignments
  assign reg_q_o = reg_q;
  assign resp_o = resp_o;

endmodule
