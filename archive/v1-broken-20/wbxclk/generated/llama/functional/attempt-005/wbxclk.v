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

reg [(AW-1):0] addr_fifo [(1<<LGFIFO)-1:0];
reg [(DW-1):0] data_fifo [(1<<LGFIFO)-1:0];
reg [(DW/8-1):0] sel_fifo [(1<<LGFIFO)-1:0];
reg [LGFIFO-1:0] wr_ptr, rd_ptr;
reg [LGFIFO:0] count;
reg [LGFIFO:0] next_count;

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
        wr_ptr <= 0;
        rd_ptr <= 0;
        count <= 0;
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

        if (i_xclk_err && count > 0) begin
            o_wb_err <= 1;
            rd_ptr <= rd_ptr + 1;
            count <= count - 1;
        end

        if (i_xclk_data && count > 0) begin
            o_wb_data <= i_xclk_data;
            o_wb_ack <= 1;
            rd_ptr <= rd_ptr + 1;
            count <= count - 1;
        end

        o_wb_ack <= (o_wb_ack && !i_wb_cyc) || (i_xclk_data && count > 0);
        o_wb_err <= (o_wb_err && !i_wb_cyc) || (i_xclk_err && count > 0);

        o_xclk_cyc <= (count > 0 && !i_xclk_stall);
        o_xclk_stb <= (count > 0 && !i_xclk_stall);
        o_xclk_we <= (count > 0 && !i_xclk_stall) ? data_fifo[rd_ptr][DW-1] : 0;
        o_xclk_addr <= (count > 0 && !i_xclk_stall) ? addr_fifo[rd_ptr] : 0;
        o_xclk_data <= (count > 0 && !i_xclk_stall) ? data_fifo[rd_ptr] : 0;
        o_xclk_sel <= (count > 0 && !i_xclk_stall) ? sel_fifo[rd_ptr] : 0;
    end
end

assign o_wb_stall = (count == (1<<LGFIFO));

endmodule
