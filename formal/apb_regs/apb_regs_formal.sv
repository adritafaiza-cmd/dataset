`include "apb/typedef.svh"

module apb_regs_formal;
  (* gclk *) reg pclk_i;
  (* anyseq *) reg preset_ni, psel, penable, pwrite;
  (* anyseq *) reg [31:0] paddr, pwdata;
  (* anyseq *) reg [3:0] pstrb;
  wire pready, pslverr;
  wire [31:0] prdata;
  wire [31:0] base_addr_i = 32'h0;

  typedef logic [31:0] addr_t;
  typedef logic [31:0] data_t;
  typedef logic [3:0] strb_t;
  `APB_TYPEDEF_REQ_T(apb_req_t, addr_t, data_t, strb_t)
  `APB_TYPEDEF_RESP_T(apb_resp_t, data_t)

  apb_req_t req;
  apb_resp_t resp;
  logic [1:0][15:0] regs;

  assign req.paddr = paddr;
  assign req.pprot = 3'b000;
  assign req.psel = psel;
  assign req.penable = penable;
  assign req.pwrite = pwrite;
  assign req.pwdata = pwdata;
  assign req.pstrb = pstrb;
  assign pready = resp.pready;
  assign prdata = resp.prdata;
  assign pslverr = resp.pslverr;

  apb_regs #(
      .NoApbRegs(2),
      .ApbAddrWidth(32),
      .AddrOffset(4),
      .ApbDataWidth(32),
      .RegDataWidth(16),
      .ReadOnly(2'b00),
      .req_t(apb_req_t),
      .resp_t(apb_resp_t)
  ) dut (
      .pclk_i(pclk_i),
      .preset_ni(preset_ni),
      .req_i(req),
      .resp_o(resp),
      .base_addr_i(base_addr_i),
      .reg_init_i({16'h0000, 16'h0000}),
      .reg_q_o(regs)
  );

  reg f_past_valid;
  initial begin
    f_past_valid = 0;
    assume(!preset_ni);
  end

  always @(posedge pclk_i) begin
    f_past_valid <= 1;
    assume(!penable || psel);
    if (f_past_valid && $past(preset_ni && psel && !penable))
      assume(preset_ni && psel && penable && $stable({paddr, pwrite, pwdata, pstrb}));
    if (f_past_valid && $past(preset_ni && psel && penable && !pready))
      assume(preset_ni && psel && penable && $stable({paddr, pwrite, pwdata, pstrb}));
    if (f_past_valid && preset_ni)
      assert(resp.pready == (psel && penable));
    if (f_past_valid && $past(preset_ni && psel && penable && pwrite &&
                              paddr[7:0] == 8'h00 && pstrb[1:0] == 2'b11))
      assert(regs[0] == $past(pwdata[15:0]));
    cover(preset_ni && psel && penable && pwrite);
    cover(preset_ni && psel && penable && !pwrite);
  end
endmodule
