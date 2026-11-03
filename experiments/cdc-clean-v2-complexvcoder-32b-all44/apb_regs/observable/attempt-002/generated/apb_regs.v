module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd8,
  parameter int unsigned        ApbAddrWidth = 32'd32,
  parameter int unsigned        AddrOffset   = 32'd4,
  parameter int unsigned        ApbDataWidth = 32'd32,
  parameter int unsigned        RegDataWidth = 32'd32,
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
  logic [NoApbRegs-1:0]      reg_addr;
  logic [NoApbRegs-1:0]      write_enable;
  reg_data_t                 read_data;
  reg_data_t                 write_data;
  logic                      psel;
  logic                      penable;
  logic                      pwrite;
  logic [ApbDataWidth/8-1:0] pstrb;
  apb_addr_t                 paddr;
  logic                      pready;

  // Decode the register address
  always_comb begin
    reg_addr = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (paddr[ApbAddrWidth-1:AddrOffset] == base_addr_i[ApbAddrWidth-1:AddrOffset] + i) begin
        reg_addr[i] = 1'b1;
      end
    end
  end

  // APB signals
  assign psel   = req_i;
  assign penable = req_i;
  assign pwrite = req_i; // Assuming req_i is high only during write or read access
  assign pstrb  = 4'b1111; // Assuming byte strobe is always 4 bytes for simplicity
  assign paddr  = req_i ? base_addr_i : '0;

  // Read data
  always_comb begin
    read_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (reg_addr[i]) begin
        read_data = reg_file[i];
      end
    end
  end

  // Write data with byte strobe
  always_comb begin
    write_data = '0;
    for (int i = 0; i < ApbDataWidth/8; i++) begin
      if (pstrb[i]) begin
        write_data[i*8 +: 8] = req_i ? paddr[i*8 +: 8] : '0; // Assuming paddr holds the write data
      end else begin
        write_data[i*8 +: 8] = reg_file[reg_addr.index][i*8 +: 8];
      end
    end
  end

  // Write enable
  always_comb begin
    write_enable = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (reg_addr[i] && !ReadOnly[i] && psel && penable && pwrite) begin
        write_enable[i] = 1'b1;
      end
    end
  end

  // Register file update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) begin
          reg_file[i] <= reg_init_i[i];
        end else begin
          reg_file[i] <= '0;
        end
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (write_enable[i]) begin
          reg_file[i] <= write_data;
        end
      end
    end
  end

  // Response signal
  assign resp_o = pready;

endmodule
