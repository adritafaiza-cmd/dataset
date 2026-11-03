module wbxclk #(
    parameter AW = 32,
              DW = 32,
              LGFIFO = 5
) (
    input wire i_wb_clk, i_reset,
    input wire i_wb_cyc, i_wb_stb, i_wb_we,
    input wire [(AW-1):0] i_wb_addr,
    input wire [(DW-1):0] i_wb_data,
    input wire [(DW/8-1):0] i_wb_sel,
    output wire o_wb_stall,
    output reg o_wb_ack,
    output reg [(DW-1):0] o_wb_data,
    output reg o_wb_err,
    input wire i_xclk_clk,
    output reg o_xclk_cyc,
    output reg o_xclk_stb,
    output reg o_xclk_we,
    output reg [(AW-1):0] o_xclk_addr,
    output reg [(DW-1):0] o_xclk_data,
    output reg [(DW/8-1):0] o_xclk_sel,
    input wire i_xclk_stall,
    input wire i_xclk_ack,
    input wire [(DW-1):0] i_xclk_data,
    input wire i_xclk_err
);

    reg [(DW-1):0] fifo_data [2**LGFIFO-1:0];
    reg [(AW-1):0] fifo_addr [2**LGFIFO-1:0];
    reg [(DW/8-1):0] fifo_sel [2**LGFIFO-1:0];
    reg [LGFIFO-1:0] fifo_wr_ptr;
    reg [LGFIFO-1:0] fifo_rd_ptr;
    reg [LGFIFO:0] fifo_count;
    reg [LGFIFO:0] fifo_count_gray;
    reg [LGFIFO:0] fifo_count_gray_sync;
    reg o_wb_stall_sync;

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 0;
            o_wb_data <= 0;
            o_wb_err <= 0;
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
            o_xclk_we <= 0;
            o_xclk_addr <= 0;
            o_xclk_data <= 0;
            o_xclk_sel <= 0;
            fifo_wr_ptr <= 0;
            fifo_rd_ptr <= 0;
            fifo_count <= 0;
            fifo_count_gray <= 0;
            fifo_count_gray_sync <= 0;
            o_wb_stall_sync <= 0;
        end else begin
            if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
                fifo_data[fifo_wr_ptr] <= i_wb_data;
                fifo_addr[fifo_wr_ptr] <= i_wb_addr;
                fifo_sel[fifo_wr_ptr] <= i_wb_sel;
                fifo_wr_ptr <= fifo_wr_ptr + 1;
                fifo_count <= fifo_count + 1;
                fifo_count_gray <= (fifo_count + 1) ^ ((fifo_count + 1) >> 1);
            end
            if (i_xclk_ack && fifo_count > 0) begin
                fifo_rd_ptr <= fifo_rd_ptr + 1;
                fifo_count <= fifo_count - 1;
                fifo_count_gray <= (fifo_count - 1) ^ ((fifo_count - 1) >> 1);
            end
            if (fifo_count > (2**LGFIFO - 2)) begin
                o_wb_stall_sync <= 1;
            end else begin
                o_wb_stall_sync <= 0;
            end
            if (i_xclk_ack) begin
                o_wb_ack <= 1;
                o_wb_data <= i_xclk_data;
                o_wb_err <= i_xclk_err;
            end else begin
                o_wb_ack <= 0;
            end
        end
    end

    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
            o_xclk_we <= 0;
            o_xclk_addr <= 0;
            o_xclk_data <= 0;
            o_xclk_sel <= 0;
            fifo_count_gray_sync <= 0;
        end else begin
            if (fifo_count_gray_sync > 0) begin
                o_xclk_cyc <= 1;
                o_xclk_stb <= 1;
                o_xclk_we <= fifo_sel[fifo_rd_ptr];
                o_xclk_addr <= fifo_addr[fifo_rd_ptr];
                o_xclk_data <= fifo_data[fifo_rd_ptr];
                o_xclk_sel <= fifo_sel[fifo_rd_ptr];
            end else begin
                o_xclk_cyc <= 0;
                o_xclk_stb <= 0;
                o_xclk_we <= 0;
                o_xclk_addr <= 0;
                o_xclk_data <= 0;
                o_xclk_sel <= 0;
            end
            if (i_xclk_stall) begin
                fifo_count_gray_sync <= fifo_count_gray;
            end
        end
    end

    assign o_wb_stall = o_wb_stall_sync;

endmodule
