module async_bidir_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir,
       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_winc,
       input wire [DSIZE-1:0]  b_wdata,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty,
       input wire              b_dir
       );

    localparam DEPTH = 1 << ASIZE;

    reg [DSIZE-1:0] mem [0:DEPTH-1];

    reg [ASIZE:0] a_wr_ptr, a_wr_ptr_gray, a_wr_ptr_gray_sync, a_rd_ptr, a_rd_ptr_gray;
    reg [ASIZE:0] b_wr_ptr, b_wr_ptr_gray, b_wr_ptr_gray_sync, b_rd_ptr, b_rd_ptr_gray;

    // Gray code conversion functions
    function [ASIZE:0] bin_to_gray;
        input [ASIZE:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    function [ASIZE:0] gray_to_bin;
        input [ASIZE:0] gray;
        integer i;
        reg [ASIZE:0] bin;
        bin = gray;
        for (i = ASIZE; i > 0; i = i - 1)
            bin[i-1] = bin[i] ^ bin[i-1];
        gray_to_bin = bin;
    endfunction

    // a_clk domain
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_wr_ptr <= 0;
            a_rd_ptr <= 0;
        end else begin
            if (a_dir && !a_full) begin
                mem[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
                a_wr_ptr <= a_wr_ptr + 1;
            end
            if (!a_dir && !a_empty) begin
                a_rd_ptr <= a_rd_ptr + 1;
            end
        end
    end

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n)
            a_wr_ptr_gray <= 0;
        else
            a_wr_ptr_gray <= bin_to_gray(a_wr_ptr);
    end

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n)
            a_wr_ptr_gray_sync <= 0;
        else
            a_wr_ptr_gray_sync <= a_wr_ptr_gray;
    end

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n)
            a_rd_ptr_gray <= 0;
        else
            a_rd_ptr_gray <= bin_to_gray(a_rd_ptr);
    end

    // b_clk domain
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_wr_ptr <= 0;
            b_rd_ptr <= 0;
        end else begin
            if (b_dir && !b_full) begin
                mem[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
                b_wr_ptr <= b_wr_ptr + 1;
            end
            if (!b_dir && !b_empty) begin
                b_rd_ptr <= b_rd_ptr + 1;
            end
        end
    end

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n)
            b_wr_ptr_gray <= 0;
        else
            b_wr_ptr_gray <= bin_to_gray(b_wr_ptr);
    end

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n)
            b_wr_ptr_gray_sync <= 0;
        else
            b_wr_ptr_gray_sync <= b_wr_ptr_gray;
    end

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n)
            b_rd_ptr_gray <= 0;
        else
            b_rd_ptr_gray <= bin_to_gray(b_rd_ptr);
    end

    // a_clk domain flags
    assign a_full   = (a_wr_ptr_gray_sync[ASIZE:0] == {~a_wr_ptr_gray[ASIZE], a_wr_ptr_gray[ASIZE-1:0]});
    assign a_afull  = (a_wr_ptr_gray_sync[ASIZE:0] == {~a_wr_ptr_gray[ASIZE], a_wr_ptr_gray[ASIZE-1:0] + 1});
    assign a_empty  = (a_wr_ptr_gray[ASIZE:0] == a_rd_ptr_gray[ASIZE:0]);
    assign a_aempty = (a_wr_ptr_gray[ASIZE:0] == {a_rd_ptr_gray[ASIZE], a_rd_ptr_gray[ASIZE-1:0] + 1});

    // b_clk domain flags
    assign b_full   = (b_wr_ptr_gray_sync[ASIZE:0] == {~b_wr_ptr_gray[ASIZE], b_wr_ptr_gray[ASIZE-1:0]});
    assign b_afull  = (b_wr_ptr_gray_sync[ASIZE:0] == {~b_wr_ptr_gray[ASIZE], b_wr_ptr_gray[ASIZE-1:0] + 1});
    assign b_empty  = (b_wr_ptr_gray[ASIZE:0] == b_rd_ptr_gray[ASIZE:0]);
    assign b_aempty = (b_wr_ptr_gray[ASIZE:0] == {b_rd_ptr_gray[ASIZE], b_rd_ptr_gray[ASIZE-1:0] + 1});

    // a_clk domain read data
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n)
            a_rdata <= 0;
        else if (!a_dir && !a_empty)
            a_rdata <= mem[a_rd_ptr[ASIZE-1:0]];
    end

    // b_clk domain read data
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n)
            b_rdata <= 0;
        else if (!b_dir && !b_empty)
            b_rdata <= mem[b_rd_ptr[ASIZE-1:0]];
    end

endmodule
