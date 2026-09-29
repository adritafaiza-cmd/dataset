module async_bidir_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4,
    parameter FALLTHROUGH = "TRUE"
) (
    input wire a_clk,
    input wire a_rst_n,
    input wire a_winc,
    input wire [DSIZE-1:0] a_wdata,
    input wire a_rinc,
    output wire [DSIZE-1:0] a_rdata,
    output wire a_full,
    output wire a_afull,
    output wire a_empty,
    output wire a_aempty,
    input wire a_dir,
    input wire b_clk,
    input wire b_rst_n,
    input wire b_winc,
    input wire [DSIZE-1:0] b_wdata,
    input wire b_rinc,
    output wire [DSIZE-1:0] b_rdata,
    output wire b_full,
    output wire b_afull,
    output wire b_empty,
    output wire b_aempty,
    input wire b_dir
);

// FIFO_AB: A to B direction
reg [ASIZE:0] wr_ptr_ab, rd_ptr_ab;
reg [ASIZE:0] wr_ptr_ab_gray, rd_ptr_ab_gray;
reg [ASIZE:0] wr_ptr_ab_sync_b [1:0];
reg [ASIZE:0] rd_ptr_ab_sync_a [1:0];
reg [DSIZE-1:0] mem_ab [0:(1 << ASIZE)-1];

// FIFO_BA: B to A direction
reg [ASIZE:0] wr_ptr_ba, rd_ptr_ba;
reg [ASIZE:0] wr_ptr_ba_gray, rd_ptr_ba_gray;
reg [ASIZE:0] wr_ptr_ba_sync_a [1:0];
reg [ASIZE:0] rd_ptr_ba_sync_b [1:0];
reg [DSIZE-1:0] mem_ba [0:(1 << ASIZE)-1];

// FIFO_AB write logic
always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
        wr_ptr_ab <= 0;
    end else if (a_dir && a_winc && !a_full) begin
        mem_ab[wr_ptr_ab[ASIZE-1:0]] <= a_wdata;
        wr_ptr_ab <= wr_ptr_ab + 1;
    end
end

// Convert to gray code
always @* begin
    wr_ptr_ab_gray = (wr_ptr_ab >> 1) ^ wr_ptr_ab;
end

// Synchronize to b_clk domain
always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
        wr_ptr_ab_sync_b[0] <= 0;
        wr_ptr_ab_sync_b[1] <= 0;
    end else begin
        wr_ptr_ab_sync_b[0] <= wr_ptr_ab_gray;
        wr_ptr_ab_sync_b[1] <= wr_ptr_ab_sync_b[0];
    end
end

// Convert synchronized gray to binary
function [ASIZE:0] gray2bin;
    input [ASIZE:0] gray;
    integer i;
    begin
        gray2bin[ASIZE] = gray[ASIZE];
        for (i = ASIZE-1; i >=0; i=i-1)
            gray2bin[i] = gray2bin[i+1] ^ gray[i];
    end
endfunction

// FIFO_AB read logic
reg [DSIZE-1:0] a_rdata_reg;
always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
        rd_ptr_ab <= 0;
        a_rdata_reg <= 0;
    end else if (b_dir && b_rinc && !b_empty) begin
        a_rdata_reg <= mem_ab[rd_ptr_ab[ASIZE-1:0]];
        rd_ptr_ab <= rd_ptr_ab + 1;
    end
end

// FIFO_AB full and empty
wire full_ab = (wr_ptr_ab - gray2bin(wr_ptr_ab_sync_b[1])) >= (1 << ASIZE);
wire empty_ab = (gray2bin(wr_ptr_ab_sync_a[1]) == rd_ptr_ab);

// Assign outputs for A side
assign a_full = full_ab;
assign a_afull = full_ab;
assign a_empty = empty_ab;
assign a_aempty = empty_ab;
assign a_rdata = a_rdata_reg;

// FIFO_BA write logic
always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
        wr_ptr_ba <= 0;
    end else if (b_dir && b_winc && !b_full) begin
        mem_ba[wr_ptr_ba[ASIZE-1:0]] <= b_wdata;
        wr_ptr_ba <= wr_ptr_ba + 1;
    end
end

// Convert to gray code
always @* begin
    wr_ptr_ba_gray = (wr_ptr_ba >> 1) ^ wr_ptr_ba;
end

// Synchronize to a_clk domain
always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
        wr_ptr_ba_sync_a[0] <= 0;
        wr_ptr_ba_sync_a[1] <= 0;
    end else begin
        wr_ptr_ba_sync_a[0] <= wr_ptr_ba_gray;
        wr_ptr_ba_sync_a[1] <= wr_ptr_ba_sync_a[0];
    end
end

// FIFO_BA read logic
reg [DSIZE-1:0] b_rdata_reg;
always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
        rd_ptr_ba <= 0;
        b_rdata_reg <= 0;
    end else if (a_dir && a_rinc && !a_empty) begin
        b_rdata_reg <= mem_ba[rd_ptr_ba[ASIZE-1:0]];
        rd_ptr_ba <= rd_ptr_ba + 1;
    end
end

// FIFO_BA full and empty
wire full_ba = (wr_ptr_ba - gray2bin(wr_ptr_ba_sync_a[1])) >= (1 << ASIZE);
wire empty_ba = (gray2bin(wr_ptr_ba_sync_b[1]) == rd_ptr_ba);

// Assign outputs for B side
assign b_full = full_ba;
assign b_afull = full_ba;
assign b_empty = empty_ba;
assign b_aempty = empty_ba;
assign b_rdata = b_rdata_reg;

endmodule
