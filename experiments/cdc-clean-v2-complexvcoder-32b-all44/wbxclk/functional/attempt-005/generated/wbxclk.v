module wbxclk #(
        parameter AW=32,
                  DW=32,
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

reg wb_stall_reg;
reg wb_ack_reg;
reg wb_err_reg;
reg [(DW-1):0] wb_data_reg;
reg xclk_cyc_reg;
reg xclk_stb_reg;
reg xclk_we_reg;
reg [(AW-1):0] xclk_addr_reg;
reg [(DW-1):0] xclk_data_reg;
reg [(DW/8-1):0] xclk_sel_reg;
wire fifo_full, fifo_empty;

fifo_async #(.AW(AW), .DW(DW), .LGFIFO(LGFIFO)) fifo_addr (
        .i_wb_clk(i_wb_clk),
        .i_xclk_clk(i_xclk_clk),
        .i_reset(i_reset),
        .i_data_in(i_wb_addr),
        .i_wb_valid(i_wb_cyc & i_wb_stb),
        .o_xclk_valid(xclk_cyc_reg),
        .o_data_out(xclk_addr_reg),
        .o_full(fifo_full),
        .o_empty(fifo_empty)
);

fifo_async #(.AW(AW), .DW(DW), .LGFIFO(LGFIFO)) fifo_data_in (
        .i_wb_clk(i_wb_clk),
        .i_xclk_clk(i_xclk_clk),
        .i_reset(i_reset),
        .i_data_in(i_wb_data),
        .i_wb_valid(i_wb_cyc & i_wb_stb),
        .o_xclk_valid(),
        .o_data_out(),
        .o_full(),
        .o_empty()
);

fifo_async #(.AW(AW), .DW(DW), .LGFIFO(LGFIFO)) fifo_data_out (
        .i_wb_clk(i_wb_clk),
        .i_xclk_clk(i_xclk_clk),
        .i_reset(i_reset),
        .i_data_in(i_xclk_data),
        .i_wb_valid(i_xclk_ack),
        .o_xclk_valid(wb_ack_reg),
        .o_data_out(wb_data_reg),
        .o_full(),
        .o_empty()
);

fifo_async #(.AW(AW), .DW(1), .LGFIFO(LGFIFO)) fifo_we (
        .i_wb_clk(i_wb_clk),
        .i_xclk_clk(i_xclk_clk),
        .i_reset(i_reset),
        .i_data_in(i_wb_we),
        .i_wb_valid(i_wb_cyc & i_wb_stb),
        .o_xclk_valid(),
        .o_data_out(xclk_we_reg),
        .o_full(),
        .o_empty()
);

fifo_async #(.AW(AW), .DW(DW/8), .LGFIFO(LGFIFO)) fifo_sel (
        .i_wb_clk(i_wb_clk),
        .i_xclk_clk(i_xclk_clk),
        .i_reset(i_reset),
        .i_data_in(i_wb_sel),
        .i_wb_valid(i_wb_cyc & i_wb_stb),
        .o_xclk_valid(),
        .o_data_out(xclk_sel_reg),
        .o_full(),
        .o_empty()
);

fifo_async #(.AW(AW), .DW(1), .LGFIFO(LGFIFO)) fifo_cyc (
        .i_wb_clk(i_wb_clk),
        .i_xclk_clk(i_xclk_clk),
        .i_reset(i_reset),
        .i_data_in(i_wb_cyc),
        .i_wb_valid(i_wb_cyc & i_wb_stb),
        .o_xclk_valid(),
        .o_data_out(),
        .o_full(),
        .o_empty()
);

fifo_async #(.AW(AW), .DW(1), .LGFIFO(LGFIFO)) fifo_stb (
        .i_wb_clk(i_wb_clk),
        .i_xclk_clk(i_xclk_clk),
        .i_reset(i_reset),
        .i_data_in(i_wb_stb),
        .i_wb_valid(i_wb_cyc & i_wb_stb),
        .o_xclk_valid(),
        .o_data_out(),
        .o_full(),
        .o_empty()
);

fifo_async #(.AW(AW), .DW(1), .LGFIFO(LGFIFO)) fifo_ack (
        .i_wb_clk(i_wb_clk),
        .i_xclk_clk(i_xclk_clk),
        .i_reset(i_reset),
        .i_data_in(i_xclk_ack),
        .i_wb_valid(),
        .o_xclk_valid(),
        .o_data_out(),
        .o_full(),
        .o_empty()
);

fifo_async #(.AW(AW), .DW(1), .LGFIFO(LGFIFO)) fifo_err (
        .i_wb_clk(i_wb_clk),
        .i_xclk_clk(i_xclk_clk),
        .i_reset(i_reset),
        .i_data_in(i_xclk_err),
        .i_wb_valid(i_xclk_ack),
        .o_xclk_valid(wb_err_reg),
        .o_data_out(),
        .o_full(),
        .o_empty()
);

always @(posedge i_wb_clk or posedge i_reset) begin
    if (i_reset) begin
        o_wb_stall <= 1'b0;
        o_wb_ack <= 1'b0;
        o_wb_data <= {DW{1'b0}};
        o_wb_err <= 1'b0;
    end else begin
        o_wb_stall <= fifo_full;
        o_wb_ack <= wb_ack_reg;
        o_wb_data <= wb_data_reg;
        o_wb_err <= wb_err_reg;
    end
end

always @(posedge i_xclk_clk or posedge i_reset) begin
    if (i_reset) begin
        o_xclk_cyc <= 1'b0;
        o_xclk_stb <= 1'b0;
        o_xclk_we <= 1'b0;
        o_xclk_addr <= {AW{1'b0}};
        o_xclk_data <= {DW{1'b0}};
        o_xclk_sel <= {DW/8{1'b0}};
    end else begin
        o_xclk_cyc <= xclk_cyc_reg;
        o_xclk_stb <= xclk_stb_reg;
        o_xclk_we <= xclk_we_reg;
        o_xclk_addr <= xclk_addr_reg;
        o_xclk_data <= xclk_data_reg;
        o_xclk_sel <= xclk_sel_reg;
    end
end

endmodule

module fifo_async #(
        parameter AW=32,
                  DW=32,
                  LGFIFO=5
) (
        input wire i_wb_clk,
        input wire i_xclk_clk,
        input wire i_reset,
        input wire [(DW-1):0] i_data_in,
        input wire i_wb_valid,
        output reg i_xclk_valid,
        output reg [(DW-1):0] o_data_out,
        output wire o_full,
        output wire o_empty
);

reg [LGFIFO-1:0] wb_wptr, wb_rptr;
reg [LGFIFO-1:0] xclk_wptr, xclk_rptr;
reg [DW-1:0] mem [0:(1<<LGFIFO)-1];

assign o_full = (wb_wptr + 1'b1) == xclk_rptr;
assign o_empty = wb_rptr == xclk_rptr;

always @(posedge i_wb_clk or posedge i_reset) begin
    if (i_reset) begin
        wb_wptr <= {LGFIFO{1'b0}};
        wb_rptr <= {LGFIFO{1'b0}};
    end else begin
        if (i_wb_valid && !o_full) begin
            mem[wb_wptr] <= i_data_in;
            wb_wptr <= wb_wptr + 1'b1;
        end
    end
end

always @(posedge i_xclk_clk or posedge i_reset) begin
    if (i_reset) begin
        xclk_wptr <= {LGFIFO{1'b0}};
        xclk_rptr <= {LGFIFO{1'b0}};
        i_xclk_valid <= 1'b0;
        o_data_out <= {DW{1'b0}};
    end else begin
        if (i_xclk_valid && !i_xclk_stall && !o_empty) begin
            xclk_rptr <= xclk_rptr + 1'b1;
            i_xclk_valid <= 1'b0;
        end else if (!o_empty) begin
            i_xclk_valid <= 1'b1;
            o_data_out <= mem[xclk_rptr];
        end
    end
end

endmodule
