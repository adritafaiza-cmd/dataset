module wbxclk #(
        parameter AW=32,
                  DW=32,
                  LGFIFO = 5
) (
        input wire            i_wb_clk, i_reset,
        input wire            i_wb_cyc, i_wb_stb, i_wb_we,
        input wire [(AW-1):0] i_wb_addr,
        input wire [(DW-1):0] i_wb_data,
        input wire [(DW/8-1):0] i_wb_sel,
        output wire           o_wb_stall,
        output reg            o_wb_ack,
        output reg [(DW-1):0] o_wb_data,
        output reg            o_wb_err,
        input wire            i_xclk_clk,
        output reg            o_xclk_cyc,
        output reg            o_xclk_stb,
        output reg            o_xclk_we,
        output reg [(AW-1):0] o_xclk_addr,
        output reg [(DW-1):0] o_xclk_data,
        output reg [(DW/8-1):0] o_xclk_sel,
        input wire            i_xclk_stall,
        input wire            i_xclk_ack,
        input wire [(DW-1):0] i_xclk_data,
        input wire            i_xclk_err
);

    // Internal signals
    reg wb2xclk_fifo_wr_en;
    reg wb2xclk_fifo_rd_en;
    wire [(AW + DW + DW/8 + 1 + 1 + 1 - 1):0] wb2xclk_fifo_din;
    wire [(AW + DW + DW/8 + 1 + 1 + 1 - 1):0] wb2xclk_fifo_dout;
    wire wb2xclk_fifo_full;
    wire wb2xclk_fifo_empty;

    reg xclk2wb_fifo_wr_en;
    reg xclk2wb_fifo_rd_en;
    wire [(DW + 1 + 1 - 1):0] xclk2wb_fifo_din;
    wire [(DW + 1 + 1 - 1):0] xclk2wb_fifo_dout;
    wire xclk2wb_fifo_full;
    wire xclk2wb_fifo_empty;

    reg o_wb_stall_reg;
    reg o_wb_ack_reg;
    reg [(DW-1):0] o_wb_data_reg;
    reg o_wb_err_reg;

    reg o_xclk_cyc_reg;
    reg o_xclk_stb_reg;
    reg o_xclk_we_reg;
    reg [(AW-1):0] o_xclk_addr_reg;
    reg [(DW-1):0] o_xclk_data_reg;
    reg [(DW/8-1):0] o_xclk_sel_reg;

    // FIFO instances
    fifo_sync #(
        .DW(AW + DW + DW/8 + 1 + 1 + 1),
        .LG(LGFIFO)
    ) wb2xclk_fifo (
        .clk_wr(i_wb_clk),
        .clk_rd(i_xclk_clk),
        .rst_wr(i_reset),
        .rst_rd(i_reset),
        .wr_en(wb2xclk_fifo_wr_en),
        .rd_en(wb2xclk_fifo_rd_en),
        .din(wb2xclk_fifo_din),
        .dout(wb2xclk_fifo_dout),
        .full(wb2xclk_fifo_full),
        .empty(wb2xclk_fifo_empty)
    );

    fifo_sync #(
        .DW(DW + 1 + 1),
        .LG(LGFIFO)
    ) xclk2wb_fifo (
        .clk_wr(i_xclk_clk),
        .clk_rd(i_wb_clk),
        .rst_wr(i_reset),
        .rst_rd(i_reset),
        .wr_en(xclk2wb_fifo_wr_en),
        .rd_en(xclk2wb_fifo_rd_en),
        .din(xclk2wb_fifo_din),
        .dout(xclk2wb_fifo_dout),
        .full(xclk2wb_fifo_full),
        .empty(xclk2wb_fifo_empty)
    );

    // WB to XCLK FIFO write logic
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb2xclk_fifo_wr_en <= 0;
        end else begin
            wb2xclk_fifo_wr_en <= i_wb_cyc & i_wb_stb & ~wb2xclk_fifo_full;
        end
    end

    // Pack Wishbone inputs into FIFO data
    assign wb2xclk_fifo_din = {i_wb_addr, i_wb_data, i_wb_sel, i_wb_we, i_wb_stb, i_wb_cyc};

    // XCLK to WB FIFO read logic
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk2wb_fifo_rd_en <= 0;
            o_wb_ack_reg <= 0;
            o_wb_data_reg <= 0;
            o_wb_err_reg <= 0;
        end else begin
            xclk2wb_fifo_rd_en <= ~xclk2wb_fifo_empty & i_xclk_ack;
            if (i_xclk_ack) begin
                o_wb_ack_reg <= 1;
                o_wb_data_reg <= xclk2wb_fifo_dout[(DW-1):0];
                o_wb_err_reg <= xclk2wb_fifo_dout[DW];
            end else if (o_wb_ack_reg) begin
                o_wb_ack_reg <= 0;
            end
        end
    end

    // WB stall logic
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_stall_reg <= 0;
        end else begin
            o_wb_stall_reg <= wb2xclk_fifo_full;
        end
    end

    // XCLK to WB FIFO write logic
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk2wb_fifo_wr_en <= 0;
        end else begin
            xclk2wb_fifo_wr_en <= o_xclk_stb_reg & ~i_xclk_stall & ~xclk2wb_fifo_full;
        end
    end

    // Pack XCLK inputs into FIFO data
    assign xclk2wb_fifo_din = {i_xclk_data, i_xclk_err, i_xclk_ack};

    // WB to XCLK FIFO read logic
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            wb2xclk_fifo_rd_en <= 0;
            o_xclk_cyc_reg <= 0;
            o_xclk_stb_reg <= 0;
            o_xclk_we_reg <= 0;
            o_xclk_addr_reg <= 0;
            o_xclk_data_reg <= 0;
            o_xclk_sel_reg <= 0;
        end else begin
            wb2xclk_fifo_rd_en <= ~wb2xclk_fifo_empty & ~o_xclk_stb_reg;
            if (~wb2xclk_fifo_empty) begin
                o_xclk_cyc_reg <= wb2xclk_fifo_dout[(AW + DW + DW/8 + 1 + 1 + 1 - 1)];
                o_xclk_stb_reg <= wb2xclk_fifo_dout[(AW + DW + DW/8 + 1 + 1 + 1 - 2)];
                o_xclk_we_reg <= wb2xclk_fifo_dout[(AW + DW + DW/8 + 1 + 1 + 1 - 3)];
                o_xclk_addr_reg <= wb2xclk_fifo_dout[(AW + DW + DW/8 + 1 + 1 + 1 - 4 -: AW)];
                o_xclk_data_reg <= wb2xclk_fifo_dout[(AW + DW + DW/8 + 1 + 1 + 1 - 4 - AW -: DW)];
                o_xclk_sel_reg <= wb2xclk_fifo_dout[(AW + DW + DW/8 + 1 + 1 + 1 - 4 - AW - DW -: DW/8)];
            end else if (o_xclk_stb_reg & i_xclk_ack) begin
                o_xclk_cyc_reg <= 0;
                o_xclk_stb_reg <= 0;
            end
        end
    end

    // Output assignments
    assign o_wb_stall = o_wb_stall_reg;
    assign o_wb_ack = o_wb_ack_reg;
    assign o_wb_data = o_wb_data_reg;
    assign o_wb_err = o_wb_err_reg;

    assign o_xclk_cyc = o_xclk_cyc_reg;
    assign o_xclk_stb = o_xclk_stb_reg;
    assign o_xclk_we = o_xclk_we_reg;
    assign o_xclk_addr = o_xclk_addr_reg;
    assign o_xclk_data = o_xclk_data_reg;
    assign o_xclk_sel = o_xclk_sel_reg;

endmodule

module fifo_sync #(
    parameter DW = 8,
              LG = 4
) (
    input wire clk_wr,
    input wire clk_rd,
    input wire rst_wr,
    input wire rst_rd,
    input wire wr_en,
    input wire rd_en,
    input wire [DW-1:0] din,
    output wire [DW-1:0] dout,
    output wire full,
    output wire empty
);

    localparam DEPTH = 1 << LG;
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [LG:0] wr_ptr, rd_ptr;
    reg [LG:0] wr_ptr_gray, rd_ptr_gray;
    reg [LG:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Write pointer logic
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en & ~full) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
        end
    end

    // Read pointer logic
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en & ~empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);
        end
    end

    // Gray code synchronization
    always @(posedge clk_wr) begin
        wr_ptr_gray_sync <= wr_ptr_gray;
    end

    always @(posedge clk_rd) begin
        rd_ptr_gray_sync <= rd_ptr_gray;
    end

    // Write operation
    always @(posedge clk_wr) begin
        if (wr_en & ~full) begin
            mem[wr_ptr] <= din;
        end
    end

    // Read operation
    always @(posedge clk_rd) begin
        if (rd_en & ~empty) begin
            dout <= mem[rd_ptr];
        end
    end

    // Full flag
    assign full = (wr_ptr_gray_sync ^ rd_ptr_gray) == {1'b1, {LG{1'b0}}};

    // Empty flag
    assign empty = wr_ptr_gray_sync == rd_ptr_gray_sync;

endmodule
