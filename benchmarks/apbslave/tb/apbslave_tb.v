`timescale 1ns/1ps

module apbslave_tb;
    integer errors = 0;

    reg PCLK = 0, PRESETn = 0, PSEL = 0, PENABLE = 0, PWRITE = 0;
    reg [11:0] PADDR = 0;
    reg [31:0] PWDATA = 0;
    reg [3:0] PWSTRB = 0;
    wire PREADY, PSLVERR;
    wire [31:0] PRDATA;
    always #5 PCLK = ~PCLK;

    apbslave dut (
        .PCLK(PCLK), .PRESETn(PRESETn), .PSEL(PSEL), .PENABLE(PENABLE),
        .PREADY(PREADY), .PADDR(PADDR), .PWRITE(PWRITE), .PWDATA(PWDATA),
        .PWSTRB(PWSTRB), .PPROT(3'b000), .PRDATA(PRDATA), .PSLVERR(PSLVERR)
    );

    task apb_write(input [11:0] addr, input [31:0] data);
        begin
            @(negedge PCLK);
            PSEL = 1; PENABLE = 0; PWRITE = 1; PADDR = addr;
            PWDATA = data; PWSTRB = 4'hF;
            @(posedge PCLK);
            @(negedge PCLK); PENABLE = 1;
            @(posedge PCLK);
            while (!PREADY) @(posedge PCLK);
            @(negedge PCLK);
            PSEL = 0; PENABLE = 0; PWRITE = 0;
        end
    endtask

    task apb_read(input [11:0] addr);
        begin
            @(negedge PCLK);
            PSEL = 1; PENABLE = 0; PWRITE = 0; PADDR = addr; PWSTRB = 0;
            @(posedge PCLK);
            @(negedge PCLK); PENABLE = 1;
            @(posedge PCLK);
            while (!PREADY) @(posedge PCLK);
            @(negedge PCLK);
            PSEL = 0; PENABLE = 0;
        end
    endtask

    initial begin
        repeat (3) @(posedge PCLK); PRESETn = 1;
        apb_write(12'h004, 32'h11223344);
        apb_read(12'h004);
        if (PRDATA !== 32'h11223344) begin
            $display("FAIL got %h", PRDATA);
            errors = errors + 1;
        end
        if (errors == 0) $display("APBSLAVE: ALL TESTS PASSED");
        else $display("APBSLAVE: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("APBSLAVE_TB: TIMEOUT");
        $finish;
    end
endmodule
