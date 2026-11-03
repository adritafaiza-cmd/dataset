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
  logic [$clog2(NoApbRegs)-1:0] reg_addr;
  logic write_enable;
  reg_data_t read_data;
  reg_data_t write_data;
  logic [ApbDataWidth/8-1:0] pstrb;

  // Decode the address to select the register
  always_comb begin
    reg_addr = (req_i.paddr - base_addr_i) / AddrOffset;
    if (reg_addr >= NoApbRegs)
      reg_addr = 0; // Out-of-bounds address defaults to first register
  end

  // Read data from the selected register
  always_comb begin
    if (ReadOnly[reg_addr])
      read_data = reg_init_i[reg_addr];
    else
      read_data = registers[reg_addr];
  end

  // Generate write enable signal
  always_comb begin
    write_enable = req_i.psel && req_i.penable && req_i.pwrite;
  end

  // Generate write data with byte strobes
  always_comb begin
    write_data = read_data; // Start with current data
    for (int i = 0; i < ApbDataWidth/8; i++) begin
      if (req_i.pstrb[i])
        write_data[i*8 +: 8] = req_i.pwdata[i*8 +: 8];
    end
  end

  // Register bank update logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i])
          registers[i] <= reg_init_i[i];
        else
          registers[i] <= 0;
      end
    end else if (write_enable) begin
      if (!ReadOnly[reg_addr])
        registers[reg_addr] <= write_data;
    end
  end

  // Assign outputs
  always_comb begin
    resp_o.prdata = read_data;
    resp_o.pready = 1'b1;
    resp_o.pslverr = 1'b0;
  end

  assign reg_q_o = registers;

endmodule
