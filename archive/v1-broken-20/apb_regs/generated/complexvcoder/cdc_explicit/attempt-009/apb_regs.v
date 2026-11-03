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
  reg_data_t [NoApbRegs-1:0] reg_file;
  reg_data_t [NoApbRegs-1:0] reg_init_reg;
  reg_data_t [NoApbRegs-1:0] reg_q_reg;

  // Initialize register file from reg_init_i
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_file <= reg_init_i;
    end else begin
      reg_file <= reg_q_reg;
    end
  end

  // Handle register write
  always_ff @(posedge pclk_i) begin
    if (req_i.write_en) begin
      if (ReadOnly[req_i.addr[NoApbRegs-1:0]]) begin
        // Ignore write if read-only
        reg_q_reg <= reg_file;
      end else begin
        reg_q_reg[req_i.addr[NoApbRegs-1:0]] <= req_i.data;
      end
    end else begin
      reg_q_reg <= reg_file;
    end
  end

  // Handle register read
  assign resp_o = reg_file[req_i.addr[NoApbRegs-1:0]];

  // Drive output
  assign reg_q_o = reg_q_reg;

endmodule
