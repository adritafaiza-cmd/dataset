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

  // Internal register file
  reg_data_t reg_file [NoApbRegs-1:0];

  // Internal signals
  logic [ApbAddrWidth-1:0] addr;
  logic [NoApbRegs-1:0]    reg_sel;
  logic [ApbDataWidth/8-1:0] byte_strobe;
  logic                    write_enable;
  logic                    read_enable;
  reg_data_t               write_data;
  reg_data_t               read_data;

  // Decode the address
  assign addr = req_i.paddr - base_addr_i;
  assign reg_sel = (addr < NoApbRegs * AddrOffset) ? (1 << (addr / AddrOffset)) : 0;

  // Byte strobe
  assign byte_strobe = req_i.pstrb;

  // Write enable and read enable
  assign write_enable = req_i.psel && req_i.penable && req_i.pwrite;
  assign read_enable = req_i.psel && req_i.penable && !req_i.pwrite;

  // Write data
  assign write_data = req_i.pwdata;

  // Read data
  always_comb begin
    read_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (reg_sel[i]) begin
        read_data = ReadOnly[i] ? reg_init_i[i] : reg_file[i];
      end
    end
  end

  // Register file update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (!ReadOnly[i]) begin
          reg_file[i] <= '0;
        end
      end
    end else if (write_enable) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (reg_sel[i] && !ReadOnly[i]) begin
          for (int j = 0; j < ApbDataWidth/8; j++) begin
            if (byte_strobe[j]) begin
              reg_file[i][j*8 +: 8] <= write_data[j*8 +: 8];
            end
          end
        end
      end
    end
  end

  // Output current register values
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q_o <= '0;
    end else begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q_o[i] <= ReadOnly[i] ? reg_init_i[i] : reg_file[i];
      end
    end
  end

  // APB response
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      resp_o.prdata <= '0;
      resp_o.pready <= 1'b0;
      resp_o.pslverr <= 1'b0;
    end else if (read_enable) begin
      resp_o.prdata <= read_data;
      resp_o.pready <= 1'b1;
      resp_o.pslverr <= 1'b0;
    end else begin
      resp_o.pready <= 1'b0;
    end
  end

endmodule
