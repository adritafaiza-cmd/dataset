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

    reg [(AW-1):0] fifo_addr [0:(1<<LGFIFO)-1];
    reg [(DW-1):0] fifo_data [0:(1<<LGFIFO)-1];
    reg [(DW/8-1):0] fifo_sel [0:(1<<LGFIFO)-1];
    reg [LGFIFO-1:0] fifo_wr_ptr, fifo_rd_ptr;
    reg [LGFIFO:0] fifo_count;
    reg fifo_full, fifo_empty;

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
        end else begin
            if (i_wb_cyc && i_wb_stb && !fifo_full) begin
                fifo_addr[fifo_wr_ptr] <= i_wb_addr;
                fifo_data[fifo_wr_ptr] <= i_wb_data;
                fifo_sel[fifo_wr_ptr] <= i_wb_sel;
                if (fifo_wr_ptr == (1<<LGFIFO)-1) begin
                    fifo_wr_ptr <= 0;
                end else begin
                    fifo_wr_ptr <= fifo_wr_ptr + 1;
                end
                fifo_count <= fifo_count + 1;
            end

            if (i_xclk_ack && !fifo_empty) begin
                o_wb_ack <= 1;
                o_wb_data <= i_xclk_data;
                o_wb_err <= i_xclk_err;
                if (fifo_rd_ptr == (1<<LGFIFO)-1) begin
                    fifo_rd_ptr <= 0;
                end else begin
                    fifo_rd_ptr <= fifo_rd_ptr + 1;
                end
                fifo_count <= fifo_count - 1;
            end else begin
                o_wb_ack <= 0;
            end

            if (fifo_count == (1<<LGFIFO)) begin
                fifo_full <= 1;
            end else begin
                fifo_full <= 0;
            end

            if (fifo_count == 0) begin
                fifo_empty <= 1;
            end else begin
                fifo_empty <= 0;
            end

            if (!fifo_empty && !i_xclk_stall) begin
                o_xclk_cyc <= 1;
                o_xclk_stb <= 1;
                o_xclk_we <= i_wb_we;
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
        end
    end

    assign o_wb_stall = fifo_full;

endmodule
