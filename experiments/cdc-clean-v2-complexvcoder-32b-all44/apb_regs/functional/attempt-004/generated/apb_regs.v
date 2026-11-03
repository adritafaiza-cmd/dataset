module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd8,
  parameter int unsigned        ApbAddrWidth = 32'd12,
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

  logic [NoApbRegs-1:0] [RegDataWidth-1:0] reg_file;
  logic [NoApbRegs-1:0] reg_addr;
  logic [RegDataWidth-1:0] write_data;
  logic write_enable;
  logic [ApbDataWidth/8-1:0] byte_strobe;
  logic [RegDataWidth-1:0] read_data;
  logic psel;
  logic penable;
  logic pwrite;

  // Decode the APB address
  always_comb begin
    reg_addr = '0;
    psel = 1'b0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (base_addr_i + i * AddrOffset == req_i.paddr) begin
        reg_addr[i] = 1'b1;
        psel = 1'b1;
      end
    end
  end

  // Assign byte strobe
  assign byte_strobe = req_i.pstrb;

  // Determine write data and enable
  assign write_data = req_i.pwdata;
  assign write_enable = psel & penable & pwrite;

  // Write logic
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
        if (reg_addr[i] && !ReadOnly[i]) begin
          for (int b = 0; b < ApbDataWidth/8; b++) begin
            if (byte_strobe[b]) begin
              reg_file[i][b*8 +: 8] <= write_data[b*8 +: 8];
            end
          end
        end
      end
    end
  end

  // Read logic
  always_comb begin
    read_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (reg_addr[i]) begin
        read_data = ReadOnly[i] ? reg_init_i[i] : reg_file[i];
      end
    end
  end

  // APB response
  assign resp_o.prdata = read_data;
  assign resp_o.pready = psel;
  assign resp_o.pslverr = 1'b0;

  // Output current register values
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_q_o[i] = ReadOnly[i] ? reg_init_i[i] : reg_file[i];
    end
  end

endmodule
