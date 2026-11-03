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

  localparam int unsigned RegAddrWidth = $clog2(NoApbRegs);

  reg_data_t [NoApbRegs-1:0] reg_file;
  apb_addr_t                 reg_addr;
  logic [RegAddrWidth-1:0]   reg_index;
  logic                      psel;
  logic                      penable;
  logic                      pwrite;
  logic [ApbDataWidth/8-1:0] pstrb;
  reg_data_t                 pwdata;
  reg_data_t                 prdata;
  logic                      reg_wr_en;
  reg_data_t                 reg_wr_data;
  reg_data_t                 reg_rd_data;

  // Decode APB signals
  assign reg_addr = (req_i.addr - base_addr_i) / AddrOffset;
  assign reg_index = reg_addr[RegAddrWidth-1:0];
  assign psel = req_i.psel;
  assign penable = req_i.penable;
  assign pwrite = req_i.pwrite;
  assign pstrb = req_i.pstrb;
  assign pwdata = req_i.pwdata;

  // Write enable generation
  assign reg_wr_en = psel && penable && pwrite;

  // Write data generation with byte-wise update
  genvar i;
  generate
    for (i = 0; i < ApbDataWidth/8; i = i + 1) begin : gen_byte_update
      assign reg_wr_data[i*8 +: 8] = pstrb[i] ? pwdata[i*8 +: 8] : reg_file[reg_index][i*8 +: 8];
    end
  endgenerate

  // Register file update
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int j = 0; j < NoApbRegs; j = j + 1) begin
        if (ReadOnly[j])
          reg_file[j] <= reg_init_i[j];
        else
          reg_file[j] <= '0;
      end
    end else if (reg_wr_en && !ReadOnly[reg_index]) begin
      reg_file[reg_index] <= reg_wr_data;
    end
  end

  // Read data generation
  assign reg_rd_data = reg_file[reg_index];

  // Response generation
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      resp_o <= 1'b0;
    end else if (psel && penable) begin
      resp_o <= 1'b1;
    end else begin
      resp_o <= 1'b0;
    end
  end

  // Output the current state of the register file
  assign reg_q_o = reg_file;

endmodule
