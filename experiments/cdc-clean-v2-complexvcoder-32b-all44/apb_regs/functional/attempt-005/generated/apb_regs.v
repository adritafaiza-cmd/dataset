module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd8,
  parameter int unsigned        ApbAddrWidth = 32'd32,
  parameter int unsigned        AddrOffset   = 32'd4,
  parameter int unsigned        ApbDataWidth = 32'd32,
  parameter int unsigned        RegDataWidth = 32'd32,
  parameter bit [NoApbRegs-1:0] ReadOnly     = 32'h0,
  parameter type                req_t        = logic,
  parameter type                resp_t       = logic,
  parameter type                apb_addr_t   = logic[ApbAddrWidth-1:0],
  parameter type                reg_data_t   = logic[RegDataWidth-1:0]
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
  reg_data_t [NoApbRegs-1:0] registers;
  int unsigned                 reg_addr;
  logic                        is_read;
  logic                        is_write;
  reg_data_t                   write_data;
  reg_data_t                   read_data;

  // Decode the register address
  assign reg_addr = (req_i.paddr - base_addr_i) / AddrOffset;

  // Determine if the current transaction is a read or write
  assign is_read  = req_i.psel && req_i.penable && !req_i.pwrite;
  assign is_write = req_i.psel && req_i.penable && req_i.pwrite;

  // Handle read operation
  always_comb begin
    if (reg_addr < NoApbRegs) begin
      if (ReadOnly[reg_addr])
        read_data = reg_init_i[reg_addr];
      else
        read_data = registers[reg_addr];
    end else begin
      read_data = '0;
    end
  end

  // Handle write operation
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        if (ReadOnly[i])
          registers[i] <= reg_init_i[i];
        else
          registers[i] <= '0;
      end
    end else if (is_write && reg_addr < NoApbRegs && !ReadOnly[reg_addr]) begin
      for (int b = 0; b < (RegDataWidth / 8); b = b + 1) begin
        if (req_i.pstrb[b]) begin
          registers[reg_addr][b*8 +: 8] <= req_i.pwdata[b*8 +: 8];
        end
      end
    end
  end

  // Drive the output ports
  assign resp_o.prdata = read_data;
  assign resp_o.pready = 1'b1;
  assign resp_o.pslverr = 1'b0;

  assign reg_q_o = registers;

endmodule
