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

    // FIFO signals for Wishbone to XCLK domain
    reg fifo_wb_to_xclk_wr_en;
    wire fifo_wb_to_xclk_full;
    wire [(DW + AW + 1 + DW/8 + 1 + 1 - 1):0] fifo_wb_to_xclk_din;
    reg fifo_wb_to_xclk_rd_en;
    wire fifo_wb_to_xclk_empty;
    wire [(DW + AW + 1 + DW/8 + 1 + 1 - 1):0] fifo_wb_to_xclk_dout;

    // FIFO signals for XCLK to Wishbone domain
    reg fifo_xclk_to_wb_wr_en;
    wire fifo_xclk_to_wb_full;
    wire [(DW + 1 + 1 - 1):0] fifo_xclk_to_wb_din;
    reg fifo_xclk_to_wb_rd_en;
    wire fifo_xclk_to_wb_empty;
    wire [(DW + 1 + 1 - 1):0] fifo_xclk_to_wb_dout;

    // Intermediate signals
    reg [(DW-1):0] wb_to_xclk_data;
    reg [(AW-1):0] wb_to_xclk_addr;
    reg wb_to_xclk_we;
    reg [(DW/8-1):0] wb_to_xclk_sel;
    reg wb_to_xclk_cyc;
    reg wb_to_xclk_stb;

    reg [(DW-1):0] xclk_to_wb_data;
    reg xclk_to_wb_err;
    reg xclk_to_wb_ack;

    // Instantiate FIFOs
    fifo_sync #(
        .DATA_WIDTH(DW + AW + 1 + DW/8 + 1 + 1),
        .ADDR_WIDTH(LGFIFO)
    ) fifo_wb_to_xclk (
        .clk_wr(i_wb_clk),
        .clk_rd(i_xclk_clk),
        .reset(i_reset),
        .wr_en(fifo_wb_to_xclk_wr_en),
        .full(fifo_wb_to_xclk_full),
        .din(fifo_wb_to_xclk_din),
        .rd_en(fifo_wb_to_xclk_rd_en),
        .empty(fifo_wb_to_xclk_empty),
        .dout(fifo_wb_to_xclk_dout)
    );

    fifo_sync #(
        .DATA_WIDTH(DW + 1 + 1),
        .ADDR_WIDTH(LGFIFO)
    ) fifo_xclk_to_wb (
        .clk_wr(i_xclk_clk),
        .clk_rd(i_wb_clk),
        .reset(i_reset),
        .wr_en(fifo_xclk_to_wb_wr_en),
        .full(fifo_xclk_to_wb_full),
        .din(fifo_xclk_to_wb_din),
        .rd_en(fifo_xclk_to_wb_rd_en),
        .empty(fifo_xclk_to_wb_empty),
        .dout(fifo_xclk_to_wb_dout)
    );

    // Wishbone to XCLK FIFO logic
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            fifo_wb_to_xclk_wr_en <= 0;
            wb_to_xclk_cyc <= 0;
            wb_to_xclk_stb <= 0;
        end else begin
            fifo_wb_to_xclk_wr_en <= (i_wb_cyc && i_wb_stb) && !fifo_wb_to_xclk_full;
            wb_to_xclk_cyc <= i_wb_cyc;
            wb_to_xclk_stb <= i_wb_stb;
            wb_to_xclk_we <= i_wb_we;
            wb_to_xclk_addr <= i_wb_addr;
            wb_to_xclk_data <= i_wb_data;
            wb_to_xclk_sel <= i_wb_sel;
        end
    end

    assign fifo_wb_to_xclk_din = {wb_to_xclk_data, wb_to_xclk_addr, wb_to_xclk_we, wb_to_xclk_sel, wb_to_xclk_cyc, wb_to_xclk_stb};

    assign o_wb_stall = fifo_wb_to_xclk_full;

    // XCLK to Wishbone FIFO logic
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            fifo_xclk_to_wb_wr_en <= 0;
        end else begin
            fifo_xclk_to_wb_wr_en <= i_xclk_ack || i_xclk_err;
        end
    end

    assign fifo_xclk_to_wb_din = {i_xclk_data, i_xclk_err, i_xclk_ack};

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            fifo_xclk_to_wb_rd_en <= 0;
            o_wb_ack <= 0;
            o_wb_err <= 0;
            o_wb_data <= 0;
        end else begin
            fifo_xclk_to_wb_rd_en <= !fifo_xclk_to_wb_empty && !o_wb_ack;
            if (!fifo_xclk_to_wb_empty) begin
                o_wb_data <= fifo_xclk_to_wb_dout[(DW-1):0];
                o_wb_err <= fifo_xclk_to_wb_dout[DW+1];
                o_wb_ack <= fifo_xclk_to_wb_dout[DW];
            end
        end
    end

    // XCLK output logic
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
            o_xclk_we <= 0;
            o_xclk_addr <= 0;
            o_xclk_data <= 0;
            o_xclk_sel <= 0;
        end else if (!fifo_wb_to_xclk_empty && !i_xclk_stall) begin
            o_xclk_cyc <= fifo_wb_to_xclk_dout[DW + AW + 1 + DW/8 + 1 + 1 - 1];
            o_xclk_stb <= fifo_wb_to_xclk_dout[DW + AW + 1 + DW/8 + 1];
            o_xclk_we <= fifo_wb_to_xclk_dout[DW + AW + 1 + DW/8];
            o_xclk_addr <= fifo_wb_to_xclk_dout[DW + AW - 1 : DW];
            o_xclk_data <= fifo_wb_to_xclk_dout[DW - 1 : 0];
            o_xclk_sel <= fifo_wb_to_xclk_dout[DW + AW + 1 + DW/8 - 1 : DW + AW + 1];
        end else begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
        end
    end

    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            fifo_wb_to_xclk_rd_en <= 0;
        end else begin
            fifo_wb_to_xclk_rd_en <= !fifo_wb_to_xclk_empty && !i_xclk_stall;
        end
    end

endmodule

// Synchronous FIFO module
module fifo_sync #(
    parameter DATA_WIDTH = 32,
              ADDR_WIDTH = 5
) (
    input wire clk_wr,
    input wire clk_rd,
    input wire reset,
    input wire wr_en,
    output wire full,
    input wire [DATA_WIDTH-1:0] din,
    input wire rd_en,
    output wire empty,
    output wire [DATA_WIDTH-1:0] dout
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] wr_cnt, rd_cnt;
    reg full_reg, empty_reg;

    always @(posedge clk_wr or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
            wr_cnt <= 0;
            full_reg <= 0;
        end else if (wr_en && !full_reg) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
            wr_cnt <= wr_cnt + 1;
        end
    end

    always @(posedge clk_rd or posedge reset) begin
        if (reset) begin
            rd_ptr <= 0;
            rd_cnt <= 0;
            empty_reg <= 1;
        end else if (rd_en && !empty_reg) begin
            rd_ptr <= rd_ptr + 1;
            rd_cnt <= rd_cnt + 1;
        end
    end

    assign full = (wr_cnt == DEPTH);
    assign empty = (wr_cnt == rd_cnt);
    assign dout = mem[rd_ptr];

endmodule
