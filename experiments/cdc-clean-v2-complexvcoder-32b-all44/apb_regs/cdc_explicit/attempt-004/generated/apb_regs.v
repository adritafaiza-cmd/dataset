module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd0,
  parameter int unsigned        ApbAddrWidth = 32'd0,
  parameter int unsigned        AddrOffset   = 32'd4,
  parameter int unsigned        ApbDataWidth = 32'd0,
  parameter int unsigned        RegDataWidth = 32'd0,
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
  logic [$clog2(NoApbRegs)-1:0] reg_addr;
  logic write_enable;
  reg_data_t read_data;
  reg_data_t write_data;
  logic [ApbDataWidth/8-1:0] byte_strobe;

  // APB signals
  logic psel;
  logic penable;
  logic pwrite;
  reg_data_t prdata;
  reg_data_t pwdata;

  // Address decoding
  assign reg_addr = (req_i.paddr - base_addr_i) / AddrOffset;

  // Byte strobe extraction
  assign byte_strobe = req_i.pstrb;

  // Write data preparation
  genvar i;
  generate
    for (i = 0; i < RegDataWidth/8; i = i + 1) begin : gen_byte_write_data
      assign write_data[8*i +: 8] = byte_strobe[i] ? req_i.pwdata[8*i +: 8] : reg_file[reg_addr][8*i +: 8];
    end
  endgenerate

  // Read data selection
  assign read_data = ReadOnly[reg_addr] ? reg_init_i[reg_addr] : reg_file[reg_addr];

  // APB request signals
  assign psel = req_i.psel;
  assign penable = req_i.penable;
  assign pwrite = req_i.pwrite;
  assign pwdata = req_i.pwdata;

  // APB response
  assign resp_o = req_i.pready;

  // Register file logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int j = 0; j < NoApbRegs; j = j + 1) begin
        if (ReadOnly[j]) begin
          reg_file[j] <= reg_init_i[j];
        end else begin
          reg_file[j] <= '0;
        end
      end
    end else if (psel && penable) begin
      if (pwrite && !ReadOnly[reg_addr]) begin
        reg_file[reg_addr] <= write_data;
      end
    end
  end

  // Output current register values
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q_o <= '0;
    end else begin
      reg_q_o <= reg_file;
    end
  end

endmodule
