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

    localparam WIDTH = 1 + AW + DW + (DW/8);
    localparam DEPTH = 1 << LGFIFO;

    reg wb2xclk_fifo_full;
    reg xclk2wb_fifo_full;

    fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) wb2xclk_fifo (
        .i_clk_wr(i_wb_clk),
        .i_clk_rd(i_xclk_clk),
        .i_reset(i_reset),
        .i_wr_en((i_wb_cyc & i_wb_stb) & ~wb2xclk_fifo_full),
        .i_data({i_wb_we, i_wb_addr, i_wb_data, i_wb_sel}),
        .i_rd_en(o_xclk_cyc & o_xclk_stb),
        .o_data({o_xclk_we, o_xclk_addr, o_xclk_data, o_xclk_sel}),
        .o_valid(o_xclk_cyc),
        .o_full(wb2xclk_fifo_full)
    );

    fifo #(.WIDTH(DW+1), .DEPTH(DEPTH)) xclk2wb_fifo (
        .i_clk_wr(i_xclk_clk),
        .i_clk_rd(i_wb_clk),
        .i_reset(i_reset),
        .i_wr_en(i_xclk_ack),
        .i_data({i_xclk_err, i_xclk_data}),
        .i_rd_en(o_wb_ack),
        .o_data({o_wb_err, o_wb_data}),
        .o_valid(o_wb_ack),
        .o_full(xclk2wb_fifo_full)
    );

    assign o_wb_stall = wb2xclk_fifo_full;

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 0;
            o_wb_data <= 0;
            o_wb_err <= 0;
        end else if (i_xclk_err) begin
            o_wb_ack <= 0;
        end else if (xclk2wb_fifo_full) begin
            o_wb_ack <= 0;
        end else if (i_xclk_ack) begin
            o_wb_ack <= 1;
        end else begin
            o_wb_ack <= 0;
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
        end else if (i_xclk_stall) begin
            o_xclk_cyc <= o_xclk_cyc;
            o_xclk_stb <= o_xclk_stb;
        end else if (wb2xclk_fifo_full) begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
        end else if (i_wb_cyc & i_wb_stb) begin
            o_xclk_cyc <= 1;
            o_xclk_stb <= 1;
        end else begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
        end
    end

endmodule

module fifo #(
    parameter WIDTH = 33,
              DEPTH = 32
) (
    input wire i_clk_wr, i_clk_rd, i_reset,
    input wire i_wr_en, i_rd_en,
    input wire [WIDTH-1:0] i_data,
    output reg [WIDTH-1:0] o_data,
    output reg o_valid, o_full
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg full, empty;

    always @(posedge i_clk_wr or posedge i_reset) begin
        if (i_reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            mem <= '{default:0};
            full <= 0;
            empty <= 1;
        end else begin
            if (i_wr_en & ~full) begin
                mem[wr_ptr] <= i_data;
                wr_ptr <= wr_ptr + 1;
            end
            if (wr_ptr == rd_ptr + 1) begin
                full <= 1;
            end else begin
                full <= 0;
            end
            if (wr_ptr == rd_ptr) begin
                empty <= 1;
            end else begin
                empty <= 0;
            end
        end
    end

    always @(posedge i_clk_rd or posedge i_reset) begin
        if (i_reset) begin
            rd_ptr <= 0;
            o_data <= 0;
            o_valid <= 0;
        end else begin
            if (i_rd_en & ~empty) begin
                o_data <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
            end
            o_valid <= ~empty;
        end
    end

    assign o_full = full;

endmodule
