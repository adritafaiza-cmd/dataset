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
  reg_data_t [NoApbRegs-1:0] reg_file;
  apb_addr_t                 addr;
  logic [$clog2(NoApbRegs)-1:0] reg_index;
  reg_data_t                 write_data;
  reg_data_t                 read_data;
  logic                      psel;
  logic                      penable;
  logic                      pwrite;
  logic [ApbDataWidth/8-1:0] pstrb;
  logic                      reg_valid;

  // Decode the APB request
  assign addr = req_i ? req_i.paddr : '0;
  assign reg_index = (addr - base_addr_i) / AddrOffset;
  assign reg_valid = (addr >= base_addr_i) && (addr < base_addr_i + NoApbRegs * AddrOffset);
  assign psel = req_i ? req_i.psel : 1'b0;
  assign penable = req_i ? req_i.penable : 1'b0;
  assign pwrite = req_i ? req_i.pwrite : 1'b0;
  assign pstrb = req_i ? req_i.pstrb : '0;
  assign write_data = req_i ? req_i.pwdata : '0;

  // Read data from the register file
  always_comb begin
    if (reg_valid && !pwrite) begin
      if (ReadOnly[reg_index])
        read_data = reg_init_i[reg_index];
      else
        read_data = reg_file[reg_index];
    end else begin
      read_data = '0;
    end
  end

  // Write data to the register file
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        if (!ReadOnly[i])
          reg_file[i] <= '0;
      end
    end else if (psel && penable && pwrite && reg_valid) begin
      for (int i = 0; i < ApbDataWidth/8; i = i + 1) begin
        if (pstrb[i] && i < RegDataWidth/8) begin
          reg_file[reg_index][i*8 +: 8] <= write_data[i*8 +: 8];
        end
      end
    end
  end

  // Drive the output ports
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      resp_o <= 0;
    end else if (psel && penable) begin
      resp_o <= 1;
    end else begin
      resp_o <= 0;
    end
  end

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q_o <= '0;
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
