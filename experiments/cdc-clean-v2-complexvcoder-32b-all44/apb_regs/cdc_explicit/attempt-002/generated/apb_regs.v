module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd8,  // Example value, can be adjusted
  parameter int unsigned        ApbAddrWidth = 32'd32, // Example value, can be adjusted
  parameter int unsigned        AddrOffset   = 32'd4,
  parameter int unsigned        ApbDataWidth = 32'd32, // Example value, can be adjusted
  parameter int unsigned        RegDataWidth = 32'd32, // Example value, can be adjusted
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
  logic [ApbAddrWidth-1:0]   reg_addr;
  logic                      write_enable;
  reg_data_t                 read_data;
  reg_data_t                 write_data;
  logic [ApbDataWidth/8-1:0] byte_strobe;
  logic [NoApbRegs-1:0]      reg_wr_en;

  // Decode the register address
  always_comb begin
    reg_addr = (req_i) ? (base_addr_i[ApbAddrWidth-1:$clog2(AddrOffset)] - base_addr_i[$clog2(AddrOffset)-1:0]) : '0;
    reg_wr_en = (1 << reg_addr);
  end

  // Handle byte strobes
  always_comb begin
    write_data = '0;
    for (int i = 0; i < ApbDataWidth/8; i++) begin
      if (byte_strobe[i]) begin
        write_data[i*8 +: 8] = req_i ? req_i.pwdata[i*8 +: 8] : '0;
      end
    end
  end

  // Write enable logic
  always_comb begin
    write_enable = req_i & req_i.psel & req_i.penable & ~ReadOnly[reg_addr];
  end

  // Register file read process
  always_comb begin
    read_data = (ReadOnly[reg_addr]) ? reg_init_i[reg_addr] : reg_file[reg_addr];
  end

  // Register file write process
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (!ReadOnly[i]) begin
          reg_file[i] <= '0;
        end
      end
    end else if (write_enable) begin
      reg_file[reg_addr] <= (reg_file[reg_addr] & ~({ApbDataWidth{byte_strobe}})) | (write_data & {ApbDataWidth{byte_strobe}});
    end
  end

  // APB response logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      resp_o <= 0;
    end else begin
      resp_o <= req_i & req_i.psel & req_i.penable;
    end
  end

  // Output the current register values
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q_o <= '0;
    end else begin
      reg_q_o <= reg_file;
    end
  end

endmodule
