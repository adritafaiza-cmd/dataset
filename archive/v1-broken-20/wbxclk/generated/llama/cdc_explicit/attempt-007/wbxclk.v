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

    reg [(AW-1):0] fifo_addr[(1<<LGFIFO)-1:0];
    reg [(DW-1):0] fifo_data[(1<<LGFIFO)-1:0];
    reg [(DW/8-1):0] fifo_sel[(1<<LGFIFO)-1:0];
    reg [LGFIFO-1:0] fifo_wr_ptr, fifo_rd_ptr;
    reg [LGFIFO:0] fifo_count;

    reg [LGFIFO:0] xclk_fifo_count;
    reg [(AW-1):0] xclk_fifo_addr[(1<<LGFIFO)-1:0];
    reg [(DW-1):0] xclk_fifo_data[(1<<LGFIFO)-1:0];
    reg [(DW/8-1):0] xclk_fifo_sel[(1<<LGFIFO)-1:0];
    reg [LGFIFO-1:0] xclk_fifo_wr_ptr, xclk_fifo_rd_ptr;

    reg wb_stall;
    reg wb_ack;
    reg [(DW-1):0] wb_data;
    reg wb_err;

    reg xclk_cyc;
    reg xclk_stb;
    reg xclk_we;
    reg [(AW-1):0] xclk_addr;
    reg [(DW-1):0] xclk_data;
    reg [(DW/8-1):0] xclk_sel;

    assign o_wb_stall = wb_stall;
    assign o_wb_ack = wb_ack;
    assign o_wb_data = wb_data;
    assign o_wb_err = wb_err;

    assign o_xclk_cyc = xclk_cyc;
    assign o_xclk_stb = xclk_stb;
    assign o_xclk_we = xclk_we;
    assign o_xclk_addr = xclk_addr;
    assign o_xclk_data = xclk_data;
    assign o_xclk_sel = xclk_sel;

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_stall <= 0;
            wb_ack <= 0;
            wb_data <= 0;
            wb_err <= 0;
            fifo_wr_ptr <= 0;
            fifo_rd_ptr <= 0;
            fifo_count <= 0;
        end else begin
            if (i_wb_cyc && i_wb_stb &&!wb_stall) begin
                fifo_addr[fifo_wr_ptr] <= i_wb_addr;
                fifo_data[fifo_wr_ptr] <= i_wb_data;
                fifo_sel[fifo_wr_ptr] <= i_wb_sel;
                fifo_wr_ptr <= fifo_wr_ptr + 1;
                fifo_count <= fifo_count + 1;
                wb_stall <= 1;
            end
            if (i_xclk_ack) begin
                fifo_rd_ptr <= fifo_rd_ptr + 1;
                fifo_count <= fifo_count - 1;
                wb_stall <= (fifo_count > 0);
            end
            if (i_xclk_err) begin
                wb_err <= 1;
            end
            if (i_xclk_ack) begin
                wb_ack <= 1;
                wb_data <= i_xclk_data;
            end else begin
                wb_ack <= 0;
            end
        end
    end

    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_cyc <= 0;
            xclk_stb <= 0;
            xclk_we <= 0;
            xclk_addr <= 0;
            xclk_data <= 0;
            xclk_sel <= 0;
            xclk_fifo_wr_ptr <= 0;
            xclk_fifo_rd_ptr <= 0;
            xclk_fifo_count <= 0;
        end else begin
            if (fifo_count > 0 &&!i_xclk_stall) begin
                xclk_cyc <= 1;
                xclk_stb <= 1;
                xclk_we <= i_wb_we;
                xclk_addr <= fifo_addr[fifo_rd_ptr];
                xclk_data <= fifo_data[fifo_rd_ptr];
                xclk_sel <= fifo_sel[fifo_rd_ptr];
                xclk_fifo_wr_ptr <= xclk_fifo_wr_ptr + 1;
                xclk_fifo_count <= xclk_fifo_count + 1;
            end
            if (i_xclk_ack) begin
                xclk_cyc <= 0;
                xclk_stb <= 0;
                xclk_we <= 0;
                xclk_addr <= 0;
                xclk_data <= 0;
                xclk_sel <= 0;
                xclk_fifo_rd_ptr <= xclk_fifo_rd_ptr + 1;
                xclk_fifo_count <= xclk_fifo_count - 1;
            end
        end
    end

endmodule
