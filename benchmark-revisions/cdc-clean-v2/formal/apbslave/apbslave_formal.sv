module apbslave_formal;
    reg PCLK;
    (* anyseq *) reg PRESETn, PSEL, PENABLE, PWRITE;
    (* anyseq *) reg [11:0] PADDR;
    (* anyseq *) reg [31:0] PWDATA;
    (* anyseq *) reg [3:0] PWSTRB;
    (* anyseq *) reg [2:0] PPROT;
    wire PREADY, PSLVERR;
    wire [31:0] PRDATA;

    apbslave dut (
        .PCLK(PCLK), .PRESETn(PRESETn), .PSEL(PSEL), .PENABLE(PENABLE),
        .PREADY(PREADY), .PADDR(PADDR), .PWRITE(PWRITE), .PWDATA(PWDATA),
        .PWSTRB(PWSTRB), .PPROT(PPROT), .PRDATA(PRDATA), .PSLVERR(PSLVERR));

    reg f_past_valid;
    initial begin
        f_past_valid = 0;
        assume(!PRESETn);
    end

    always @(posedge PCLK) begin
        f_past_valid <= 1;

        assume(!PENABLE || PSEL);
        if (f_past_valid && $past(PRESETn && PSEL && !PENABLE)) begin
            assume(PRESETn && PSEL && PENABLE);
            assume(PADDR == $past(PADDR));
            assume(PWRITE == $past(PWRITE));
            assume(PWDATA == $past(PWDATA));
            assume(PWSTRB == $past(PWSTRB));
            assume(PPROT == $past(PPROT));
        end
        if (f_past_valid && $past(PRESETn && PSEL && PENABLE && !PREADY)) begin
            assume(PRESETn && PSEL && PENABLE);
            assume({PADDR,PWRITE,PWDATA,PWSTRB,PPROT} ==
                   $past({PADDR,PWRITE,PWDATA,PWSTRB,PPROT}));
        end

        assert(!PSLVERR);
        if (!PRESETn)
            assert(!PREADY);
        if (f_past_valid && $past(PRESETn && PSEL && !PENABLE))
            assert(PREADY);
        if (PREADY)
            assert(PRESETn && PSEL && PENABLE);

        cover(PRESETn && PSEL && !PENABLE && PWRITE && PWSTRB != 0);
        cover(PREADY && PWRITE);
        cover(PREADY && !PWRITE);
    end
endmodule
