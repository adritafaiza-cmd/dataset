module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd32,
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
  apb_addr_t                 addr;
  logic                      write_enable;
  reg_data_t                 read_data;
  reg_data_t                 write_data;
  logic [ApbDataWidth/8-1:0] byte_strobe;

  // Decode address
  assign addr = (req_i.addr - base_addr_i) / AddrOffset;

  // Determine if the register is writable
  assign write_enable = req_i.psel && req_i.penable && !ReadOnly[addr];

  // Byte strobe
  assign byte_strobe = req_i.pstrb;

  // Read data from register file
  assign read_data = (addr < NoApbRegs) ? ((ReadOnly[addr]) ? reg_init_i[addr] : reg_file[addr]) : '0;

  // Write data to register file
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        if (ReadOnly[i]) begin
          reg_file[i] <= reg_init_i[i];
        end else begin
          reg_file[i] <= '0;
        end
      end
    end else if (write_enable) begin
      for (int i = 0; i < ApbDataWidth/8; i = i + 1) begin
        if (byte_strobe[i]) begin
          reg_file[addr][i*8 +: 8] <= write_data[i*8 +: 8];
        end
      end
    end
  end

  // APB response
  assign resp_o = req_i.psel && req_i.penable;

  // Drive output with current register values
  assign reg_q_o = reg_file;

endmodule
