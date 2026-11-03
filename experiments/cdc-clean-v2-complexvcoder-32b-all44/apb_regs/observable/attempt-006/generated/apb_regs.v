module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd8,
  parameter int unsigned        ApbAddrWidth = 32'd16,
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
  logic [ApbDataWidth/8-1:0] write_strobe;
  logic [ApbDataWidth-1:0]   write_data;
  logic [ApbDataWidth-1:0]   read_data;
  apb_addr_t                 reg_addr;
  logic                      write_enable;
  logic                      read_enable;
  logic [$clog2(NoApbRegs)-1:0] selected_reg;
  logic                      pending_write;
  logic                      write_commit;

  // APB interface signals
  logic psel;
  logic penable;
  logic pwrite;
  logic [ApbDataWidth-1:0] prdata;
  logic [ApbDataWidth-1:0] pwdata;
  logic [ApbDataWidth/8-1:0] pstrb;

  // Decode APB address
  assign reg_addr = base_addr_i[ApbAddrWidth-1:AddrOffset];
  assign selected_reg = reg_addr[$clog2(NoApbRegs)-1:0];

  // APB interface signals
  assign psel = req_i;
  assign penable = req_i;
  assign pwrite = req_i;
  assign pwdata = write_data;
  assign pstrb = write_strobe;

  // Decode write strobe
  assign write_strobe = pstrb;

  // Read/Write enable signals
  assign write_enable = psel & penable & pwrite;
  assign read_enable = psel & penable & ~pwrite;

  // Write data
  assign write_data = pwdata;

  // Read data
  always_comb begin
    if (read_enable) begin
      read_data = ReadOnly[selected_reg] ? reg_init_i[selected_reg] : reg_file[selected_reg];
    end else begin
      read_data = '0;
    end
  end

  // Write commit signal
  assign write_commit = psel & penable & pwrite;

  // Register file update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        if (!ReadOnly[i]) begin
          reg_file[i] <= '0;
        end else begin
          reg_file[i] <= reg_init_i[i];
        end
      end
      pending_write <= 0;
    end else begin
      if (write_commit) begin
        if (!ReadOnly[selected_reg]) begin
          for (int i = 0; i < ApbDataWidth/8; i = i + 1) begin
            if (write_strobe[i]) begin
              reg_file[selected_reg][8*(i+1)-1:8*i] <= pwdata[8*(i+1)-1:8*i];
            end
          end
        end
      end
    end
  end

  // Response signal
  assign resp_o = psel & penable;

  // Output register values
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        reg_q_o[i] <= ReadOnly[i] ? reg_init_i[i] : reg_file[i];
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        reg_q_o[i] <= ReadOnly[i] ? reg_init_i[i] : reg_file[i];
      end
    end
  end

endmodule
