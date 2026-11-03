module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd32,
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
  logic [NoApbRegs-1:0]      decoded_addr;
  logic [NoApbRegs-1:0]      write_enable;
  reg_data_t                 read_data;
  reg_data_t                 write_data;
  logic [ApbDataWidth/8-1:0] write_strobe;
  logic                      write_commit;

  // Decode the address
  always_comb begin
    decoded_addr = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (req_i.paddr[ApbAddrWidth-1:$clog2(AddrOffset)] == base_addr_i[ApbAddrWidth-1:$clog2(AddrOffset)] + i) begin
        decoded_addr[i] = 1'b1;
      end
    end
  end

  // Determine write enable for each register
  always_comb begin
    write_enable = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (decoded_addr[i] && req_i.pwrite && !ReadOnly[i]) begin
        write_enable[i] = 1'b1;
      end
    end
  end

  // Generate write data with byte strobes
  always_comb begin
    write_data = '0;
    for (int i = 0; i < ApbDataWidth/8; i++) begin
      if (write_strobe[i]) begin
        write_data[i*8 +: 8] = req_i.pwdata[i*8 +: 8];
      end
    end
  end

  // Write commit signal
  always_comb begin
    write_commit = req_i.psel && req_i.penable;
  end

  // Register file logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (!ReadOnly[i]) begin
          registers[i] <= '0;
        end else begin
          registers[i] <= reg_init_i[i];
        end
      end
    end else if (write_commit) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (write_enable[i]) begin
          registers[i] <= (registers[i] & ~({ApbDataWidth{write_strobe}})) | write_data;
        end
      end
    end
  end

  // Read data selection
  always_comb begin
    read_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (decoded_addr[i]) begin
        read_data = ReadOnly[i] ? reg_init_i[i] : registers[i];
      end
    end
  end

  // APB response
  always_comb begin
    resp_o.prdata = read_data;
    resp_o.pready = 1'b1;
    resp_o.pslverr = 1'b0;
  end

  // Register values output
  always_comb begin
    reg_q_o = registers;
  end

endmodule
