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

    // Instantiate the asynchronous FIFO from A to B
    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH(FALLTHROUGH)
    ) fifo_a_to_b (
        .clk_wr(a_clk),
        .rst_wr_n(a_rst_n),
        .wr_en(a_winc & a_dir),
        .wr_data(a_wdata),
        .clk_rd(b_clk),
        .rst_rd_n(b_rst_n),
        .rd_en(b_rinc & ~b_dir),
        .rd_data(b_rdata),
        .full(b_full),
        .afull(b_afull),
        .empty(b_empty),
        .aempty(b_aempty)
    );

    // Instantiate the asynchronous FIFO from B to A
    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH(FALLTHROUGH)
    ) fifo_b_to_a (
        .clk_wr(b_clk),
        .rst_wr_n(b_rst_n),
        .wr_en(b_winc & b_dir),
        .wr_data(b_wdata),
        .clk_rd(a_clk),
        .rst_rd_n(a_rst_n),
        .rd_en(a_rinc & ~a_dir),
        .rd_data(a_rdata),
        .full(a_full),
        .afull(a_afull),
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
       input wire              wr_en,
       input wire [DSIZE-1:0]  wr_data,
       input wire              clk_rd,
       input wire              rst_rd_n,
       input wire              rd_en,
       output wire [DSIZE-1:0] rd_data,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

    localparam DEPTH = 1 << ASIZE;
    localparam AWIDTH = ASIZE;

    reg [DSIZE-1:0] mem [0:DEPTH-1];

    reg [AWIDTH:0] wr_ptr, wr_ptr_gray;
    reg [AWIDTH:0] rd_ptr, rd_ptr_gray;

    reg [AWIDTH:0] wr_ptr_gray_sync, wr_ptr_gray_sync2;
    reg [AWIDTH:0] rd_ptr_gray_sync, rd_ptr_gray_sync2;

    // Gray code conversion
    function [AWIDTH:0] binary_to_gray;
        input [AWIDTH:0] bin;
        binary_to_gray = (bin >> 1) ^ bin;
    endfunction

    // Gray code to binary conversion
    function [AWIDTH:0] gray_to_binary;
        input [AWIDTH:0] gray;
        integer i;
        reg [AWIDTH:0] bin;
        bin = gray;
        for (i = AWIDTH-1; i >= 0; i = i - 1)
            bin[i] = bin[i+1] ^ gray[i];
        gray_to_binary = bin;
    endfunction

    // Write pointer logic
    always @(posedge clk_wr or negedge rst_wr_n) begin
        if (!rst_wr_n) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= binary_to_gray(wr_ptr + 1);
        end
    end

    // Read pointer logic
    always @(posedge clk_rd or negedge rst_rd_n) begin
        if (!rst_rd_n) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= binary_to_gray(rd_ptr + 1);
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge clk_rd or negedge rst_rd_n) begin
        if (!rst_rd_n) begin
            wr_ptr_gray_sync <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync;
        end
    end

    // Synchronize read pointer to write domain
    always @(posedge clk_wr or negedge rst_wr_n) begin
        if (!rst_wr_n) begin
            rd_ptr_gray_sync <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync;
        end
    end

    // Write operation
    always @(posedge clk_wr or negedge rst_wr_n) begin
        if (!rst_wr_n) begin
            mem[0] <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[AWIDTH-1:0]] <= wr_data;
        end
    end

    // Read operation
    reg [DSIZE-1:0] rd_data_reg;
    always @(posedge clk_rd or negedge rst_rd_n) begin
        if (!rst_rd_n) begin
            rd_data_reg <= 0;
        end else if (rd_en && !empty) begin
            rd_data_reg <= mem[rd_ptr[AWIDTH-1:0]];
        end
    end

    assign rd_data = rd_data_reg;

    // Full flag logic
    wire [AWIDTH:0] wr_ptr_gray_sync_bin = gray_to_binary(wr_ptr_gray_sync2);
    assign full = (wr_ptr_gray_sync_bin[AWIDTH-1:0] == rd_ptr[AWIDTH-1:0]) && (wr_ptr_gray_sync_bin[AWIDTH] != rd_ptr[AWIDTH]);
    assign afull = (wr_ptr_gray_sync_bin[AWIDTH-1:0] == rd_ptr[AWIDTH-1:0] + DEPTH - 2) && (wr_ptr_gray_sync_bin[AWIDTH] != rd_ptr[AWIDTH]);

    // Empty flag logic
    wire [AWIDTH:0] rd_ptr_gray_sync_bin = gray_to_binary(rd_ptr_gray_sync2);
    assign empty = (rd_ptr_gray_sync_bin[AWIDTH-1:0] == wr_ptr[AWIDTH-1:0]) && (rd_ptr_gray_sync_bin[AWIDTH] == wr_ptr[AWIDTH]);
    assign aempty = (rd_ptr_gray_sync_bin[AWIDTH-1:0] == wr_ptr[AWIDTH-1:0] + 1) && (rd_ptr_gray_sync_bin[AWIDTH] == wr_ptr[AWIDTH]);

endmodule
