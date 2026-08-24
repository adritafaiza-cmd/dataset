`timescale 1ns/1ps

module apb_cdc_tb;
    integer errors = 0;

    reg src_pclk = 0, dst_pclk = 0, src_rst_n = 0, dst_rst_n = 0;
    always #5 src_pclk = ~src_pclk;
    always #8 dst_pclk = ~dst_pclk;

    reg src_psel = 0, src_penable = 0, src_pwrite = 0;
    reg [7:0] src_paddr = 0;
    reg [31:0] src_pwdata = 0;
    wire src_pready;
    wire [31:0] src_prdata;
    wire src_pslverr;
    wire dst_psel, dst_penable, dst_pwrite;
    wire [7:0] dst_paddr;
    wire [31:0] dst_pwdata;
    wire dst_pready = 1'b1;
    wire [31:0] dst_prdata;
    wire dst_pslverr = 1'b0;

    reg [31:0] mem [0:15];
    integer i;
    initial for (i = 0; i < 16; i = i + 1) mem[i] = 32'h0;

    always @(posedge dst_pclk) begin
        if (dst_psel && dst_penable && dst_pwrite)
            mem[dst_paddr[5:2]] <= dst_pwdata;
    end
    assign dst_prdata = mem[dst_paddr[5:2]];

    apb_cdc #(.ADDR_WIDTH(8), .DATA_WIDTH(32), .LOG_DEPTH(1)) dut (
        .src_pclk_i(src_pclk), .src_preset_ni(src_rst_n),
        .src_psel_i(src_psel), .src_penable_i(src_penable), .src_pwrite_i(src_pwrite),
        .src_paddr_i(src_paddr), .src_pwdata_i(src_pwdata),
        .src_pstrb_i(4'hF), .src_pprot_i(3'b000),
        .src_pready_o(src_pready), .src_prdata_o(src_prdata), .src_pslverr_o(src_pslverr),
        .dst_pclk_i(dst_pclk), .dst_preset_ni(dst_rst_n),
        .dst_psel_o(dst_psel), .dst_penable_o(dst_penable), .dst_pwrite_o(dst_pwrite),
        .dst_paddr_o(dst_paddr), .dst_pwdata_o(dst_pwdata),
        .dst_pstrb_o(), .dst_pprot_o(),
        .dst_pready_i(dst_pready), .dst_prdata_i(dst_prdata), .dst_pslverr_i(dst_pslverr)
    );

    task apb_write;
        input [7:0] addr;
        input [31:0] data;
        begin
            @(negedge src_pclk);
            src_paddr = addr; src_pwdata = data; src_pwrite = 1; src_psel = 1; src_penable = 0;
            @(negedge src_pclk);
            src_penable = 1;
            while (!src_pready) @(negedge src_pclk);
            src_psel = 0; src_penable = 0; src_pwrite = 0;
        end
    endtask

    task apb_read;
        input [7:0] addr;
        output [31:0] data;
        begin
            @(negedge src_pclk);
            src_paddr = addr; src_pwrite = 0; src_psel = 1; src_penable = 0;
            @(negedge src_pclk);
            src_penable = 1;
            while (!src_pready) @(negedge src_pclk);
            data = src_prdata;
            src_psel = 0; src_penable = 0;
        end
    endtask

    reg [31:0] rdata;
    initial begin
        repeat (4) @(posedge src_pclk); src_rst_n = 1;
        repeat (4) @(posedge dst_pclk); dst_rst_n = 1;
        repeat (4) @(posedge src_pclk);
        apb_write(8'h04, 32'hA5A5_1234);
        apb_read(8'h04, rdata);
        if (rdata !== 32'hA5A5_1234) begin
            $display("FAIL APB CDC readback %h", rdata);
            errors = errors + 1;
        end
        if (src_pslverr !== 1'b0)
            errors = errors + 1;
        if (errors == 0)
            $display("APB CDC: ALL TESTS PASSED");
        else
            $display("APB CDC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #80000;
        $display("APB CDC: TIMEOUT");
        $finish;
    end
endmodule
