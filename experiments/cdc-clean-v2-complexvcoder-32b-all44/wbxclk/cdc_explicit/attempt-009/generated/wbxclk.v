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
    reg wb_xclk_addr_fifo_wr_en, wb_xclk_addr_fifo_full, wb_xclk_addr_fifo_dout_vld;
    reg wb_xclk_data_fifo_wr_en, wb_xclk_data_fifo_full, wb_xclk_data_fifo_dout_vld;
    reg wb_xclk_sel_fifo_wr_en, wb_xclk_sel_fifo_full, wb_xclk_sel_fifo_dout_vld;
    reg wb_xclk_cyc_sync, wb_xclk_stb_sync, wb_xclk_we_sync;
    reg xclk_wb_data_fifo_wr_en, xclk_wb_data_fifo_full, xclk_wb_data_fifo_dout_vld;
    reg xclk_wb_ack_sync, xclk_wb_err_sync;
    wire [AW-1:0] wb_xclk_addr_fifo_dout;
    wire [DW-1:0] wb_xclk_data_fifo_dout;
    wire [(DW/8-1):0] wb_xclk_sel_fifo_dout;
    wire [DW-1:0] xclk_wb_data_fifo_dout;

    // FIFOs
    fifo_sync #(.DW(AW), .LGFIFO(LGFIFO)) wb_xclk_addr_fifo (
        .clk_wr(i_wb_clk),
        .rst_wr(i_reset),
        .wr_en(wb_xclk_addr_fifo_wr_en),
        .full(wb_xclk_addr_fifo_full),
        .din(i_wb_addr),
        .dout(wb_xclk_addr_fifo_dout),
        .clk_rd(i_xclk_clk),
        .rst_rd(i_reset),
        .rd_en(wb_xclk_addr_fifo_rd_en)
    );

    fifo_sync #(.DW(DW), .LGFIFO(LGFIFO)) wb_xclk_data_fifo (
        .clk_wr(i_wb_clk),
        .rst_wr(i_reset),
        .wr_en(wb_xclk_data_fifo_wr_en),
        .full(wb_xclk_data_fifo_full),
        .din(i_wb_data),
        .dout(wb_xclk_data_fifo_dout),
        .clk_rd(i_xclk_clk),
        .rst_rd(i_reset),
        .rd_en(wb_xclk_data_fifo_rd_en)
    );

    fifo_sync #(.DW(DW/8), .LGFIFO(LGFIFO)) wb_xclk_sel_fifo (
        .clk_wr(i_wb_clk),
        .rst_wr(i_reset),
        .wr_en(wb_xclk_sel_fifo_wr_en),
        .full(wb_xclk_sel_fifo_full),
        .din(i_wb_sel),
        .dout(wb_xclk_sel_fifo_dout),
        .clk_rd(i_xclk_clk),
        .rst_rd(i_reset),
        .rd_en(wb_xclk_sel_fifo_rd_en)
    );

    fifo_sync #(.DW(DW), .LGFIFO(LGFIFO)) xclk_wb_data_fifo (
        .clk_wr(i_xclk_clk),
        .rst_wr(i_reset),
        .wr_en(xclk_wb_data_fifo_wr_en),
        .full(xclk_wb_data_fifo_full),
        .din(i_xclk_data),
        .dout(xclk_wb_data_fifo_dout),
        .clk_rd(i_wb_clk),
        .rst_rd(i_reset),
        .rd_en(xclk_wb_data_fifo_rd_en)
    );

    // CDCs
    cdc_sync wb_xclk_cyc_sync_inst (
        .clk_src(i_wb_clk),
        .rst_src(i_reset),
        .din(i_wb_cyc),
        .clk_dst(i_xclk_clk),
        .rst_dst(i_reset),
        .dout(wb_xclk_cyc_sync)
    );

    cdc_sync wb_xclk_stb_sync_inst (
        .clk_src(i_wb_clk),
        .rst_src(i_reset),
        .din(i_wb_stb),
        .clk_dst(i_xclk_clk),
        .rst_dst(i_reset),
        .dout(wb_xclk_stb_sync)
    );

    cdc_sync wb_xclk_we_sync_inst (
        .clk_src(i_wb_clk),
        .rst_src(i_reset),
        .din(i_wb_we),
        .clk_dst(i_xclk_clk),
        .rst_dst(i_reset),
        .dout(wb_xclk_we_sync)
    );

    cdc_sync xclk_wb_ack_sync_inst (
        .clk_src(i_xclk_clk),
        .rst_src(i_reset),
        .din(i_xclk_ack),
        .clk_dst(i_wb_clk),
        .rst_dst(i_reset),
        .dout(xclk_wb_ack_sync)
    );

    cdc_sync xclk_wb_err_sync_inst (
        .clk_src(i_xclk_clk),
        .rst_src(i_reset),
        .din(i_xclk_err),
        .clk_dst(i_wb_clk),
        .rst_dst(i_reset),
        .dout(xclk_wb_err_sync)
    );

    // Control logic
    reg wb_xclk_addr_fifo_rd_en, wb_xclk_data_fifo_rd_en, wb_xclk_sel_fifo_rd_en;
    reg xclk_wb_data_fifo_rd_en;

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_xclk_addr_fifo_wr_en <= 0;
            wb_xclk_data_fifo_wr_en <= 0;
            wb_xclk_sel_fifo_wr_en <= 0;
            wb_xclk_addr_fifo_rd_en <= 0;
            wb_xclk_data_fifo_rd_en <= 0;
            wb_xclk_sel_fifo_rd_en <= 0;
            o_wb_ack <= 0;
            o_wb_err <= 0;
            o_wb_data <= 0;
        end else begin
            wb_xclk_addr_fifo_wr_en <= i_wb_cyc & i_wb_stb & ~wb_xclk_addr_fifo_full;
            wb_xclk_data_fifo_wr_en <= i_wb_cyc & i_wb_stb & ~wb_xclk_data_fifo_full;
            wb_xclk_sel_fifo_wr_en <= i_wb_cyc & i_wb_stb & ~wb_xclk_sel_fifo_full;

            wb_xclk_addr_fifo_rd_en <= wb_xclk_cyc_sync & wb_xclk_stb_sync & ~i_xclk_stall;
            wb_xclk_data_fifo_rd_en <= wb_xclk_cyc_sync & wb_xclk_stb_sync & ~i_xclk_stall;
            wb_xclk_sel_fifo_rd_en <= wb_xclk_cyc_sync & wb_xclk_stb_sync & ~i_xclk_stall;

            if (xclk_wb_ack_sync) begin
                o_wb_ack <= 1;
                o_wb_err <= xclk_wb_err_sync;
                o_wb_data <= xclk_wb_data_fifo_dout;
                xclk_wb_data_fifo_rd_en <= 1;
            end else begin
                o_wb_ack <= 0;
                o_wb_err <= 0;
                o_wb_data <= 0;
                xclk_wb_data_fifo_rd_en <= 0;
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
        end else begin
            o_xclk_cyc <= wb_xclk_cyc_sync;
            o_xclk_stb <= wb_xclk_stb_sync;
            o_xclk_we <= wb_xclk_we_sync;
            o_xclk_addr <= wb_xclk_addr_fifo_dout;
            o_xclk_data <= wb_xclk_data_fifo_dout;
            o_xclk_sel <= wb_xclk_sel_fifo_dout;
        end
    end

    assign o_wb_stall = wb_xclk_addr_fifo_full;

endmodule

module fifo_sync #(
    parameter DW=32,
              LGFIFO=5
) (
    input wire clk_wr, rst_wr,
    input wire wr_en,
    output reg full,
    input wire [DW-1:0] din,
    output reg [DW-1:0] dout,
    input wire clk_rd, rst_rd,
    input wire rd_en
);

    localparam DEPTH = 1 << LGFIFO;
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [LGFIFO:0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray, rd_ptr_gray_sync;

    // Write pointer logic
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en & ~full) begin
            mem[wr_ptr[0+:LGFIFO]] <= din;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr[LGFIFO-1:0] ^ (wr_ptr[LGFIFO-1:0] >> 1);
        end
    end

    // Read pointer logic
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            rd_ptr_gray_sync <= 0;
        end else if (rd_en) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= rd_ptr[LGFIFO-1:0] ^ (rd_ptr[LGFIFO-1:0] >> 1);
        end

        // Synchronize read pointer gray code to write domain
        if (rst_wr) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // Full flag logic
    assign full = (wr_ptr_gray[LGFIFO-1:0] ^ rd_ptr_gray_sync[LGFIFO-1:0]) == {LGFIFO{1'b1}} & (wr_ptr_gray[LGFIFO] ^ rd_ptr_gray_sync[LGFIFO]);

    // Output data
    assign dout = mem[rd_ptr_gray_sync[0+:LGFIFO]];
endmodule

module cdc_sync (
    input wire clk_src, rst_src,
    input wire din,
    input wire clk_dst, rst_dst,
    output reg dout
);

    reg din_sync;

    // Synchronize din to clk_dst domain
    always @(posedge clk_dst or posedge rst_dst) begin
        if (rst_dst) begin
            din_sync <= 0;
            dout <= 0;
        end else begin
            din_sync <= din;
            dout <= din_sync;
        end
    end
endmodule
