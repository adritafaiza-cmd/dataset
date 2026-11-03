module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd8,
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

  reg_data_t [NoApbRegs-1:0] reg_file;
  logic [NoApbRegs-1:0]      write_enable;
  reg_data_t                 write_data;
  reg_data_t                 read_data;
  apb_addr_t                 address;
  logic [ApbDataWidth/8-1:0] write_strobe;
  logic                      write_commit;
  logic                      psel;
  logic                      penable;
  logic                      pwrite;
  apb_addr_t                 paddr;
  reg_data_t                 pwdata;
  reg_data_t                 prdata;
  logic                      pready;
  logic                      pslverr;
  logic [$clog2(NoApbRegs)-1:0] reg_index;

  // APB interface decoding and control signals
  assign address = paddr - base_addr_i;
  assign psel    = (address >= 0) && (address < (NoApbRegs * AddrOffset));
  assign pwrite  = req_i;
  assign paddr   = paddr;
  assign pwdata  = pwdata;
  assign write_strobe = pwdata[ApbDataWidth/8-1:0];
  assign write_commit = psel & penable & pwrite;

  // Register file read and write logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i])
          reg_file[i] <= reg_init_i[i];
        else
          reg_file[i] <= '0;
      end
    end else if (write_commit) begin
      reg_index = address / AddrOffset;
      if (!ReadOnly[reg_index]) begin
        for (int byte_idx = 0; byte_idx < ApbDataWidth/8; byte_idx++) begin
          if (write_strobe[byte_idx]) begin
            reg_file[reg_index][byte_idx*8 +: 8] <= pwdata[byte_idx*8 +: 8];
          end
        end
      end
    end
  end

  // Read operation
  always_comb begin
    reg_index = address / AddrOffset;
    if (psel & penable & !pwrite) begin
      read_data = reg_file[reg_index];
    end else begin
      read_data = '0;
    end
  end

  // APB response
  assign prdata = read_data;
  assign pready = psel & penable;
  assign pslverr = 1'b0;
  assign resp_o = pready;

  // Output the register file state
  assign reg_q_o = reg_file;

endmodule
