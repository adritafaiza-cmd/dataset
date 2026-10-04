module apbxclk_formal;
  localparam AW=6, DW=8;
  (* gclk *) reg gclk;
  reg [5:0] tick = 0;
  always @(posedge gclk) tick <= tick + 1'b1;
  wire S_APB_PCLK = tick[0];
  wire M_APB_PCLK = tick[1];
  wire S_PRESETn = (tick >= 8);
  (* anyseq *) reg S_APB_PSEL, S_APB_PENABLE, S_APB_PWRITE;
  (* anyseq *) reg [AW-1:0] S_APB_PADDR;
  (* anyseq *) reg [DW-1:0] S_APB_PWDATA;
  (* anyseq *) reg [DW/8-1:0] S_APB_PWSTRB;
  (* anyseq *) reg [2:0] S_APB_PPROT;
  (* anyseq *) reg M_APB_PREADY, M_APB_PSLVERR;
  (* anyseq *) reg [DW-1:0] M_APB_PRDATA;
  wire S_APB_PREADY, S_APB_PSLVERR, M_PRESETn;
  wire M_APB_PSEL, M_APB_PENABLE, M_APB_PWRITE;
  wire [AW-1:0] M_APB_PADDR;
  wire [DW-1:0] S_APB_PRDATA, M_APB_PWDATA;
  wire [DW/8-1:0] M_APB_PWSTRB;
  wire [2:0] M_APB_PPROT;
  apbxclk #(.C_APB_ADDR_WIDTH(AW), .C_APB_DATA_WIDTH(DW), .OPT_REGISTERED(1)) dut(.*);

  always @* begin
    if (tick < 10) begin
      assume(!S_APB_PSEL);
      assume(!S_APB_PENABLE);
    end
  end

  always @(posedge S_APB_PCLK) begin
    assume(!S_APB_PENABLE || S_APB_PSEL);
    if (S_PRESETn && $past(S_PRESETn && S_APB_PSEL && S_APB_PENABLE && !S_APB_PREADY))
      assume(S_APB_PSEL && S_APB_PENABLE &&
             $stable({S_APB_PWRITE, S_APB_PADDR, S_APB_PWDATA, S_APB_PWSTRB, S_APB_PPROT}));
    if (!S_PRESETn)
      assert(!S_APB_PREADY);
    if (S_APB_PREADY)
      assert(S_PRESETn && S_APB_PSEL && S_APB_PENABLE);
  end

  always @(posedge M_APB_PCLK) begin
    if (M_PRESETn)
      assert(!M_APB_PENABLE || M_APB_PSEL);
    if (M_PRESETn && $past(M_PRESETn && M_APB_PSEL && M_APB_PENABLE && !M_APB_PREADY))
      assert(M_APB_PSEL && M_APB_PENABLE &&
             $stable({M_APB_PWRITE, M_APB_PADDR, M_APB_PWDATA, M_APB_PWSTRB, M_APB_PPROT}));
  end

  always @(posedge gclk) begin
    cover(S_PRESETn && S_APB_PREADY);
    cover(M_PRESETn && M_APB_PSEL && M_APB_PENABLE && M_APB_PREADY);
  end
endmodule
