`include "apb/typedef.svh"

module apb_regs_wrap (
    input  logic        pclk_i,
    input  logic        preset_ni,
    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    input  logic [31:0] paddr,
    input  logic [31:0] pwdata,
    input  logic [3:0]  pstrb,
    output logic        pready,
    output logic [31:0] prdata,
    output logic        pslverr,
    input  logic [31:0] base_addr_i
);
    typedef logic [31:0] addr_t;
    typedef logic [31:0] data_t;
    typedef logic [3:0]  strb_t;
    `APB_TYPEDEF_REQ_T(apb_req_t, addr_t, data_t, strb_t)
    `APB_TYPEDEF_RESP_T(apb_resp_t, data_t)

    apb_req_t  req;
    apb_resp_t resp;
    logic [1:0][15:0] regs;

    assign req.paddr   = paddr;
    assign req.pprot   = 3'b000;
    assign req.psel    = psel;
    assign req.penable = penable;
    assign req.pwrite  = pwrite;
    assign req.pwdata  = pwdata;
    assign req.pstrb   = pstrb;
    assign pready      = resp.pready;
    assign prdata      = resp.prdata;
    assign pslverr     = resp.pslverr;

    apb_regs #(
        .NoApbRegs(2),
        .ApbAddrWidth(32),
        .AddrOffset(4),
        .ApbDataWidth(32),
        .RegDataWidth(16),
        .ReadOnly(2'b00),
        .req_t(apb_req_t),
        .resp_t(apb_resp_t)
    ) i_regs (
        .pclk_i(pclk_i),
        .preset_ni(preset_ni),
        .req_i(req),
        .resp_o(resp),
        .base_addr_i(base_addr_i),
        .reg_init_i({16'h0000, 16'h0000}),
        .reg_q_o(regs)
    );
endmodule
