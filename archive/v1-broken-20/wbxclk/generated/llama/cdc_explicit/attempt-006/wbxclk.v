module wbxclk #(
    parameter AW = 32,
    parameter DW = 32,
    parameter LGFIFO = 5
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

    reg [(AW-1):0] fifo_addr [2**LGFIFO-1:0];
    reg [(DW-1):0] fifo_data [2**LGFIFO-1:0];
    reg [(DW/8-1):0] fifo_sel [2**LGFIFO-1:0];
    reg [LGFIFO-1:0] fifo_wr_ptr, fifo_rd_ptr;
    reg [LGFIFO:0] fifo_count;

    reg [LGFIFO:0] wb_fifo_count;

    reg wb_ack, wb_err;
    reg [(DW-1):0] wb_data;

    reg xclk_cyc, xclk_stb, xclk_we;
    reg [(AW-1):0] xclk_addr;
    reg [(DW-1):0] xclk_data;
    reg [(DW/8-1):0] xclk_sel;

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_stall <= 1'b0;
            o_wb_ack <= 1'b0;
            o_wb_data <= {(DW){1'b0}};
            o_wb_err <= 1'b0;
            o_xclk_cyc <= 1'b0;
            o_xclk_stb <= 1'b0;
            o_xclk_we <= 1'b0;
            o_xclk_addr <= {(AW){1'b0}};
            o_xclk_data <= {(DW){1'b0}};
            o_xclk_sel <= {(DW/8){1'b0}};
            fifo_wr_ptr <= {(LGFIFO){1'b0}};
            fifo_rd_ptr <= {(LGFIFO){1'b0}};
            fifo_count <= {(LGFIFO+1){1'b0}};
            wb_fifo_count <= {(LGFIFO+1){1'b0}};
            wb_ack <= 1'b0;
            wb_err <= 1'b0;
            wb_data <= {(DW){1'b0}};
            xclk_cyc <= 1'b0;
            xclk_stb <= 1'b0;
            xclk_we <= 1'b0;
            xclk_addr <= {(AW){1'b0}};
            xclk_data <= {(DW){1'b0}};
            xclk_sel <= {(DW/8){1'b0}};
        end else begin
            if (i_wb_cyc && i_wb_stb &&!o_wb_stall) begin
                fifo_addr[fifo_wr_ptr] <= i_wb_addr;
                fifo_data[fifo_wr_ptr] <= i_wb_data;
                fifo_sel[fifo_wr_ptr] <= i_wb_sel;
                fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
                fifo_count <= fifo_count + 1'b1;
                wb_fifo_count <= wb_fifo_count + 1'b1;
            end

            if (i_xclk_ack) begin
                fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
                fifo_count <= fifo_count - 1'b1;
                wb_fifo_count <= wb_fifo_count - 1'b1;
            end

            o_wb_stall <= (wb_fifo_count == (2**LGFIFO));
            o_wb_ack <= wb_ack;
            o_wb_data <= wb_data;
            o_wb_err <= wb_err;

            o_xclk_cyc <= xclk_cyc;
            o_xclk_stb <= xclk_stb;
            o_xclk_we <= xclk_we;
            o_xclk_addr <= xclk_addr;
            o_xclk_data <= xclk_data;
            o_xclk_sel <= xclk_sel;

            if (fifo_count > 0 &&!i_xclk_stall) begin
                xclk_cyc <= 1'b1;
                xclk_stb <= 1'b1;
                xclk_we <= i_wb_we;
                xclk_addr <= fifo_addr[fifo_rd_ptr];
                xclk_data <= fifo_data[fifo_rd_ptr];
                xclk_sel <= fifo_sel[fifo_rd_ptr];
            end else begin
                xclk_cyc <= 1'b0;
                xclk_stb <= 1'b0;
                xclk_we <= 1'b0;
                xclk_addr <= {(AW){1'b0}};
                xclk_data <= {(DW){1'b0}};
                xclk_sel <= {(DW/8){1'b0}};
            end

            if (i_xclk_ack) begin
                wb_ack <= 1'b1;
                wb_data <= i_xclk_data;
                wb_err <= i_xclk_err;
            end else begin
                wb_ack <= 1'b0;
                wb_data <= {(DW){1'b0}};
                wb_err <= 1'b0;
            end
        end
    end

endmodule
