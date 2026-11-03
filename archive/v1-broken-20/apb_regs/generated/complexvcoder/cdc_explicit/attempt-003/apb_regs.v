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
  reg_data_t [NoApbRegs-1:0] reg_data;
  reg_data_t [NoApbRegs-1:0] reg_data_next;
  resp_t resp;

  // Register initialization
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_data <= reg_init_i;
    end else begin
      reg_data <= reg_data_next;
    end
  end

  // Register file logic
  always_comb begin
    reg_data_next = reg_data;
    resp = 1'b0;

    if (req_i) begin
      if (base_addr_i[ApbAddrWidth-1:ApbAddrWidth-AddrOffset] < NoApbRegs) begin
        if (ReadOnly[base_addr_i[ApbAddrWidth-1:ApbAddrWidth-AddrOffset]]) begin
          resp = 1'b1; // Read-only access
        end else begin
          reg_data_next[base_addr_i[ApbAddrWidth-1:ApbAddrWidth-AddrOffset]] = reg_init_i[base_addr_i[ApbAddrWidth-1:ApbAddrWidth-AddrOffset]];
          resp = 1'b0; // Write successful
        end
      end else begin
        resp = 1'b1; // Invalid address
      end
    end
  end

  // Output assignment
  assign reg_q_o = reg_data;
  assign resp_o = resp;

endmodule
