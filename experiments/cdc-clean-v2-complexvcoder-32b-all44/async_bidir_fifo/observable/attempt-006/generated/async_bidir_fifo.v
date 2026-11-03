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

    // Instantiate the FIFO for data transfer from a_clk to b_clk
    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH(FALLTHROUGH)
    ) a_to_b_fifo (
        .clk_wr(a_clk),
        .rst_n_wr(a_rst_n),
        .winc(a_winc & a_dir),
        .wdata(a_wdata),
        .clk_rd(b_clk),
        .rst_n_rd(b_rst_n),
        .rinc(b_rinc & ~b_dir),
        .rdata(b_rdata),
        .full(b_full),
        .afull(b_afull),
        .empty(a_empty),
        .aempty(a_aempty)
    );

    // Instantiate the FIFO for data transfer from b_clk to a_clk
    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH(FALLTHROUGH)
    ) b_to_a_fifo (
        .clk_wr(b_clk),
        .rst_n_wr(b_rst_n),
        .winc(b_winc & b_dir),
        .wdata(b_wdata),
        .clk_rd(a_clk),
        .rst_n_rd(a_rst_n),
        .rinc(a_rinc & ~a_dir),
        .rdata(a_rdata),
        .full(a_full),
        .afull(a_afull),
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
       input wire              rst_n_wr,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              clk_rd,
       input wire              rst_n_rd,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

    reg [DSIZE-1:0] mem [(1<<ASIZE)-1:0];
    reg [ASIZE-1:0] wr_ptr;
    reg [ASIZE-1:0] rd_ptr;
    reg [ASIZE-1:0] wr_ptr_gray;
    reg [ASIZE-1:0] rd_ptr_gray;
    reg [ASIZE-1:0] rd_ptr_gray_sync;
    reg [ASIZE-1:0] wr_ptr_gray_sync;
    reg [ASIZE-1:0] wr_ptr_gray_sync2;
    reg [ASIZE-1:0] rd_ptr_gray_sync2;
    wire [ASIZE-1:0] wr_ptr_bin;
    wire [ASIZE-1:0] rd_ptr_bin;
    wire [ASIZE-1:0] wr_ptr_bin_sync;
    wire [ASIZE-1:0] rd_ptr_bin_sync;
    wire full_flag;
    wire afull_flag;
    wire empty_flag;
    wire aempty_flag;
    wire [ASIZE-1:0] gray_to_bin;

    // Write side logic
    always @(posedge clk_wr or negedge rst_n_wr) begin
        if (!rst_n_wr) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (winc && !full_flag) begin
            mem[wr_ptr_bin] <= wdata;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
        end
    end

    // Read side logic
    always @(posedge clk_rd or negedge rst_n_rd) begin
        if (!rst_n_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rinc && !empty_flag) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
        end
    end

    // Gray to binary conversion
    assign gray_to_bin = wr_ptr_gray_sync ^ (wr_ptr_gray_sync >> 1);
    assign wr_ptr_bin = wr_ptr;
    assign rd_ptr_bin = rd_ptr;
    assign wr_ptr_bin_sync = gray_to_bin;
    assign rd_ptr_bin_sync = rd_ptr_gray_sync2 ^ (rd_ptr_gray_sync2 >> 1);

    // Gray code synchronization
    always @(posedge clk_wr or negedge rst_n_wr) begin
        if (!rst_n_wr) begin
            rd_ptr_gray_sync <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync;
        end
    end

    always @(posedge clk_rd or negedge rst_n_rd) begin
        if (!rst_n_rd) begin
            wr_ptr_gray_sync <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync;
        end
    end

    // Flags calculation
    assign full_flag = (wr_ptr_bin + 1) == rd_ptr_bin_sync;
    assign afull_flag = (wr_ptr_bin + 2) == rd_ptr_bin_sync;
    assign empty_flag = wr_ptr_bin_sync == rd_ptr_bin;
    assign aempty_flag = wr_ptr_bin_sync == (rd_ptr_bin + 1);

    // Read data output
    assign rdata = mem[rd_ptr_bin];

    // Output flags
    assign full = full_flag;
    assign afull = afull_flag;
    assign empty = empty_flag;
    assign aempty = aempty_flag;

endmodule
