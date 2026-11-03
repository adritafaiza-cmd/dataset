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
  reg_data_t [NoApbRegs-1:0] reg_file;
  logic [NoApbRegs-1:0]      addr_decoded;
  logic                      write_enable;
  logic                      read_enable;
  reg_data_t                 reg_write_data;
  reg_data_t                 reg_read_data;
  logic [ApbDataWidth/8-1:0] byte_strobe;
  logic [NoApbRegs-1:0]      pending_write;
  logic                      reset;

  // Decode address
  always_comb begin
    addr_decoded = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      addr_decoded[i] = (req_i.paddr == base_addr_i + i * AddrOffset);
    end
  end

  // Byte strobe extraction
  assign byte_strobe = req_i.pstrb;

  // Write enable and read enable
  assign write_enable = req_i.psel && req_i.penable && req_i.pwrite;
  assign read_enable  = req_i.psel && req_i.penable && !req_i.pwrite;

  // Write data handling
  always_comb begin
    reg_write_data = '0;
    for (int i = 0; i < ApbDataWidth/8; i++) begin
      if (byte_strobe[i]) begin
        reg_write_data[i*8 +: 8] = req_i.pwdata[i*8 +: 8];
      end
    end
  end

  // Register file update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (!ReadOnly[i]) begin
          reg_file[i] <= '0;
        end else begin
          reg_file[i] <= reg_init_i[i];
        end
      end
    end else if (write_enable) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (addr_decoded[i] && !ReadOnly[i]) begin
          reg_file[i] <= reg_file[i] ^ ((reg_file[i] ^ reg_write_data) & {RegDataWidth{1'b1}});
        end
      end
    end
  end

  // Read data handling
  always_comb begin
    reg_read_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (addr_decoded[i]) begin
        reg_read_data = ReadOnly[i] ? reg_init_i[i] : reg_file[i];
      end
    end
  end

  // Response generation
  always_comb begin
    resp_o.prdata = reg_read_data;
    resp_o.pready = 1'b1;
    resp_o.pslverr = 1'b0;
  end

  // Output current register values
  assign reg_q_o = reg_file;

endmodule
