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
  apb_addr_t                 reg_addr;
  logic [AddrOffset-1:0]     reg_offset;
  logic [$clog2(NoApbRegs)-1:0] reg_index;
  logic [ApbDataWidth/8-1:0] write_strobe;
  reg_data_t                 write_data;
  reg_data_t                 read_data;
  logic                      psel;
  logic                      penable;
  logic                      pwrite;
  apb_addr_t                 paddr;
  reg_data_t                 pwdata;
  reg_data_t                 prdata;
  logic                      presp;
  logic                      pending_write;
  logic                      write_enable;

  // APB bus signals
  assign psel   = req_i;
  assign penable = req_i;
  assign pwrite  = req_i; // Simplified for this example, in real APB, pwrite is a separate signal
  assign paddr   = base_addr_i;
  assign pwdata  = '0;     // Simplified for this example, in real APB, pwdata is a separate signal

  // Decode address to determine register index and offset
  assign reg_addr    = paddr - base_addr_i;
  assign reg_index   = reg_addr / AddrOffset;
  assign reg_offset  = reg_addr % AddrOffset;
  assign write_strobe = '1; // Simplified for this example, in real APB, write_strobe is a separate signal

  // Read and write data
  assign read_data = reg_file[reg_index];

  // Write enable logic
  assign write_enable = psel && penable && pwrite && !ReadOnly[reg_index];

  // Update register file on write
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i = i + 1) begin
        if (ReadOnly[i])
          reg_file[i] <= reg_init_i[i];
        else
          reg_file[i] <= '0;
      end
    end else if (write_enable) begin
      for (int i = 0; i < ApbDataWidth/8; i = i + 1) begin
        if (write_strobe[i]) begin
          reg_file[reg_index][i*8 +: 8] <= pwdata[i*8 +: 8];
        end
      end
    end
  end

  // Output registered data
  always_ff @(posedge pclk_i) begin
    if (psel && penable && !pwrite) begin
      prdata <= read_data;
      presp  <= 1'b1;
    end else begin
      presp <= 1'b0;
    end
  end

  // Drive output ports
  assign resp_o = presp;
  assign reg_q_o = reg_file;

endmodule
