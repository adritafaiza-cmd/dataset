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

  // APB signals
  logic        psel;
  logic        penable;
  logic        pwrite;
  logic [ApbAddrWidth-1:0] paddr;
  logic [ApbDataWidth-1:0] pwdata;
  logic [3:0]  pstrb;
  logic        pready;
  logic [ApbDataWidth-1:0] prdata;
  logic [1:0]  pslverr;

  // Decode APB request
  assign psel    = req_i[0];
  assign penable = req_i[1];
  assign pwrite  = req_i[2];
  assign paddr   = req_i[3 +: ApbAddrWidth];
  assign pwdata  = req_i[3 + ApbAddrWidth +: ApbDataWidth];
  assign pstrb   = req_i[3 + ApbAddrWidth + ApbDataWidth +: 4];

  // Response
  assign resp_o = {pslverr, pready, prdata};

  // Address decoding
  logic [ApbAddrWidth-1:0] offset_addr;
  logic [ApbAddrWidth-1:0] reg_index;
  logic                    addr_valid;

  assign offset_addr = paddr - base_addr_i;
  assign reg_index   = offset_addr / AddrOffset;
  assign addr_valid  = (reg_index < NoApbRegs) && (offset_addr % AddrOffset == 0);

  // Register file
  reg_data_t [NoApbRegs-1:0] reg_q;

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        reg_q[i] <= reg_init_i[i];
      end
    end else begin
      if (psel && penable && pwrite && addr_valid) begin
        for (int i = 0; i < NoApbRegs; i++) begin
          if (i == reg_index) begin
            if (ReadOnly[i]) begin
              reg_q[i] <= reg_q[i];
            end else begin
              // Apply byte strobes
              for (int b = 0; b < RegDataWidth/8; b++) begin
                if (pstrb[b]) begin
                  reg_q[i][b*8 +: 8] <= pwdata[b*8 +: 8];
                end
              end
            end
          end
        end
      end
    end
  end

  assign reg_q_o = reg_q;

  // Read data
  always_comb begin
    if (psel && !pwrite && addr_valid) begin
      prdata = reg_q[reg_index];
    end else begin
      prdata = '0;
    end
  end

  // Ready and error
  assign pready  = 1'b1;
  assign pslverr = 2'b00;

endmodule
