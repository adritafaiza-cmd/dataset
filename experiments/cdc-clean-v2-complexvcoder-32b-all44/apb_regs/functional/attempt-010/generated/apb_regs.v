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
  reg_data_t [NoApbRegs-1:0] reg_file;
  reg_data_t                 write_data;
  logic                      write_enable;
  reg_data_t                 read_data;
  apb_addr_t                 reg_addr;
  logic [$clog2(NoApbRegs)-1:0] decoded_addr;
  logic [ApbDataWidth/8-1:0] byte_strobe;

  // APB control signals
  logic psel;
  logic penable;
  logic pwrite;
  logic [ApbDataWidth-1:0] prdata;
  logic [ApbDataWidth-1:0] pwdata;
  logic [ApbDataWidth/8-1:0] pstrb;

  // Decode the APB address
  assign reg_addr = req_i.addr - base_addr_i;
  assign decoded_addr = reg_addr / AddrOffset;

  // Byte strobe signals
  assign byte_strobe = req_i.pstrb;

  // Write data mux for byte-wise updates
  generate
    genvar i;
    for (i = 0; i < RegDataWidth/8; i = i + 1) begin : gen_write_data
      assign write_data[i*8 +: 8] = byte_strobe[i] ? pwdata[i*8 +: 8] : reg_file[decoded_addr][i*8 +: 8];
    end
  endgenerate

  // Write enable logic
  assign write_enable = req_i.psel & req_i.penable & req_i.pwrite & (reg_addr % AddrOffset == 0);

  // Read data mux for read-only registers
  assign read_data = ReadOnly[decoded_addr] ? reg_init_i[decoded_addr] : reg_file[decoded_addr];

  // Register file read and write logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        if (ReadOnly[i]) begin
          reg_file[i] <= reg_init_i[i];
        end else begin
          reg_file[i] <= 0;
        end
      end
    end else if (write_enable) begin
      if (!ReadOnly[decoded_addr]) begin
        reg_file[decoded_addr] <= write_data;
      end
    end
  end

  // APB response generation
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      resp_o <= 0;
    end else if (req_i.psel & req_i.penable) begin
      resp_o <= 1;
    end else begin
      resp_o <= 0;
    end
  end

  // Drive reg_q_o with current register values
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q_o <= reg_init_i;
    end else begin
      reg_q_o <= reg_file;
    end
  end

  // Drive prdata with read_data
  assign req_i.prdata = read_data;

endmodule
