module apb_regs_formal;
  // Drive an actual clock net across the Slang/native frontend boundary.
  // A native-only (* gclk *) register does not clock the separately elaborated DUT.
  reg pclk_i = 0;
  always @($global_clock) pclk_i <= ~pclk_i;
  (* anyseq *) reg preset_ni, psel, penable, pwrite;
  (* anyseq *) reg [31:0] paddr, pwdata;
  (* anyseq *) reg [3:0] pstrb;
  wire pready, pslverr;
  wire [31:0] prdata, regs;
  apb_regs_formal_dut dut (
    .pclk_i(pclk_i), .preset_ni(preset_ni),
    .psel(psel), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .pready(pready), .prdata(prdata), .pslverr(pslverr),
    .base_addr_i(32'b0), .regs_o(regs)
  );
  reg f_past_valid = 0;
  reg full_write_pending;
  reg [15:0] full_write_data;
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      f_past_valid <= 0;
      full_write_pending <= 0;
      full_write_data <= 0;
    end else begin
      f_past_valid <= 1;
      full_write_pending <= psel && penable && pwrite && paddr == 0 && pstrb[1:0] == 2'b11;
      full_write_data <= pwdata[15:0];
    end
  end
  reg [15:0] expected0, expected1;
  reg [3:0] writes, reads;
  initial assume(!preset_ni);
  always @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      expected0 <= 0; expected1 <= 0; writes <= 0; reads <= 0;
    end else begin
      if (psel && penable && pwrite) begin
        writes <= writes + 1'b1;
        // The address decoder maps each complete four-byte address range.
        if (paddr < 4) begin
          if (pstrb[0]) expected0[7:0] <= pwdata[7:0];
          if (pstrb[1]) expected0[15:8] <= pwdata[15:8];
        end
        if (paddr >= 4 && paddr < 8) begin
          if (pstrb[0]) expected1[7:0] <= pwdata[7:0];
          if (pstrb[1]) expected1[15:8] <= pwdata[15:8];
        end
      end
      if (psel && penable && !pwrite) reads <= reads + 1'b1;
    end
  end
  always @(posedge pclk_i) begin
    assume(!penable || psel);
    if (f_past_valid && $past(preset_ni && psel && !penable))
      assume(preset_ni && psel && penable && $stable({paddr,pwrite,pwdata,pstrb}));
    if (f_past_valid && $past(preset_ni && psel && penable && !pready))
      assume(preset_ni && psel && penable && $stable({paddr,pwrite,pwdata,pstrb}));
    if (f_past_valid && preset_ni) begin
      assert(pready == (psel && penable));
      assert(regs[15:0] == expected0);
      assert(regs[31:16] == expected1);
      if (psel && penable && !pwrite) begin
        if (paddr < 4) assert(prdata == {16'b0,expected0});
        if (paddr >= 4 && paddr < 8) assert(prdata == {16'b0,expected1});
      end
      // An intervening asynchronous reset cancels the previous write.
      if (full_write_pending) assert(regs[15:0] == full_write_data);
      cover(writes >= 2 && reads >= 1);
      cover(psel && penable && pwrite && paddr < 4 && pstrb[1:0] == 2'b01);
    end
  end
endmodule
