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

    reg [(AW-1):0] addr_fifo [(1 << LGFIFO)-1:0];
    reg [(DW-1):0] data_fifo [(1 << LGFIFO)-1:0];
    reg [(DW/8-1):0] sel_fifo [(1 << LGFIFO)-1:0];
    reg [LGFIFO-1:0] wr_ptr, rd_ptr;
    reg [LGFIFO:0] count;
    reg [LGFIFO:0] next_count;
    reg [1:0] state;
    reg [1:0] next_state;
    reg ack, err;
    reg [(DW-1):0] data;

    assign o_wb_stall = (count == (1 << LGFIFO));
    assign o_xclk_cyc = (state == 2'b01);
    assign o_xclk_stb = (state == 2'b01);
    assign o_xclk_we = (wr_ptr != 0) ? addr_fifo[wr_ptr-1][0] : 1'b0;
    assign o_xclk_addr = (wr_ptr != 0) ? addr_fifo[wr_ptr-1] : {AW{1'b0}};
    assign o_xclk_data = (wr_ptr != 0) ? data_fifo[wr_ptr-1] : {DW{1'b0}};
    assign o_xclk_sel = (wr_ptr != 0) ? sel_fifo[wr_ptr-1] : {DW/8{1'b0}};

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            state <= 2'b00;
            o_wb_ack <= 1'b0;
            o_wb_data <= {DW{1'b0}};
            o_wb_err <= 1'b0;
        end else begin
            wr_ptr <= next_wr_ptr;
            rd_ptr <= next_rd_ptr;
            count <= next_count;
            state <= next_state;
            o_wb_ack <= ack;
            o_wb_data <= data;
            o_wb_err <= err;
        end
    end

    always @(*) begin
        next_wr_ptr = wr_ptr;
        next_rd_ptr = rd_ptr;
        next_count = count;
        next_state = state;
        ack = 1'b0;
        err = 1'b0;
        data = {DW{1'b0}};

        if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
            next_wr_ptr = wr_ptr + 1;
            addr_fifo[wr_ptr] = i_wb_addr;
            data_fifo[wr_ptr] = i_wb_data;
            sel_fifo[wr_ptr] = i_wb_sel;
            next_count = count + 1;
        end

        if (i_xclk_ack && state == 2'b01) begin
            next_rd_ptr = rd_ptr + 1;
            next_count = count - 1;
            next_state = 2'b00;
            ack = 1'b1;
            data = i_xclk_data;
        end

        if (i_xclk_err && state == 2'b01) begin
            next_rd_ptr = rd_ptr + 1;
            next_count = count - 1;
            next_state = 2'b00;
            err = 1'b1;
        end

        if (count > 0 && !i_xclk_stall && state != 2'b01) begin
            next_state = 2'b01;
        end
    end

endmodule
