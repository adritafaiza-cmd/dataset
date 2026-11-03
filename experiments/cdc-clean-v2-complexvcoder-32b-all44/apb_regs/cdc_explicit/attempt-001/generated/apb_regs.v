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
  apb_addr_t                 addr;
  logic [$clog2(NoApbRegs)-1:0] reg_index;
  reg_data_t                 write_data;
  logic [ApbDataWidth/8-1:0] write_strobe;
  reg_data_t                 read_data;
  logic                      is_read_only;
  logic                      write_enabled;

  // Decode the address to find the register index
  always_comb begin
    addr = req_i.paddr - base_addr_i;
    reg_index = addr / AddrOffset;
    is_read_only = ReadOnly[reg_index];
    read_data = is_read_only ? reg_init_i[reg_index] : reg_file[reg_index];
  end

  // Determine write enable and data
  always_comb begin
    write_enabled = req_i.psel && req_i.penable && !is_read_only;
    write_data = req_i.pwdata;
    write_strobe = req_i.pstrb;
  end

  // Register file update logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        if (ReadOnly[i])
          reg_file[i] <= reg_init_i[i];
        else
          reg_file[i] <= '0;
      end
    end else if (write_enabled) begin
      for (int byte_index = 0; byte_index < ApbDataWidth/8; byte_index = byte_index + 1) begin
        if (write_strobe[byte_index]) begin
          reg_file[reg_index][byte_index*8 +: 8] <= write_data[byte_index*8 +: 8];
        end
      end
    end
  end

  // Drive the output ports
  assign resp_o.prdata = read_data;
  assign resp_o.pready = 1'b1; // Always ready for simplicity
  assign resp_o.pslverr = 1'b0; // No error
  assign reg_q_o = reg_file;

endmodule
