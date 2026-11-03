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
  apb_addr_t                 decoded_addr;
  logic                      write_enable;
  logic                      read_enable;
  reg_data_t                 write_data;
  reg_data_t                 read_data;
  logic [(ApbDataWidth/8)-1:0] byte_strobe;
  logic [$clog2(NoApbRegs)-1:0] reg_index;

  // Decode the address
  assign decoded_addr = req_i ? (base_addr_i + (reg_index * AddrOffset)) : '0;
  assign reg_index    = (req_i) ? (decoded_addr[AddrOffset +: $clog2(NoApbRegs)]) : '0;

  // Determine read/write enable
  assign read_enable  = req_i && !req_i.pwrite;
  assign write_enable = req_i &&  req_i.pwrite && req_i.penable;

  // Byte strobe
  assign byte_strobe = req_i ? req_i.pstrb : '0;

  // Write data
  assign write_data = req_i ? req_i.pwdata : '0;

  // Read data
  assign read_data = reg_file[reg_index];

  // APB response
  assign resp_o = req_i.penable ? '1 : '0;

  // Register file logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        if (ReadOnly[i])
          reg_file[i] <= reg_init_i[i];
        else
          reg_file[i] <= '0;
      end
    end else if (write_enable) begin
      for (int b = 0; b < (ApbDataWidth / 8); b = b + 1) begin
        if (byte_strobe[b]) begin
          reg_file[reg_index][(b * 8) +: 8] <= write_data[(b * 8) +: 8];
        end
      end
    end
  end

  // Output register values
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        reg_q_o[i] <= ReadOnly[i] ? reg_init_i[i] : '0;
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        if (ReadOnly[i])
          reg_q_o[i] <= reg_init_i[i];
        else
          reg_q_o[i] <= reg_file[i];
      end
    end
  end

endmodule
