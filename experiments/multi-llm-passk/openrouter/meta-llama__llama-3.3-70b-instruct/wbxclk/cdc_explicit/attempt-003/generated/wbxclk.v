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

    reg [1:0] state;
    reg [1:0] next_state;

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
            state <= 0;
            next_state <= 0;
            fifo_wr_ptr <= 0;
            fifo_rd_ptr <= 0;
            fifo_count <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
            wb_stall <= 0;
            wb_ack <= 0;
            wb_data <= 0;
            wb_err <= 0;
            xclk_cyc <= 0;
            xclk_stb <= 0;
            xclk_we <= 0;
            xclk_addr <= 0;
            xclk_data <= 0;
            xclk_sel <= 0;
        end else begin
            case (state)
                0: begin
                    if (i_wb_cyc && i_wb_stb && !wb_stall) begin
                        state <= 1;
                        fifo_addr[fifo_wr_ptr] <= i_wb_addr;
                        fifo_data[fifo_wr_ptr] <= i_wb_data;
                        fifo_sel[fifo_wr_ptr] <= i_wb_sel;
                        fifo_wr_ptr <= fifo_wr_ptr + 1;
                        fifo_count <= fifo_count + 1;
                        if (fifo_count == (1<<LGFIFO)) begin
                            fifo_full <= 1;
                        end
                    end
                end
                1: begin
                    if (i_xclk_ack) begin
                        state <= 0;
                        wb_ack <= 1;
                        wb_data <= i_xclk_data;
                        wb_err <= i_xclk_err;
                        fifo_rd_ptr <= fifo_rd_ptr + 1;
                        fifo_count <= fifo_count - 1;
                        if (fifo_count == 0) begin
                            fifo_empty <= 1;
                        end
                    end
                end
            endcase
            if (fifo_full) begin
                wb_stall <= 1;
            end else begin
                wb_stall <= 0;
            end
            if (fifo_empty) begin
                xclk_cyc <= 0;
                xclk_stb <= 0;
                xclk_we <= 0;
                xclk_addr <= 0;
                xclk_data <= 0;
                xclk_sel <= 0;
            end else begin
                xclk_cyc <= 1;
                xclk_stb <= 1;
                xclk_we <= fifo_data[fifo_rd_ptr][0];
                xclk_addr <= fifo_addr[fifo_rd_ptr];
                xclk_data <= fifo_data[fifo_rd_ptr];
                xclk_sel <= fifo_sel[fifo_rd_ptr];
            end
            if (i_xclk_stall) begin
                xclk_cyc <= 0;
                xclk_stb <= 0;
                xclk_we <= 0;
                xclk_addr <= 0;
                xclk_data <= 0;
                xclk_sel <= 0;
            end
        end
    end

    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 0;
            o_wb_data <= 0;
            o_wb_err <= 0;
        end else begin
            o_wb_ack <= wb_ack;
            o_wb_data <= wb_data;
            o_wb_err <= wb_err;
            wb_ack <= 0;
        end
    end

endmodule
