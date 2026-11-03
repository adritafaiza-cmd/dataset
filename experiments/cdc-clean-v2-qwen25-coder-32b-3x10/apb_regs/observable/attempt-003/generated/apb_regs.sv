module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd4,
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

  // Internal register file
  reg_data_t [NoApbRegs-1:0] reg_file;
  reg_data_t                 reg_next;
  logic [NoApbRegs-1:0]      reg_write_en;
  logic [NoApbRegs-1:0]      reg_read_en;
  logic [ApbDataWidth-1:0]   reg_data_out;
  logic [ApbDataWidth-1:0]   reg_data_in;
  logic [ApbDataWidth/8-1:0] pstrb;
  logic                      psel;
  logic                      penable;
  logic [ApbAddrWidth-1:0]   paddr;
  logic [ApbDataWidth-1:0]   pwdata;
  logic                      pwrite;

  // Decode APB request
  assign psel    = req_i.psel;
  assign penable = req_i.penable;
  assign paddr   = req_i.paddr;
  assign pwdata  = req_i.pwdata;
  assign pstrb   = req_i.pstrb;
  assign pwrite  = req_i.pwrite;

  // Decode address to register index
  logic [$clog2(NoApbRegs)-1:0] reg_index;
  assign reg_index = (paddr - base_addr_i) / AddrOffset;

  // Read enable logic
  always_comb begin
    reg_read_en = '0;
    if (psel && !penable && !pwrite) begin
      reg_read_en[reg_index] = 1'b1;
    end
  end

  // Write enable logic
  always_comb begin
    reg_write_en = '0;
    if (psel && penable && pwrite) begin
      reg_write_en[reg_index] = 1'b1;
    end
  end

  // Byte-wise write data selection
  always_comb begin
    reg_data_in = reg_file[reg_index];
    for (int i = 0; i < ApbDataWidth/8; i++) begin
      if (pstrb[i]) begin
        reg_data_in[i*8 +: 8] = pwdata[i*8 +: 8];
      end
    end
  end

  // Register file update logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_file <= '0;
    end else if (psel && penable) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (reg_write_en[i] && !ReadOnly[i]) begin
          reg_file[i] <= reg_data_in;
        end
      end
    end
  end

  // Output register data
  always_comb begin
    reg_data_out = '0;
    if (reg_read_en[reg_index]) begin
      if (ReadOnly[reg_index]) begin
        reg_data_out = reg_init_i[reg_index];
      end else begin
        reg_data_out = reg_file[reg_index];
      end
    end
  end

  // Output response
  always_comb begin
    resp_o.prdata = reg_data_out;
    resp_o.pready = 1'b1;
    resp_o.pslverr = 1'b0;
  end

  // Output register values
  always_comb begin
    reg_q_o = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (ReadOnly[i]) begin
        reg_q_o[i] = reg_init_i[i];
      end else begin
        reg_q_o[i] = reg_file[i];
      end
    end
  end

endmodule
