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
  reg_data_t [NoApbRegs-1:0] registers;
  reg_data_t                 selected_reg;
  logic [$clog2(NoApbRegs)-1:0] reg_addr;
  logic                        is_read_only;
  reg_data_t                 write_data;
  logic [ApbDataWidth/8-1:0] byte_strobe;

  // Decode register address
  assign reg_addr = (req_i.paddr - base_addr_i) / AddrOffset;

  // Determine if the selected register is read-only
  assign is_read_only = (reg_addr < NoApbRegs) ? ReadOnly[reg_addr] : 1'b0;

  // Select register data
  always_comb begin
    if (reg_addr < NoApbRegs) begin
      if (is_read_only)
        selected_reg = reg_init_i[reg_addr];
      else
        selected_reg = registers[reg_addr];
    end else begin
      selected_reg = '0;
    end
  end

  // Generate response
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      resp_o <= 0;
    end else begin
      resp_o <= req_i.psel & req_i.penable;
    end
  end

  // Write data generation with byte strobes
  always_comb begin
    write_data = '0;
    for (int i = 0; i < ApbDataWidth/8; i++) begin
      if (req_i.pwrite && byte_strobe[i]) begin
        write_data[i*8 +: 8] = req_i.pwdata[i*8 +: 8];
      end else if (reg_addr < NoApbRegs && !is_read_only) begin
        write_data[i*8 +: 8] = registers[reg_addr][i*8 +: 8];
      end else if (reg_addr < NoApbRegs && is_read_only) begin
        write_data[i*8 +: 8] = reg_init_i[reg_addr][i*8 +: 8];
      end
    end
  end

  // Byte strobe decoding
  assign byte_strobe = req_i.pstrb;

  // Register file update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i])
          registers[i] <= reg_init_i[i];
        else
          registers[i] <= '0;
      end
    end else if (req_i.psel && req_i.penable && req_i.pwrite && !is_read_only) begin
      registers[reg_addr] <= write_data;
    end
  end

  // Output current register values
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q_o <= '0;
    end else begin
      reg_q_o <= registers;
    end
  end

endmodule
