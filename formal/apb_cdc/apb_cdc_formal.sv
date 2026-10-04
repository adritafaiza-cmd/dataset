module apb_cdc_formal;
  localparam AW=6, DW=8;
  (* gclk *) reg gclk;
  reg [5:0] tick = 0;
  always @(posedge gclk) tick <= tick + 1'b1;
  wire src_pclk_i = tick[0];
  wire dst_pclk_i = tick[1];
  wire src_preset_ni = (tick >= 8);
  wire dst_preset_ni = (tick >= 8);
  (* anyseq *) reg src_psel_i, src_penable_i, src_pwrite_i;
  (* anyseq *) reg [AW-1:0] src_paddr_i;
  (* anyseq *) reg [DW-1:0] src_pwdata_i;
  (* anyseq *) reg [DW/8-1:0] src_pstrb_i;
  (* anyseq *) reg [2:0] src_pprot_i;
  (* anyseq *) reg dst_pready_i, dst_pslverr_i;
  (* anyseq *) reg [DW-1:0] dst_prdata_i;
  wire src_pready_o, src_pslverr_o, dst_psel_o, dst_penable_o, dst_pwrite_o;
  wire [DW-1:0] src_prdata_o, dst_pwdata_o;
  wire [AW-1:0] dst_paddr_o;
  wire [DW/8-1:0] dst_pstrb_o;
  wire [2:0] dst_pprot_o;
  apb_cdc #(.ADDR_WIDTH(AW), .DATA_WIDTH(DW), .LOG_DEPTH(1)) dut(.*);

  always @* begin
    if (tick < 10) begin
      assume(!src_psel_i);
      assume(!src_penable_i);
    end
  end

  always @(posedge src_pclk_i) begin
    assume(!src_penable_i || src_psel_i);
    if (src_preset_ni && $past(src_preset_ni && src_psel_i && src_penable_i && !src_pready_o))
      assume(src_psel_i && src_penable_i &&
             $stable({src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}));
    if (!src_preset_ni)
      assert(!src_pready_o);
  end

  always @(posedge dst_pclk_i) begin
    if (dst_preset_ni)
      assert(!dst_penable_o || dst_psel_o);
    if (dst_preset_ni && $past(dst_preset_ni && dst_psel_o && dst_penable_o && !dst_pready_i))
      assert(dst_psel_o && dst_penable_o &&
             $stable({dst_pwrite_o, dst_paddr_o, dst_pwdata_o, dst_pstrb_o, dst_pprot_o}));
  end

  always @(posedge gclk) begin
    cover(src_preset_ni && src_pready_o);
    cover(dst_preset_ni && dst_psel_o && dst_penable_o && dst_pready_i);
  end
endmodule
