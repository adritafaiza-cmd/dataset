module wbxclk #(
    parameter AW = 32,
    DW = 32,
    LGFIFO = 5
) (
    // Wishbone clock domain
    input wire i_wb_clk,
    input wire i_reset,
    input wire i_wb_cyc,
    input wire i_wb_stb,
    input wire i_wb_we,
    input wire [AW-1:0] i_wb_addr,
    input wire [DW-1:0] i_wb_data,
    input wire [(DW/8-1):0] i_wb_sel,
    output wire o_wb_stall,
    output reg o_wb_ack,
    output reg [DW-1:0] o_wb_data,
    output reg o_wb_err,

    // External clock domain
    input wire i_xclk_clk,
    input wire i_xclk_stall,
    input wire i_xclk_ack,
    input wire [DW-1:0] i_xclk_data,
    input wire i_xclk_err,

    // External interface
    output reg o_xclk_cyc,
    output reg o_xclk_stb,
    output reg o_xclk_we,
    output reg [AW-1:0] o_xclk_addr,
    output reg [DW-1:0] o_xclk_data,
    output reg [(DW/8-1):0] o_xclk_sel
);

    localparam FIFO_DEPTH = 2 ** LGFIFO;

    // Request FIFO in i_wb_clk domain
    reg [LGFIFO:0] wr_ptr, rd_ptr;
    reg [LGFIFO:0] wr_ptr_gray, rd_ptr_gray;
    reg [LGFIFO:0] wr_ptr_gray_sync [1:0];
    reg [LGFIFO:0] rd_ptr_gray_sync [1:0];
    reg [AW-1:0] fifo_addr [0:FIFO_DEPTH-1];
    reg [DW-1:0] fifo_data [0:FIFO_DEPTH-1];
    reg [(DW/8-1):0] fifo_sel [0:FIFO_DEPTH-1];
    reg fifo_we [0:FIFO_DEPTH-1];
    reg fifo_valid [0:FIFO_DEPTH-1];
    wire fifo_full = (wr_ptr - rd_ptr) >= FIFO_DEPTH;

    // Response FIFO in i_xclk_clk domain
    reg [LGFIFO:0] wr_ptr_resp, rd_ptr_resp;
    reg [LGFIFO:0] wr_ptr_resp_gray, rd_ptr_resp_gray;
    reg [LGFIFO:0] wr_ptr_resp_gray_sync [1:0];
    reg [LGFIFO:0] rd_ptr_resp_gray_sync [1:0];
    reg [DW-1:0] resp_data [0:FIFO_DEPTH-1];
    reg resp_ack [0:FIFO_DEPTH-1];
    reg resp_err [0:FIFO_DEPTH-1];
    wire resp_full = (wr_ptr_resp - rd_ptr_resp) >= FIFO_DEPTH;

    // CDC synchronization
    function [LGFIFO:0] bin2gray(input [LGFIFO:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Request FIFO write (i_wb_clk domain)
    always @(posedge i_wb_clk) begin
        if (i_reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            wr_ptr_gray <= 0;
            rd_ptr_gray <= 0;
        end else begin
            if (i_wb_cyc && i_wb_stb && !fifo_full) begin
                fifo_addr[wr_ptr] <= i_wb_addr;
                fifo_data[wr_ptr] <= i_wb_data;
                fifo_sel[wr_ptr] <= i_wb_sel;
                fifo_we[wr_ptr] <= i_wb_we;
                fifo_valid[wr_ptr] <= 1;
                wr_ptr <= wr_ptr + 1;
                wr_ptr_gray <= bin2gray(wr_ptr + 1);
            end
        end
    end

    // Sync write pointer to i_xclk_clk domain
    always @(posedge i_xclk_clk) begin
        wr_ptr_gray_sync[0] <= wr_ptr_gray;
        wr_ptr_gray_sync[1] <= wr_ptr_gray_sync[0];
    end

    // Request FIFO read (i_xclk_clk domain)
    reg [LGFIFO:0] rd_ptr_xclk;
    always @(posedge i_xclk_clk) begin
        if (i_reset) begin
            rd_ptr_xclk <= 0;
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
        end else begin
            if (fifo_valid[rd_ptr_xclk] && (wr_ptr_gray_sync[1] != rd_ptr_gray)) begin
                o_xclk_cyc <= 1;
                o_xclk_stb <= 1;
                o_xclk_we <= fifo_we[rd_ptr_xclk];
                o_xclk_addr <= fifo_addr[rd_ptr_xclk];
                o_xclk_data <= fifo_data[rd_ptr_xclk];
                o_xclk_sel <= fifo_sel[rd_ptr_xclk];
                if (i_xclk_ack) begin
                    // Write response to response FIFO
                    resp_data[wr_ptr_resp] <= i_xclk_data;
                    resp_ack[wr_ptr_resp] <= 1;
                    resp_err[wr_ptr_resp] <= i_xclk_err;
                    wr_ptr_resp <= wr_ptr_resp + 1;
                    wr_ptr_resp_gray <= bin2gray(wr_ptr_resp + 1);
                    rd_ptr_xclk <= rd_ptr_xclk + 1;
                end
            end
        end
    end

    // Sync response FIFO pointers to i_wb_clk domain
    always @(posedge i_wb_clk) begin
        rd_ptr_gray_sync[0] <= rd_ptr_gray;
        rd_ptr_gray_sync[1] <= rd_ptr_gray_sync[0];
    end

    // Response FIFO read (i_wb_clk domain)
    reg [LGFIFO:0] rd_ptr_resp;
    always @(posedge i_wb_clk) begin
        if (i_reset) begin
            rd_ptr_resp <= 0;
            o_wb_ack <= 0;
            o_wb_err <= 0;
            o_wb_data <= 0;
        end else begin
            if (resp_ack[rd_ptr_resp] && (wr_ptr_resp_gray_sync[1] != rd_ptr_resp_gray)) begin
                o_wb_ack <= resp_ack[rd_ptr_resp];
                o_wb_err <= resp_err[rd_ptr_resp];
                o_wb_data <= resp_data[rd_ptr_resp];
                rd_ptr_resp <= rd_ptr_resp + 1;
                rd_ptr_gray <= bin2gray(rd_ptr_resp + 1);
            end
        end
    end

    assign o_wb_stall = fifo_full;

endmodule
