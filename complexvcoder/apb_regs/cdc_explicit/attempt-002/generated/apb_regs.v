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
  reg_data_t [NoApbRegs-1:0] reg_data_n;
  logic                    write_en;
  logic [NoApbRegs-1:0]      reg_en;
  logic [ApbAddrWidth-1:0]   reg_addr;

  // Address calculation
  assign reg_addr = base_addr_i + (req_i.addr >> AddrOffset);

  // Write enable logic
  assign write_en = req_i.write && !ReadOnly[req_i.addr >> AddrOffset];

  // Register enable logic
  generate
    if (NoApbRegs > 0) begin : gen_reg_en
      generate
        genvar i;
        for (i = 0; i < NoApbRegs; i++) begin : gen_reg_en_inst
          assign reg_en[i] = reg_addr == i;
        end
      endgenerate
    end
  endgenerate

  // Register data logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_data <= reg_init_i;
    end else begin
      if (write_en && reg_en[reg_addr]) begin
        reg_data[reg_addr] <= req_i.wdata;
      end
    end
  end

  // Output logic
  always_comb begin
    resp_o = 1'b0;
    reg_q_o = reg_data;
    if (write_en && reg_en[reg_addr]) begin
      resp_o = 1'b1; // Write response
    end
  end

endmodule
