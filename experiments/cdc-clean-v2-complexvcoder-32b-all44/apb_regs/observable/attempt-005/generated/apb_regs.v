module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd8,
  parameter int unsigned        ApbAddrWidth = 32'd8,
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
  reg_data_t [NoApbRegs-1:0] reg_q;
  logic                      write_enable;
  logic                      read_enable;
  logic [NoApbRegs-1:0]      reg_addr;
  reg_data_t                 reg_data_in;
  reg_data_t                 reg_data_out;
  logic                      psel;
  logic                      penable;
  logic                      pwrite;
  apb_addr_t                 paddr;
  reg_data_t                 pwdata;
  logic [ApbDataWidth/8-1:0] pstrb;
  reg_data_t                 prdata;
  logic                      pready;
  logic                      pslverr;

  // Decode APB address
  assign reg_addr = (paddr - base_addr_i) / AddrOffset;

  // APB signals
  assign psel    = req_i;
  assign penable = req_i;
  assign pwrite  = req_i;
  assign paddr   = base_addr_i;
  assign pwdata  = reg_data_in;
  assign pstrb   = '1; // Assuming all bytes are always strobed for simplicity

  // Read/Write control
  assign read_enable  = psel & !pwrite & penable;
  assign write_enable = psel & pwrite & penable;

  // APB handshake
  assign pready  = psel & penable;
  assign pslverr = 1'b0; // No error support
  assign resp_o  = pready;

  // Read data output
  always_comb begin
    reg_data_out = reg_q[reg_addr];
    if (ReadOnly[reg_addr])
      reg_data_out = reg_init_i[reg_addr];
  end

  // Write data input
  always_comb begin
    reg_data_in = pwdata;
    for (int i = 0; i < ApbDataWidth/8; i++) begin
      if (!pstrb[i])
        reg_data_in[8*i +: 8] = reg_q[reg_addr][8*i +: 8];
    end
  end

  // Register file update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i])
          reg_q[i] <= reg_init_i[i];
        else
          reg_q[i] <= '0;
      end
    end else if (write_enable && !ReadOnly[reg_addr]) begin
      reg_q[reg_addr] <= reg_data_in;
    end
  end

  // Output registered data
  assign reg_q_o = reg_q;

endmodule
