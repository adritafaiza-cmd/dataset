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

    // Instantiate the FIFO from a_clk to b_clk
    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH(FALLTHROUGH)
    ) a_to_b_fifo (
        .clk_wr(a_clk),
        .rst_n(a_rst_n),
        .wr_en(a_winc),
        .wr_data(a_wdata),
        .clk_rd(b_clk),
        .rd_en(b_rinc),
        .rd_data(b_rdata),
        .full(a_full),
        .afull(a_afull),
        .empty(a_empty),
        .aempty(a_aempty)
    );

    // Instantiate the FIFO from b_clk to a_clk
    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH(FALLTHROUGH)
    ) b_to_a_fifo (
        .clk_wr(b_clk),
        .rst_n(b_rst_n),
        .wr_en(b_winc),
        .wr_data(b_wdata),
        .clk_rd(a_clk),
        .rd_en(a_rinc),
        .rd_data(a_rdata),
        .full(b_full),
        .afull(b_afull),
        .empty(b_empty),
        .aempty(b_aempty)
    );

endmodule

module async_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              clk_wr,
       input wire              rst_n,
       input wire              wr_en,
       input wire [DSIZE-1:0]  wr_data,
       input wire              clk_rd,
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
    reg [AWIDTH:0] wr_ptr, rd_ptr;
    reg [AWIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [AWIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    reg [AWIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;

    // Write pointer logic
    always @(posedge clk_wr or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1;
            mem[wr_ptr[AWIDTH-1:0]] <= wr_data;
        end
    end

    // Convert write pointer to gray code
    assign wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;

    // Read pointer logic
    always @(posedge clk_rd or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Convert read pointer to gray code
    assign rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;

    // Sync read pointer gray code to write domain
    always @(posedge clk_wr or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // Sync write pointer gray code to read domain
    always @(posedge clk_rd or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // Convert synced read pointer back to binary
    reg [AWIDTH:0] rd_ptr_bin_sync;
    assign rd_ptr_bin_sync = (rd_ptr_gray_sync2 >> 1) ^ rd_ptr_gray_sync2;

    // Convert synced write pointer back to binary
    reg [AWIDTH:0] wr_ptr_bin_sync;
    assign wr_ptr_bin_sync = (wr_ptr_gray_sync2 >> 1) ^ wr_ptr_gray_sync2;

    // Output data
    assign rd_data = mem[rd_ptr_bin_sync[AWIDTH-1:0]];

    // Full flag logic
    assign full = (wr_ptr_bin_sync[AWIDTH] != rd_ptr_bin_sync[AWIDTH]) && (wr_ptr_bin_sync[AWIDTH-1:0] == rd_ptr_bin_sync[AWIDTH-1:0]);

    // Almost full flag logic
    assign afull = (wr_ptr_bin_sync[AWIDTH] != rd_ptr_bin_sync[AWIDTH]) && (wr_ptr_bin_sync[AWIDTH-1:0] == rd_ptr_bin_sync[AWIDTH-1:0] - 1);

    // Empty flag logic
    assign empty = (wr_ptr_bin_sync == rd_ptr_bin_sync);

    // Almost empty flag logic
    assign aempty = (wr_ptr_bin_sync == rd_ptr_bin_sync + 1);

endmodule
