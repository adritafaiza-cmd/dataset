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
  reg_data_t                 write_data;
  reg_data_t                 read_data;
  logic                      write_enable;
  logic                      read_enable;
  logic                      psel;
  logic                      penable;
  logic                      pwrite;
  logic [ApbDataWidth/8-1:0] pstrb;
  logic [$clog2(NoApbRegs)-1:0] reg_addr;

  // Decode APB address
  always_comb begin
    addr_decoded = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (req_i && (base_addr_i + i * AddrOffset == req_i.paddr)) begin
        addr_decoded[i] = 1'b1;
      end
    end
  end

  // Extract control signals from APB request
  assign psel   = req_i.psel;
  assign penable = req_i.penable;
  assign pwrite = req_i.pwrite;
  assign pstrb  = req_i.pstrb;
  assign reg_addr = (req_i.paddr - base_addr_i) / AddrOffset;

  // Write enable logic
  assign write_enable = psel && penable && pwrite && |addr_decoded;

  // Read enable logic
  assign read_enable = psel && penable && ~pwrite && |addr_decoded;

  // Write data generation
  always_comb begin
    write_data = '0;
    for (int i = 0; i < ApbDataWidth/8; i++) begin
      if (pstrb[i]) begin
        write_data[i*8 +: 8] = req_i.pwdata[i*8 +: 8];
      end
    end
  end

  // Register file update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) begin
          reg_file[i] <= reg_init_i[i];
        end else begin
          reg_file[i] <= '0;
        end
      end
    end else if (write_enable) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (addr_decoded[i] && !ReadOnly[i]) begin
          reg_file[i] <= (reg_file[i] & ~(pstrb << (reg_addr*8))) | (write_data & (pstrb << (reg_addr*8)));
        end
      end
    end
  end

  // Read data selection
  always_comb begin
    read_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (addr_decoded[i]) begin
        read_data = ReadOnly[i] ? reg_init_i[i] : reg_file[i];
      end
    end
  end

  // APB response generation
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      resp_o <= '0;
    end else if (read_enable) begin
      resp_o.prdata <= read_data;
      resp_o.pready <= 1'b1;
      resp_o.pslverr <= 1'b0;
    end else begin
      resp_o.pready <= 1'b0;
      resp_o.pslverr <= 1'b0;
    end
  end

  // Output register values
  assign reg_q_o = reg_file;

endmodule
