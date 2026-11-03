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

    reg [(AW-1):0] fifo_addr [2**LGFIFO-1:0];
    reg [(DW-1):0] fifo_data [2**LGFIFO-1:0];
    reg [(DW/8-1):0] fifo_sel [2**LGFIFO-1:0];
    reg [LGFIFO-1:0] fifo_ptr_wr;
    reg [LGFIFO-1:0] fifo_ptr_rd;
    reg [LGFIFO:0] fifo_cnt;
    reg o_wb_stall_reg;
    reg [1:0] state;

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 0;
            o_wb_data <= 0;
            o_wb_err <= 0;
            o_wb_stall_reg <= 0;
            fifo_ptr_wr <= 0;
            fifo_ptr_rd <= 0;
            fifo_cnt <= 0;
            state <= 0;
        end else begin
            if (i_wb_cyc && i_wb_stb &&!o_wb_stall_reg) begin
                fifo_addr[fifo_ptr_wr] <= i_wb_addr;
                fifo_data[fifo_ptr_wr] <= i_wb_data;
                fifo_sel[fifo_ptr_wr] <= i_wb_sel;
                fifo_ptr_wr <= fifo_ptr_wr + 1;
                fifo_cnt <= fifo_cnt + 1;
                o_wb_stall_reg <= (fifo_cnt == (2**LGFIFO-1));
            end

            if (i_xclk_ack) begin
                fifo_cnt <= fifo_cnt - 1;
                fifo_ptr_rd <= fifo_ptr_rd + 1;
                o_wb_stall_reg <= (fifo_cnt == (2**LGFIFO-1));
            end

            if (i_xclk_err) begin
                o_wb_err <= 1;
            end

            if (i_xclk_ack &&!i_xclk_err) begin
                o_wb_ack <= 1;
                o_wb_data <= i_xclk_data;
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
            state <= 0;
        end else begin
            case (state)
                0: begin
                    if (fifo_cnt > 0) begin
                        o_xclk_cyc <= 1;
                        o_xclk_stb <= 1;
                        o_xclk_we <= fifo_data[fifo_ptr_rd][DW-1];
                        o_xclk_addr <= fifo_addr[fifo_ptr_rd];
                        o_xclk_data <= fifo_data[fifo_ptr_rd];
                        o_xclk_sel <= fifo_sel[fifo_ptr_rd];
                        state <= 1;
                    end
                end
                1: begin
                    if (i_xclk_stall) begin
                        o_xclk_cyc <= 0;
                        o_xclk_stb <= 0;
                        o_xclk_we <= 0;
                        o_xclk_addr <= 0;
                        o_xclk_data <= 0;
                        o_xclk_sel <= 0;
                        state <= 0;
                    end
                end
            endcase
        end
    end

    assign o_wb_stall = o_wb_stall_reg;

endmodule
