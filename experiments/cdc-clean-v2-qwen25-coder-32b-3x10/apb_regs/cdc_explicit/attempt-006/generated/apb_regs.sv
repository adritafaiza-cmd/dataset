module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd0,
  parameter int unsigned        ApbAddrWidth = 32'd0,
  parameter int unsigned        AddrOffset   = 32'd4,
  parameter int unsigned        ApbDataWidth = 32'd0,
  parameter int unsigned        RegDataWidth = 32'd0,
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
  logic [ApbAddrWidth-1:0] addr;
  logic [NoApbRegs-1:0]    reg_sel;
  logic [RegDataWidth-1:0] reg_data;
  logic [ApbDataWidth-1:0] write_data;
  logic [ApbDataWidth/8-1:0] strb;
  logic                      psel;
  logic                      penable;
  logic                      pwrite;
  logic [ApbDataWidth-1:0] prdata;
  logic                      pslverr;

  // Decode the address
  assign addr = req_i.addr - base_addr_i;
  assign reg_sel = (addr < NoApbRegs * AddrOffset) ? (1 << (addr / AddrOffset)) : 0;

  // APB request signals
  assign psel = req_i.psel;
  assign penable = req_i.penable;
  assign pwrite = req_i.pwrite;
  assign write_data = req_i.pwdata;
  assign strb = req_i.pstrb;

  // Register file
  reg_data_t [NoApbRegs-1:0] reg_file;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i])
          reg_file[i] <= reg_init_i[i];
        else
          reg_file[i] <= '0;
      end
    end else if (psel && penable) begin
      if (pwrite) begin
        for (int i = 0; i < NoApbRegs; i++) begin
          if (reg_sel[i] && !ReadOnly[i]) begin
            for (int b = 0; b < ApbDataWidth/8; b++) begin
              if (strb[b]) begin
                reg_file[i][b*8 +: 8] <= write_data[b*8 +: 8];
              end
            end
          end
        end
      end
    end
  end

  // Read data
  always_comb begin
    prdata = '0;
    pslverr = 1'b0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (reg_sel[i]) begin
        prdata = reg_file[i];
        pslverr = 1'b0;
        break;
      end
    end
  end

  // APB response
  assign resp_o.prdata = prdata;
  assign resp_o.pslverr = pslverr;
  assign resp_o.pready = psel;

  // Output current register values
  assign reg_q_o = reg_file;

endmodule
