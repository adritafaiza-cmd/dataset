`timescale 1ns/1ps
`include "apb/typedef.svh"

module apb_regs_tb;
    typedef logic [31:0] addr_t;
    typedef logic [31:0] data_t;
    typedef logic [3:0]  strb_t;
    `APB_TYPEDEF_REQ_T(apb_req_t, addr_t, data_t, strb_t)
    `APB_TYPEDEF_RESP_T(apb_resp_t, data_t)

    logic clk = 0, rst_n = 0;
    apb_req_t req;
    apb_resp_t resp;
    logic [1:0][15:0] regs;
    integer errors = 0;
    always #5 clk = ~clk;

    apb_regs #(
        .NoApbRegs(2), .ApbAddrWidth(32), .AddrOffset(4),
        .ApbDataWidth(32), .RegDataWidth(16), .ReadOnly(2'b00),
        .req_t(apb_req_t), .resp_t(apb_resp_t)
    ) dut (
        .pclk_i(clk), .preset_ni(rst_n), .req_i(req), .resp_o(resp),
        .base_addr_i(32'h0000_0000),
        .reg_init_i({16'h0000, 16'h0000}),
        .reg_q_o(regs)
    );

    task automatic apb_write(input addr_t addr, input data_t data);
        req = '{paddr: addr, pprot: 3'b000, psel: 1'b1, penable: 1'b0,
                pwrite: 1'b1, pwdata: data, pstrb: 4'hF};
        @(posedge clk);
        req.penable = 1'b1;
        @(posedge clk);
        while (!resp.pready) @(posedge clk);
        req = '0;
    endtask

    task automatic apb_read(input addr_t addr, output data_t data);
        req = '{paddr: addr, pprot: 3'b000, psel: 1'b1, penable: 1'b0,
                pwrite: 1'b0, pwdata: '0, pstrb: 4'h0};
        @(posedge clk);
        req.penable = 1'b1;
        @(posedge clk);
        while (!resp.pready) @(posedge clk);
        data = resp.prdata;
        req = '0;
    endtask

    data_t rdata;
    initial begin
        req = '0;
        repeat (3) @(posedge clk); rst_n = 1;
        apb_write(32'h0, 32'h0000_A5A5);
        apb_read(32'h0, rdata);
        if (rdata[15:0] !== 16'hA5A5) begin
            $display("FAIL readback %h", rdata);
            errors = errors + 1;
        end
        if (errors == 0) $display("APB REGS: ALL TESTS PASSED");
        else $display("APB REGS: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("APB_REGS_TB: TIMEOUT");
        $finish;
    end
endmodule
