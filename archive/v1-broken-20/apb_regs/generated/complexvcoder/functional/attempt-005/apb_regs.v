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

  // Internal register array
  reg_data_t [NoApbRegs-1:0] regs;

  // Initialize registers from reg_init_i
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      regs <= reg_init_i;
    end else if (req_i) begin
      // Calculate the register index
      int unsigned index = (base_addr_i - base_addr_i[ApbAddrWidth-1:ApbAddrWidth-ApbAddrWidth+AddrOffset]) / AddrOffset;
      if (index < NoApbRegs) begin
        // Handle read and write operations
        if (req_t) begin
          // Write operation
          if (!ReadOnly[index]) begin
            regs[index] <= reg_data_t'(req_t);
          end
        end else begin
          // Read operation
          reg_q_o[index] <= regs[index];
        end
      end
    end
  end

  // Drive resp_o based on the request type
  assign resp_o = req_t;

endmodule
