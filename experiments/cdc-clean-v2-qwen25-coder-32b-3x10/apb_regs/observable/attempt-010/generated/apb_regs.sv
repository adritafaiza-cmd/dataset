module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd4,
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

  // Internal register file
  reg_data_t [NoApbRegs-1:0] reg_file;

  // Internal signals
  logic [NoApbRegs-1:0] reg_addr_match;
  logic [RegDataWidth/8-1:0] byte_strobe;
  logic [ApbDataWidth-1:0] write_data;
  logic [ApbDataWidth-1:0] read_data;
  logic psel;
  logic penable;
  logic pwrite;
  apb_addr_t paddr;
  logic [ApbDataWidth-1:0] pwdata;
  logic [ApbDataWidth/1-1:0] prdata;
  logic pready;

  // Decode APB request
  assign psel = req_i.psel;
  assign penable = req_i.penable;
  assign pwrite = req_i.pwrite;
  assign paddr = req_i.paddr;
  assign pwdata = req_i.pwdata;
  assign req_i.prdata = prdata;
  assign req_i.pready = pready;

  // Address decoding
  always_comb begin
    reg_addr_match = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (paddr[ApbAddrWidth-1:AddrOffset] == i) begin
        reg_addr_match[i] = 1'b1;
      end
    end
  end

  // Byte strobe decoding
  assign byte_strobe = req_i.pstrb;

  // Write data generation
  always_comb begin
    write_data = '0;
    for (int i = 0; i < RegDataWidth/8; i++) begin
      if (byte_strobe[i]) begin
        write_data[i*8 +: 8] = pwdata[i*8 +: 8];
      end
    end
  end

  // Register file logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) begin
          reg_file[i] <= reg_init_i[i];
        end else begin
          reg_file[i] <= '0;
        end
      end
    end else if (psel && penable) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (reg_addr_match[i] && pwrite && !ReadOnly[i]) begin
          reg_file[i] <= write_data;
        end
      end
    end
  end

  // Read data generation
  always_comb begin
    read_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (reg_addr_match[i]) begin
        read_data = ReadOnly[i] ? reg_init_i[i] : reg_file[i];
      end
    end
  end

  // APB response
  assign prdata = read_data;
  assign pready = 1'b1;
  assign resp_o = '0;

  // Output register values
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q_o <= '0;
    end else begin
      reg_q_o <= reg_file;
    end
  end

endmodule
