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
    localparam AFULL_THRESHOLD = DEPTH - 2;

    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // a-side signals
    reg [ASIZE:0] a_wr_ptr, a_wr_ptr_gray, a_wr_ptr_gray_nxt;
    reg [ASIZE:0] a_rd_ptr, a_rd_ptr_gray, a_rd_ptr_gray_nxt;
    reg [DSIZE-1:0] a_rdata_reg;

    // b-side signals
    reg [ASIZE:0] b_wr_ptr, b_wr_ptr_gray, b_wr_ptr_gray_nxt;
    reg [ASIZE:0] b_rd_ptr, b_rd_ptr_gray, b_rd_ptr_gray_nxt;
    reg [DSIZE-1:0] b_rdata_reg;

    // Binary to Gray conversion
    function [ASIZE:0] bin_to_gray;
        input [ASIZE:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary conversion
    function [ASIZE:0] gray_to_bin;
        input [ASIZE:0] gray;
        integer i;
        reg [ASIZE:0] bin;
        bin = gray;
        for (i = ASIZE-1; i > 0; i = i - 1) begin
            bin[i-1] = bin[i] ^ bin[i-1];
        end
        gray_to_bin = bin;
    endfunction

    // a-side write and read pointers
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_wr_ptr <= 0;
            a_wr_ptr_gray <= 0;
        end else if (a_dir && !a_full) begin
            a_wr_ptr <= a_wr_ptr + 1;
            a_wr_ptr_gray <= bin_to_gray(a_wr_ptr + 1);
        end
    end

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_rd_ptr <= 0;
            a_rd_ptr_gray <= 0;
        end else if (!a_dir && !a_empty) begin
            a_rd_ptr <= a_rd_ptr + 1;
            a_rd_ptr_gray <= bin_to_gray(a_rd_ptr + 1);
        end
    end

    // b-side write and read pointers
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_wr_ptr <= 0;
            b_wr_ptr_gray <= 0;
        end else if (b_dir && !b_full) begin
            b_wr_ptr <= b_wr_ptr + 1;
            b_wr_ptr_gray <= bin_to_gray(b_wr_ptr + 1);
        end
    end

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_rd_ptr <= 0;
            b_rd_ptr_gray <= 0;
        end else if (!b_dir && !b_empty) begin
            b_rd_ptr <= b_rd_ptr + 1;
            b_rd_ptr_gray <= bin_to_gray(b_rd_ptr + 1);
        end
    end

    // a-side write data
    always @(posedge a_clk) begin
        if (a_dir && !a_full) begin
            mem[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
        end
    end

    // b-side write data
    always @(posedge b_clk) begin
        if (b_dir && !b_full) begin
            mem[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
        end
    end

    // a-side read data
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_rdata_reg <= 0;
        end else if (!a_dir && !a_empty) begin
            a_rdata_reg <= mem[a_rd_ptr[ASIZE-1:0]];
        end
    end

    // b-side read data
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_rdata_reg <= 0;
        end else if (!b_dir && !b_empty) begin
            b_rdata_reg <= mem[b_rd_ptr[ASIZE-1:0]];
        end
    end

    // a-side flags
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_wr_ptr_gray_nxt <= 0;
            a_rd_ptr_gray_nxt <= 0;
        end else begin
            a_wr_ptr_gray_nxt <= a_wr_ptr_gray;
            a_rd_ptr_gray_nxt <= a_rd_ptr_gray;
        end
    end

    assign a_full = (a_wr_ptr_gray_nxt == {~b_rd_ptr_gray_nxt[ASIZE], b_rd_ptr_gray_nxt[ASIZE-1:0]});
    assign a_empty = (a_wr_ptr_gray == a_rd_ptr_gray);
    assign a_afull = (a_wr_ptr_gray_nxt == {~b_rd_ptr_gray_nxt[ASIZE], b_rd_ptr_gray_nxt[ASIZE-1:0] + 1});
    assign a_aempty = (a_wr_ptr_gray == {~a_rd_ptr_gray_nxt[ASIZE], a_rd_ptr_gray_nxt[ASIZE-1:0] + 1});

    // b-side flags
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_wr_ptr_gray_nxt <= 0;
            b_rd_ptr_gray_nxt <= 0;
        end else begin
            b_wr_ptr_gray_nxt <= b_wr_ptr_gray;
            b_rd_ptr_gray_nxt <= b_rd_ptr_gray;
        end
    end

    assign b_full = (b_wr_ptr_gray_nxt == {~a_rd_ptr_gray_nxt[ASIZE], a_rd_ptr_gray_nxt[ASIZE-1:0]});
    assign b_empty = (b_wr_ptr_gray == b_rd_ptr_gray);
    assign b_afull = (b_wr_ptr_gray_nxt == {~a_rd_ptr_gray_nxt[ASIZE], a_rd_ptr_gray_nxt[ASIZE-1:0] + 1});
    assign b_aempty = (b_wr_ptr_gray == {~b_rd_ptr_gray_nxt[ASIZE], b_rd_ptr_gray_nxt[ASIZE-1:0] + 1});

    // outputs
    assign a_rdata = a_rdata_reg;
    assign b_rdata = b_rdata_reg;

endmodule
