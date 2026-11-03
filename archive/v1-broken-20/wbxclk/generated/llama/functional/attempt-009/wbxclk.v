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

reg [(AW-1):0] addr_fifo [(1<<LGFIFO)-1:0];
reg [(DW-1):0] data_fifo [(1<<LGFIFO)-1:0];
reg [(DW/8-1):0] sel_fifo [(1<<LGFIFO)-1:0];
reg [LGFIFO-1:0] wr_ptr, rd_ptr;
reg [LGFIFO:0] count;
reg [LGFIFO:0] next_count;

always @(posedge i_wb_clk or posedge i_reset) begin
    if (i_reset) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        count <= 0;
        o_wb_stall <= 0;
        o_wb_ack <= 0;
        o_wb_data <= 0;
        o_wb_err <= 0;
        o_xclk_cyc <= 0;
        o_xclk_stb <= 0;
        o_xclk_we <= 0;
        o_xclk_addr <= 0;
        o_xclk_data <= 0;
        o_xclk_sel <= 0;
    end else begin
        if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
            addr_fifo[wr_ptr] <= i_wb_addr;
            data_fifo[wr_ptr] <= i_wb_data;
            sel_fifo[wr_ptr] <= i_wb_sel;
            wr_ptr <= wr_ptr + 1;
            count <= count + 1;
        end
        if (i_xclk_ack && count > 0) begin
            rd_ptr <= rd_ptr + 1;
            count <= count - 1;
        end
        o_wb_stall <= (count == (1<<LGFIFO));
        if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
            o_wb_ack <= 1;
        end else begin
            o_wb_ack <= 0;
        end
        if (i_xclk_err) begin
            o_wb_err <= 1;
        end else begin
            o_wb_err <= 0;
        end
        if (count > 0) begin
            o_xclk_cyc <= 1;
            o_xclk_stb <= 1;
            o_xclk_we <= data_fifo[rd_ptr];
            o_xclk_addr <= addr_fifo[rd_ptr];
            o_xclk_data <= data_fifo[rd_ptr];
            o_xclk_sel <= sel_fifo[rd_ptr];
        end else begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
            o_xclk_we <= 0;
            o_xclk_addr <= 0;
            o_xclk_data <= 0;
            o_xclk_sel <= 0;
        end
        if (i_xclk_ack) begin
            o_wb_data <= i_xclk_data;
        end
    end
end

endmodule
