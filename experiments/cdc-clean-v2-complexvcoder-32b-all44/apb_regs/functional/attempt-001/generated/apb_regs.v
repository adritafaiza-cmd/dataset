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
  apb_addr_t                 reg_addr;
  logic                      psel;
  logic                      penable;
  logic                      pwrite;
  reg_data_t                 pwdata;
  logic [ApbDataWidth/8-1:0] pstrb;
  reg_data_t                 prdata;
  reg_data_t                 pending_write;
  logic [RegDataWidth-1:0]   write_enable;

  // Decode APB request
  always_comb begin
    psel = (req_i && (base_addr_i == (reg_addr & ~(AddrOffset - 1))));
    penable = req_i;
    pwrite = req_i;
    pwdata = req_i;
    pstrb = req_i;
    reg_addr = req_i;
  end

  // Decode register address
  always_comb begin
    reg_addr = req_i ? (base_addr_i - base_addr_i & ~(AddrOffset - 1)) : '0;
  end

  // Read-only and writable register handling
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i])
          reg_file[i] <= reg_init_i[i];
        else
          reg_file[i] <= '0;
      end
      pending_write <= '0;
      write_enable <= '0;
    end else if (psel && penable) begin
      if (pwrite) begin
        for (int i = 0; i < NoApbRegs; i++) begin
          if (reg_addr == i * AddrOffset && !ReadOnly[i]) begin
            for (int b = 0; b < ApbDataWidth / 8; b++) begin
              if (pstrb[b]) begin
                reg_file[i][(b + 1) * 8 - 1 -: 8] <= pwdata[(b + 1) * 8 - 1 -: 8];
              end
            end
          end
        end
      end
    end
  end

  // Drive APB response and register output
  always_comb begin
    resp_o = psel && penable;
    prdata = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (reg_addr == i * AddrOffset) begin
        prdata = ReadOnly[i] ? reg_init_i[i] : reg_file[i];
      end
    end
    reg_q_o = reg_file;
  end

endmodule
