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
  logic [NoApbRegs-1:0]      decoded_addr;
  logic [ApbDataWidth/8-1:0] write_strobe;
  reg_data_t                 write_data;
  reg_data_t                 read_data;
  logic                      psel;
  logic                      penable;
  logic                      pwrite;
  apb_addr_t                 paddr;
  reg_data_t                 pwdata;
  reg_data_t                 prdata;
  logic                      pready;
  logic                      pslverr;

  // APB interface decoding
  assign paddr   = req_i ? base_addr_i + (paddr_i - base_addr_i) : '0;
  assign psel    = (req_i && (paddr_i >= base_addr_i) && (paddr_i < base_addr_i + NoApbRegs*AddrOffset));
  assign penable = req_i && psel;
  assign pwrite  = pwrite_i;
  assign pwdata  = pwdata_i;
  assign write_strobe = pstrb_i;

  // Register file read and write logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_file <= '{default: '0};
    end else if (penable) begin
      if (pwrite) begin
        for (int i = 0; i < NoApbRegs; i++) begin
          if (decoded_addr[i] && !ReadOnly[i]) begin
            for (int j = 0; j < ApbDataWidth/8; j++) begin
              if (write_strobe[j]) begin
                reg_file[i][j*8 +: 8] <= pwdata[j*8 +: 8];
              end
            end
          end
        end
      end
    end
  end

  // Decode address to register
  always_comb begin
    decoded_addr = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (paddr == base_addr_i + i*AddrOffset) begin
        decoded_addr[i] = 1'b1;
      end
    end
  end

  // Read data multiplexer
  always_comb begin
    read_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (decoded_addr[i]) begin
        read_data = ReadOnly[i] ? reg_init_i[i] : reg_file[i];
      end
    end
  end

  // APB response logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      pready  <= 1'b0;
      pslverr <= 1'b0;
    end else if (penable) begin
      pready  <= 1'b1;
      pslverr <= 1'b0;
    end else begin
      pready  <= 1'b0;
    end
  end

  // Drive outputs
  assign prdata_o = read_data;
  assign resp_o   = pready;

  // Drive register values output
  assign reg_q_o = reg_file;

endmodule
