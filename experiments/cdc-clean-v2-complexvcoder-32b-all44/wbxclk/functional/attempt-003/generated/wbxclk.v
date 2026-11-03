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

reg wb_to_xclk_wr;
reg wb_to_xclk_wr_ack;
reg wb_to_xclk_addr_full;
reg wb_to_xclk_addr_empty;
reg wb_to_xclk_data_full;
reg wb_to_xclk_data_empty;
reg wb_to_xclk_data_wr_ack;
reg [3:0] wb_to_xclk_ctrl;
reg wb_to_xclk_ctrl_full;
reg wb_to_xclk_ctrl_empty;
reg wb_to_xclk_ctrl_wr_ack;
reg wb_to_xclk_wr_en;
reg wb_to_xclk_rd_en;
reg wb_to_xclk_rd;

reg xclk_to_wb_wr;
reg xclk_to_wb_wr_ack;
reg xclk_to_wb_data_full;
reg xclk_to_wb_data_empty;
reg [(DW-1):0] xclk_to_wb_data_out;
reg xclk_to_wb_data_wr_ack;
reg [1:0] xclk_to_wb_ctrl;
reg xclk_to_wb_ctrl_full;
reg xclk_to_wb_ctrl_empty;
reg xclk_to_wb_ctrl_wr_ack;
reg xclk_to_wb_wr_en;
reg xclk_to_wb_rd_en;
reg xclk_to_wb_rd;

assign o_wb_stall = wb_to_xclk_addr_full | wb_to_xclk_data_full | wb_to_xclk_ctrl_full;

always @(posedge i_wb_clk or posedge i_reset) begin
    if (i_reset) begin
        wb_to_xclk_wr <= 0;
        wb_to_xclk_wr_en <= 0;
        wb_to_xclk_rd <= 0;
        wb_to_xclk_rd_en <= 0;
        o_wb_ack <= 0;
        o_wb_data <= 0;
        o_wb_err <= 0;
    end else begin
        wb_to_xclk_wr <= i_wb_cyc & i_wb_stb & ~wb_to_xclk_addr_full & ~wb_to_xclk_data_full & ~wb_to_xclk_ctrl_full;
        wb_to_xclk_wr_en <= wb_to_xclk_wr & wb_to_xclk_wr_ack;
        wb_to_xclk_ctrl <= {i_wb_we, i_wb_stb, i_wb_cyc};
        wb_to_xclk_rd_en <= wb_to_xclk_addr_empty & wb_to_xclk_data_empty & wb_to_xclk_ctrl_empty & i_xclk_ack;
        wb_to_xclk_rd <= wb_to_xclk_rd_en;
        if (wb_to_xclk_rd) begin
            o_wb_ack <= xclk_to_wb_ctrl_out[2];
            o_wb_err <= xclk_to_wb_ctrl_out[1];
            o_wb_data <= xclk_to_wb_data_out;
        end
    end
end

always @(posedge i_xclk_clk or posedge i_reset) begin
    if (i_reset) begin
        xclk_to_wb_wr <= 0;
        xclk_to_wb_wr_en <= 0;
        xclk_to_wb_rd <= 0;
        xclk_to_wb_rd_en <= 0;
        o_xclk_cyc <= 0;
        o_xclk_stb <= 0;
        o_xclk_we <= 0;
        o_xclk_addr <= 0;
        o_xclk_data <= 0;
        o_xclk_sel <= 0;
    end else begin
        xclk_to_wb_wr <= ~i_xclk_stall & ~xclk_to_wb_data_full & ~xclk_to_wb_ctrl_full;
        xclk_to_wb_wr_en <= xclk_to_wb_wr & xclk_to_wb_wr_ack;
        xclk_to_wb_ctrl <= {i_xclk_err, i_xclk_ack};
        xclk_to_wb_rd_en <= xclk_to_wb_data_empty & xclk_to_wb_ctrl_empty & i_wb_stb;
        xclk_to_wb_rd <= xclk_to_wb_rd_en;
        if (xclk_to_wb_wr) begin
            o_xclk_cyc <= wb_to_xclk_ctrl_out[2];
            o_xclk_stb <= wb_to_xclk_ctrl_out[1];
            o_xclk_we <= wb_to_xclk_ctrl_out[0];
            o_xclk_addr <= wb_to_xclk_addr_out;
            o_xclk_data <= wb_to_xclk_data_out;
            o_xclk_sel <= i_wb_sel;
        end
    end
end

wire [(AW-1):0] wb_to_xclk_addr_out;
wire [(DW-1):0] wb_to_xclk_data_out;
wire [3:0] wb_to_xclk_ctrl_out;

async_fifo #(
    .DATA_WIDTH(AW),
    .FIFO_DEPTH(1<<LGFIFO)
) wb_to_xclk_addr_fifo (
    .i_clk(i_wb_clk),
    .i_reset(i_reset),
    .i_wr_en(wb_to_xclk_wr_en),
    .i_rd_en(wb_to_xclk_rd_en),
    .i_data(i_wb_addr),
    .o_full(wb_to_xclk_addr_full),
    .o_empty(wb_to_xclk_addr_empty),
    .o_data(wb_to_xclk_addr_out),
    .o_wr_ack(wb_to_xclk_wr_ack)
);

async_fifo #(
    .DATA_WIDTH(DW),
    .FIFO_DEPTH(1<<LGFIFO)
) wb_to_xclk_data_fifo (
    .i_clk(i_wb_clk),
    .i_reset(i_reset),
    .i_wr_en(wb_to_xclk_wr_en),
    .i_rd_en(wb_to_xclk_rd_en),
    .i_data(i_wb_data),
    .o_full(wb_to_xclk_data_full),
    .o_empty(wb_to_xclk_data_empty),
    .o_data(wb_to_xclk_data_out),
    .o_wr_ack(wb_to_xclk_data_wr_ack)
);

async_fifo #(
    .DATA_WIDTH(4),
    .FIFO_DEPTH(1<<LGFIFO)
) wb_to_xclk_ctrl_fifo (
    .i_clk(i_wb_clk),
    .i_reset(i_reset),
    .i_wr_en(wb_to_xclk_wr_en),
    .i_rd_en(wb_to_xclk_rd_en),
    .i_data(wb_to_xclk_ctrl),
    .o_full(wb_to_xclk_ctrl_full),
    .o_empty(wb_to_xclk_ctrl_empty),
    .o_data(wb_to_xclk_ctrl_out),
    .o_wr_ack(wb_to_xclk_ctrl_wr_ack)
);

wire [(DW-1):0] xclk_to_wb_data_out_int;
wire [1:0] xclk_to_wb_ctrl_out_int;

async_fifo #(
    .DATA_WIDTH(DW),
    .FIFO_DEPTH(1<<LGFIFO)
) xclk_to_wb_data_fifo (
    .i_clk(i_xclk_clk),
    .i_reset(i_reset),
    .i_wr_en(xclk_to_wb_wr_en),
    .i_rd_en(xclk_to_wb_rd_en),
    .i_data(i_xclk_data),
    .o_full(xclk_to_wb_data_full),
    .o_empty(xclk_to_wb_data_empty),
    .o_data(xclk_to_wb_data_out_int),
    .o_wr_ack(xclk_to_wb_data_wr_ack)
);

async_fifo #(
    .DATA_WIDTH(2),
    .FIFO_DEPTH(1<<LGFIFO)
) xclk_to_wb_ctrl_fifo (
    .i_clk(i_xclk_clk),
    .i_reset(i_reset),
    .i_wr_en(xclk_to_wb_wr_en),
    .i_rd_en(xclk_to_wb_rd_en),
    .i_data(xclk_to_wb_ctrl),
    .o_full(xclk_to_wb_ctrl_full),
    .o_empty(xclk_to_wb_ctrl_empty),
    .o_data(xclk_to_wb_ctrl_out_int),
    .o_wr_ack(xclk_to_wb_ctrl_wr_ack)
);

assign xclk_to_wb_data_out = xclk_to_wb_data_out_int;
assign xclk_to_wb_ctrl_out = xclk_to_wb_ctrl_out_int;

endmodule

module async_fifo #(
    parameter DATA_WIDTH = 32,
              FIFO_DEPTH = 32
) (
    input wire i_clk,
    input wire i_reset,
    input wire i_wr_en,
    input wire i_rd_en,
    input wire [(DATA_WIDTH-1):0] i_data,
    output reg o_full,
    output reg o_empty,
    output reg [(DATA_WIDTH-1):0] o_data,
    output reg o_wr_ack
);

reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray, rd_ptr_gray_sync, wr_ptr_gray_sync;
reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr_gray_next, rd_ptr_gray_next;

assign wr_ptr_gray_next = wr_ptr ^ (wr_ptr >> 1);
assign rd_ptr_gray_next = rd_ptr ^ (rd_ptr >> 1);

always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        wr_ptr <= 0;
        wr_ptr_gray <= 0;
        rd_ptr <= 0;
        rd_ptr_gray <= 0;
        o_full <= 0;
        o_empty <= 1;
    end else begin
        wr_ptr_gray <= wr_ptr_gray_next;
        rd_ptr_gray <= rd_ptr_gray_next;

        if (i_wr_en && !o_full) begin
            mem[wr_ptr] <= i_data;
            wr_ptr <= wr_ptr + 1;
        end

        if (i_rd_en && !o_empty) begin
            rd_ptr <= rd_ptr + 1;
        end

        // Gray code synchronization
        rd_ptr_gray_sync <= rd_ptr_gray_next;
        wr_ptr_gray_sync <= wr_ptr_gray_sync;

        // Full/Empty flags
        o_full <= (wr_ptr_gray_next == (rd_ptr_gray_sync ^ (rd_ptr_gray_sync >> 1)));
        o_empty <= (wr_ptr_gray_sync == rd_ptr_gray_next);
    end
end

always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        o_data <= 0;
        o_wr_ack <= 0;
    end else begin
        if (i_wr_en && !o_full) begin
            o_wr_ack <= 1;
        end else begin
            o_wr_ack <= 0;
        end

        if (i_rd_en && !o_empty) begin
            o_data <= mem[rd_ptr];
        end
    end
end

endmodule
