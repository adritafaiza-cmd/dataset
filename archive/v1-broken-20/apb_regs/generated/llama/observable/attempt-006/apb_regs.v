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

  logic [RegDataWidth-1:0] reg_q [NoApbRegs-1:0];
  logic [RegDataWidth-1:0] reg_d [NoApbRegs-1:0];
  logic [ApbAddrWidth-1:0] addr;
  logic [RegDataWidth-1:0] data;
  logic [RegDataWidth-1:0] data_q;
  logic [RegDataWidth-1:0] data_d;
  logic write;
  logic read;
  logic [NoApbRegs-1:0] reg_we;

  assign addr = req_i.addr;
  assign data = req_i.data;
  assign write = req_i.write;
  assign read = req_i.read;

  assign resp_o.data = data_q;
  assign resp_o.ack = 1'b1;

  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_we[i] = 1'b0;
      if (addr == (base_addr_i + i)) begin
        if (write &&!ReadOnly[i]) begin
          reg_we[i] = 1'b1;
        end
      end
    end
  end

  always_comb begin
    data_d = data;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (reg_we[i]) begin
        reg_d[i] = data_d;
      end else begin
        reg_d[i] = reg_q[i];
      end
    end
  end

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q[i] <= reg_init_i[i];
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q[i] <= reg_d[i];
      end
    end
  end

  always_comb begin
    data_q = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (addr == (base_addr_i + i)) begin
        data_q = reg_q[i];
      end
    end
  end

  always_comb begin
    reg_q_o = reg_q;
  end

endmodule
