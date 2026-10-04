module uart16550_formal;
  reg wb_clk_i;
  (* anyseq *) reg wb_rst_i, wb_we_i, wb_stb_i, wb_cyc_i;
  (* anyseq *) reg [2:0] wb_adr_i;
  (* anyseq *) reg [7:0] wb_dat_i;
  (* anyseq *) reg [3:0] wb_sel_i;
  (* anyseq *) reg srx_pad_i, cts_pad_i, dsr_pad_i, ri_pad_i, dcd_pad_i;
  wire [7:0] wb_dat_o;
  wire wb_ack_o, int_o, stx_pad_o, rts_pad_o, dtr_pad_o;

  uart_top dut (
      .wb_clk_i(wb_clk_i), .wb_rst_i(wb_rst_i), .wb_adr_i(wb_adr_i),
      .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o), .wb_we_i(wb_we_i),
      .wb_stb_i(wb_stb_i), .wb_cyc_i(wb_cyc_i), .wb_ack_o(wb_ack_o),
      .wb_sel_i(wb_sel_i), .int_o(int_o), .stx_pad_o(stx_pad_o),
      .srx_pad_i(srx_pad_i), .rts_pad_o(rts_pad_o), .cts_pad_i(cts_pad_i),
      .dtr_pad_o(dtr_pad_o), .dsr_pad_i(dsr_pad_i), .ri_pad_i(ri_pad_i),
      .dcd_pad_i(dcd_pad_i));

  reg f_past_valid;
  initial begin
    f_past_valid = 0;
    assume(wb_rst_i);
  end

  always @(posedge wb_clk_i) begin
    f_past_valid <= 1;
    assume(!wb_stb_i || wb_cyc_i);
    if (!wb_rst_i && f_past_valid && $past(!wb_rst_i && wb_stb_i && wb_cyc_i && !wb_ack_o))
      assume(wb_stb_i && wb_cyc_i && $stable({wb_adr_i, wb_dat_i, wb_we_i, wb_sel_i}));
    if (wb_rst_i)
      assert(!wb_ack_o);
    if (wb_ack_o)
      assert(!wb_rst_i && wb_cyc_i && wb_stb_i);
    if (f_past_valid && $past(wb_ack_o) && !wb_rst_i)
      assert(!wb_ack_o);
    cover(!wb_rst_i && wb_ack_o && wb_we_i);
    cover(!wb_rst_i && wb_ack_o && !wb_we_i);
  end
endmodule
