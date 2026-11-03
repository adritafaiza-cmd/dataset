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

    reg [DSIZE-1:0] mem [DEPTH-1:0];

    // a_side signals
    reg [ASIZE:0] a_wr_ptr;
    reg [ASIZE:0] a_rd_ptr;
    reg [ASIZE:0] a_wr_ptr_gray;
    reg [ASIZE:0] a_rd_ptr_gray;
    reg [ASIZE:0] b_rd_ptr_gray_sync;
    reg [ASIZE:0] b_wr_ptr_gray_sync;

    // b_side signals
    reg [ASIZE:0] b_wr_ptr;
    reg [ASIZE:0] b_rd_ptr;
    reg [ASIZE:0] b_wr_ptr_gray;
    reg [ASIZE:0] b_rd_ptr_gray;
    reg [ASIZE:0] a_rd_ptr_gray_sync;
    reg [ASIZE:0] a_wr_ptr_gray_sync;

    // Gray code conversion
    function [ASIZE:0] bin_to_gray;
        input [ASIZE:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // a_side logic
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_wr_ptr <= 0;
            a_rd_ptr <= 0;
        end else if (a_dir) begin
            if (!a_full) begin
                mem[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
                a_wr_ptr <= a_wr_ptr + 1;
            end
        end else begin
            if (!a_empty) begin
                a_rd_ptr <= a_rd_ptr + 1;
            end
        end
    end

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_wr_ptr_gray <= 0;
            a_rd_ptr_gray <= 0;
        end else begin
            a_wr_ptr_gray <= bin_to_gray(a_wr_ptr);
            a_rd_ptr_gray <= bin_to_gray(a_rd_ptr);
        end
    end

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            a_rd_ptr_gray_sync <= 0;
            a_wr_ptr_gray_sync <= 0;
        end else begin
            a_rd_ptr_gray_sync <= a_rd_ptr_gray;
            a_wr_ptr_gray_sync <= a_wr_ptr_gray;
        end
    end

    // b_side logic
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_wr_ptr <= 0;
            b_rd_ptr <= 0;
        end else if (b_dir) begin
            if (!b_full) begin
                mem[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
                b_wr_ptr <= b_wr_ptr + 1;
            end
        end else begin
            if (!b_empty) begin
                b_rd_ptr <= b_rd_ptr + 1;
            end
        end
    end

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_wr_ptr_gray <= 0;
            b_rd_ptr_gray <= 0;
        end else begin
            b_wr_ptr_gray <= bin_to_gray(b_wr_ptr);
            b_rd_ptr_gray <= bin_to_gray(b_rd_ptr);
        end
    end

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            b_wr_ptr_gray_sync <= 0;
            b_rd_ptr_gray_sync <= 0;
        end else begin
            b_wr_ptr_gray_sync <= b_wr_ptr_gray;
            b_rd_ptr_gray_sync <= b_rd_ptr_gray;
        end
    end

    // a_side flags
    assign a_full = (a_wr_ptr_gray_sync[ASIZE] != a_rd_ptr_gray[ASIZE]) && (a_wr_ptr_gray_sync[ASIZE-1:0] == a_rd_ptr_gray[ASIZE-1:0]);
    assign a_afull = (a_wr_ptr_gray_sync[ASIZE] != a_rd_ptr_gray[ASIZE]) && (a_wr_ptr_gray_sync[ASIZE-1:0] == (a_rd_ptr_gray[ASIZE-1:0] + AFULL_THRESHOLD));
    assign a_empty = (a_wr_ptr_gray == a_rd_ptr_gray);
    assign a_aempty = (a_wr_ptr_gray == a_rd_ptr_gray) || (a_wr_ptr_gray[ASIZE] != a_rd_ptr_gray[ASIZE] && a_wr_ptr_gray[ASIZE-1:0] == (a_rd_ptr_gray[ASIZE-1:0] + 1));

    // b_side flags
    assign b_full = (b_wr_ptr_gray_sync[ASIZE] != b_rd_ptr_gray[ASIZE]) && (b_wr_ptr_gray_sync[ASIZE-1:0] == b_rd_ptr_gray[ASIZE-1:0]);
    assign b_afull = (b_wr_ptr_gray_sync[ASIZE] != b_rd_ptr_gray[ASIZE]) && (b_wr_ptr_gray_sync[ASIZE-1:0] == (b_rd_ptr_gray[ASIZE-1:0] + AFULL_THRESHOLD));
    assign b_empty = (b_wr_ptr_gray == b_rd_ptr_gray);
    assign b_aempty = (b_wr_ptr_gray == b_rd_ptr_gray) || (b_wr_ptr_gray[ASIZE] != b_rd_ptr_gray[ASIZE] && b_wr_ptr_gray[ASIZE-1:0] == (b_rd_ptr_gray[ASIZE-1:0] + 1));

    // a_side read data
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_rdata <= 0;
        end else if (a_rinc && !a_empty) begin
            a_rdata <= mem[a_rd_ptr[ASIZE-1:0]];
        end
    end

    // b_side read data
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_rdata <= 0;
        end else if (b_rinc && !b_empty) begin
            b_rdata <= mem[b_rd_ptr[ASIZE-1:0]];
        end
    end

endmodule
