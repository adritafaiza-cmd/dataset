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

    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH(FALLTHROUGH)
    ) fifo_a_to_b (
        .clk_wr(a_clk),
        .rst_wr_n(a_rst_n),
        .clk_rd(b_clk),
        .rst_rd_n(b_rst_n),
        .winc(a_winc & a_dir),
        .wdata(a_wdata),
        .rinc(b_rinc & ~b_dir),
        .rdata(b_rdata),
        .full(a_full),
        .afull(a_afull),
        .empty(b_empty),
        .aempty(b_aempty)
    );

    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH(FALLTHROUGH)
    ) fifo_b_to_a (
        .clk_wr(b_clk),
        .rst_wr_n(b_rst_n),
        .clk_rd(a_clk),
        .rst_rd_n(a_rst_n),
        .winc(b_winc & b_dir),
        .wdata(b_wdata),
        .rinc(a_rinc & ~a_dir),
        .rdata(a_rdata),
        .full(b_full),
        .afull(b_afull),
        .empty(a_empty),
        .aempty(a_aempty)
    );

endmodule

module async_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              clk_wr,
       input wire              rst_wr_n,
       input wire              clk_rd,
       input wire              rst_rd_n,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

    reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
    reg [ASIZE:0] wr_ptr_gray, rd_ptr_gray;
    reg [ASIZE:0] wr_ptr_gray_sync, rd_ptr_gray_sync;
    reg [ASIZE:0] wr_ptr_bin, rd_ptr_bin;
    reg [ASIZE:0] wr_ptr_bin_sync, rd_ptr_bin_sync;

    wire [ASIZE:0] wr_ptr_next, rd_ptr_next;
    wire [ASIZE:0] wr_ptr_gray_next, rd_ptr_gray_next;
    wire [ASIZE:0] wr_ptr_gray_sync_next, rd_ptr_gray_sync_next;

    // Gray code conversion
    assign wr_ptr_gray_next = (wr_ptr_bin + 1) ^ (wr_ptr_bin + 1) >> 1;
    assign rd_ptr_gray_next = (rd_ptr_bin + 1) ^ (rd_ptr_bin + 1) >> 1;

    // Synchronize Gray pointers
    sync_gray #(.WIDTH(ASIZE+1)) sync_wr_ptr (
        .clk(clk_rd),
        .rst_n(rst_rd_n),
        .din(wr_ptr_gray_next),
        .dout(wr_ptr_gray_sync_next)
    );

    sync_gray #(.WIDTH(ASIZE+1)) sync_rd_ptr (
        .clk(clk_wr),
        .rst_n(rst_wr_n),
        .din(rd_ptr_gray_next),
        .dout(rd_ptr_gray_sync_next)
    );

    // Binary conversion
    always @(posedge clk_wr or negedge rst_wr_n) begin
        if (!rst_wr_n) begin
            wr_ptr_gray <= 0;
            wr_ptr_bin <= 0;
        end else begin
            wr_ptr_gray <= wr_ptr_gray_next;
            wr_ptr_bin <= wr_ptr_bin + 1;
        end
    end

    always @(posedge clk_rd or negedge rst_rd_n) begin
        if (!rst_rd_n) begin
            rd_ptr_gray <= 0;
            rd_ptr_bin <= 0;
        end else begin
            rd_ptr_gray <= rd_ptr_gray_next;
            rd_ptr_bin <= rd_ptr_bin + 1;
        end
    end

    // Synchronized binary pointers
    always @(posedge clk_rd or negedge rst_rd_n) begin
        if (!rst_rd_n)
            wr_ptr_bin_sync <= 0;
        else
            wr_ptr_bin_sync <= bin_sync(wr_ptr_gray_sync_next);
    end

    always @(posedge clk_wr or negedge rst_wr_n) begin
        if (!rst_wr_n)
            rd_ptr_bin_sync <= 0;
        else
            rd_ptr_bin_sync <= bin_sync(rd_ptr_gray_sync_next);
    end

    // Binary conversion from Gray code
    function [ASIZE:0] bin_sync;
        input [ASIZE:0] gray;
        reg [ASIZE:0] bin;
        integer i;
        begin
            bin = gray[ASIZE];
            for (i = ASIZE-1; i >= 0; i = i - 1)
                bin[i] = bin[i+1] ^ gray[i];
            bin_sync = bin;
        end
    endfunction

    // Write operation
    always @(posedge clk_wr or negedge rst_wr_n) begin
        if (!rst_wr_n) begin
            mem[0] <= 0;
        end else if (winc) begin
            mem[wr_ptr_bin] <= wdata;
        end
    end

    // Read operation
    always @(posedge clk_rd or negedge rst_rd_n) begin
        if (!rst_rd_n)
            rdata <= 0;
        else if (rinc)
            rdata <= mem[rd_ptr_bin];
    end

    // Flags
    assign full = (wr_ptr_bin_sync == (rd_ptr_bin + (1 << ASIZE)));
    assign afull = (wr_ptr_bin_sync == (rd_ptr_bin + (1 << (ASIZE - 1))));
    assign empty = (wr_ptr_bin_sync == rd_ptr_bin);
    assign aempty = (wr_ptr_bin_sync == (rd_ptr_bin + 1));

endmodule

module sync_gray
  #(
    parameter WIDTH = 5
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire [WIDTH-1:0]  din,
       output reg [WIDTH-1:0]  dout
       );

    reg [WIDTH-1:0] d1, d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d1 <= 0;
            d2 <= 0;
            dout <= 0;
        end else begin
            d1 <= din;
            d2 <= d1;
            dout <= d2;
        end
    end

endmodule
