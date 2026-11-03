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
  int unsigned               reg_index;
  reg_data_t                 write_data;
  reg_data_t                 read_data;
  logic [NoApbRegs-1:0]      write_enable;
  logic                      psel;
  logic                      penable;
  logic                      pwrite;
  logic [ApbDataWidth/8-1:0] pstrb;
  logic                      pready;

  // Decode APB address
  always_comb begin
    reg_addr = req_i ? req_i.paddr - base_addr_i : '0;
    reg_index = reg_addr / AddrOffset;
    psel = req_i.psel && (reg_addr >= base_addr_i) && (reg_addr < base_addr_i + NoApbRegs * AddrOffset);
  end

  // APB signals
  always_comb begin
    penable = psel && req_i.penable;
    pwrite = psel && req_i.pwrite;
    pstrb = psel ? req_i.pstrb : '0;
    pready = psel;
    resp_o = pready;
  end

  // Write data generation
  always_comb begin
    write_data = '0;
    for (int i = 0; i < ApbDataWidth/8; i++) begin
      if (pstrb[i]) begin
        write_data[i*8 +: 8] = req_i.pwdata[i*8 +: 8];
      end
    end
  end

  // Read data selection
  always_comb begin
    if (reg_index < NoApbRegs) begin
      if (ReadOnly[reg_index])
        read_data = reg_init_i[reg_index];
      else
        read_data = reg_file[reg_index];
    end else begin
      read_data = '0;
    end
  end

  // Register file update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (!ReadOnly[i])
          reg_file[i] <= '0;
      end
    end else if (penable && pwrite) begin
      if (reg_index < NoApbRegs && !ReadOnly[reg_index]) begin
        for (int i = 0; i < ApbDataWidth/8; i++) begin
          if (pstrb[i])
            reg_file[reg_index][i*8 +: 8] <= write_data[i*8 +: 8];
        end
      end
    end
  end

  // Output current register values
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i])
          reg_q_o[i] <= reg_init_i[i];
        else
          reg_q_o[i] <= reg_file[i];
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i])
          reg_q_o[i] <= reg_init_i[i];
      end
    end
  end

endmodule
