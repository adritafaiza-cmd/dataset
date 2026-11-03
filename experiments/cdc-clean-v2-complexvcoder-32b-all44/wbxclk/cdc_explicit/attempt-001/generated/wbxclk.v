module wbxclk #(
    parameter AW = 32,
              DW = 32,
              LGFIFO = 5
) (
    input wire i_wb_clk, i_reset,
    input wire i_wb_cyc, i_wb_stb, i_wb_we,
    input wire [AW-1:0] i_wb_addr,
    input wire [DW-1:0] i_wb_data,
    input wire [DW/8-1:0] i_wb_sel,
    output wire o_wb_stall,
    output reg o_wb_ack,
    output reg [DW-1:0] o_wb_data,
    output reg o_wb_err,
    input wire i_xclk_clk,
    output reg o_xclk_cyc,
    output reg o_xclk_stb,
    output reg o_xclk_we,
    output reg [AW-1:0] o_xclk_addr,
    output reg [DW-1:0] o_xclk_data,
    output reg [DW/8-1:0] o_xclk_sel,
    input wire i_xclk_stall,
    input wire i_xclk_ack,
    input wire [DW-1:0] i_xclk_data,
    input wire i_xclk_err
);

    // Internal signals
    reg fifo_addr_wren, fifo_addr_rden;
    reg fifo_data_wren, fifo_data_rden;
    reg fifo_sel_wren, fifo_sel_rden;
    reg fifo_we_wren, fifo_we_rden;
    reg fifo_addr_full, fifo_addr_empty;
    reg fifo_data_full, fifo_data_empty;
    reg fifo_sel_full, fifo_sel_empty;
    reg fifo_we_full, fifo_we_empty;
    reg wb_transfer_active, xclk_transfer_active;
    reg wb_stall_internal, xclk_stall_internal;
    reg wb_ack_internal, wb_err_internal;
    reg xclk_cyc_internal, xclk_stb_internal;
    reg [DW-1:0] xclk_data_internal;

    // FIFO instantiations
    fifo_sync #(.DW(AW), .LGFIFO(LGFIFO)) fifo_addr (
        .clk_wr(i_wb_clk),
        .rst(i_reset),
        .din(i_wb_addr),
        .wren(fifo_addr_wren),
        .clk_rd(i_xclk_clk),
        .rden(fifo_addr_rden),
        .dout(o_xclk_addr),
        .full(fifo_addr_full),
        .empty(fifo_addr_empty)
    );

    fifo_sync #(.DW(DW), .LGFIFO(LGFIFO)) fifo_data (
        .clk_wr(i_wb_clk),
        .rst(i_reset),
        .din(i_wb_data),
        .wren(fifo_data_wren),
        .clk_rd(i_xclk_clk),
        .rden(fifo_data_rden),
        .dout(fifo_data_dout),
        .full(fifo_data_full),
        .empty(fifo_data_empty)
    );

    fifo_sync #(.DW(DW/8), .LGFIFO(LGFIFO)) fifo_sel (
        .clk_wr(i_wb_clk),
        .rst(i_reset),
        .din(i_wb_sel),
        .wren(fifo_sel_wren),
        .clk_rd(i_xclk_clk),
        .rden(fifo_sel_rden),
        .dout(o_xclk_sel),
        .full(fifo_sel_full),
        .empty(fifo_sel_empty)
    );

    fifo_sync #(.DW(1), .LGFIFO(LGFIFO)) fifo_we (
        .clk_wr(i_wb_clk),
        .rst(i_reset),
        .din(i_wb_we),
        .wren(fifo_we_wren),
        .clk_rd(i_xclk_clk),
        .rden(fifo_we_rden),
        .dout(o_xclk_we),
        .full(fifo_we_full),
        .empty(fifo_we_empty)
    );

    // WB side logic
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_transfer_active <= 0;
            wb_stall_internal <= 0;
            o_wb_ack <= 0;
            o_wb_err <= 0;
            fifo_addr_wren <= 0;
            fifo_data_wren <= 0;
            fifo_sel_wren <= 0;
            fifo_we_wren <= 0;
        end else begin
            wb_stall_internal <= fifo_addr_full | fifo_data_full | fifo_sel_full | fifo_we_full;

            if (i_wb_cyc && i_wb_stb && !wb_stall_internal) begin
                wb_transfer_active <= 1;
                fifo_addr_wren <= 1;
                fifo_data_wren <= 1;
                fifo_sel_wren <= 1;
                fifo_we_wren <= 1;
            end else begin
                fifo_addr_wren <= 0;
                fifo_data_wren <= 0;
                fifo_sel_wren <= 0;
                fifo_we_wren <= 0;
            end

            if (wb_transfer_active && i_xclk_ack) begin
                wb_transfer_active <= 0;
                o_wb_ack <= 1;
                o_wb_err <= i_xclk_err;
                o_wb_data <= i_xclk_data;
            end else begin
                o_wb_ack <= 0;
                o_wb_err <= 0;
            end
        end
    end

    // XCLK side logic
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_transfer_active <= 0;
            xclk_stall_internal <= 0;
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
            fifo_addr_rden <= 0;
            fifo_data_rden <= 0;
            fifo_sel_rden <= 0;
            fifo_we_rden <= 0;
        end else begin
            xclk_stall_internal <= i_xclk_stall;

            if (!xclk_transfer_active && !fifo_addr_empty && !fifo_data_empty && !fifo_sel_empty && !fifo_we_empty) begin
                xclk_transfer_active <= 1;
                o_xclk_cyc <= 1;
                o_xclk_stb <= 1;
                fifo_addr_rden <= 1;
                fifo_data_rden <= 1;
                fifo_sel_rden <= 1;
                fifo_we_rden <= 1;
            end else begin
                fifo_addr_rden <= 0;
                fifo_data_rden <= 0;
                fifo_sel_rden <= 0;
                fifo_we_rden <= 0;
            end

            if (xclk_transfer_active && i_xclk_ack) begin
                xclk_transfer_active <= 0;
                o_xclk_cyc <= 0;
                o_xclk_stb <= 0;
            end
        end
    end

    // Output stall signal
    assign o_wb_stall = wb_stall_internal;

endmodule

// Synchronous FIFO module
module fifo_sync #(
    parameter DW = 8,
              LGFIFO = 4
) (
    input wire clk_wr, clk_rd, rst,
    input wire [DW-1:0] din,
    input wire wren, rden,
    output reg [DW-1:0] dout,
    output reg full, empty
);

    localparam DEPTH = 1 << LGFIFO;
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [LGFIFO:0] wr_ptr, rd_ptr;
    reg [LGFIFO:0] wr_ptr_gray, rd_ptr_gray;
    reg [LGFIFO:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Gray code conversion
    function [LGFIFO:0] binary_to_gray;
        input [LGFIFO:0] bin;
        binary_to_gray = bin ^ (bin >> 1);
    endfunction

    // Write pointer logic
    always @(posedge clk_wr or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wren && !full) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= binary_to_gray(wr_ptr + 1);
        end
    end

    // Read pointer logic
    always @(posedge clk_rd or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rden && !empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= binary_to_gray(rd_ptr + 1);
        end
    end

    // Gray code synchronization
    always @(posedge clk_wr or posedge rst) begin
        if (rst) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    always @(posedge clk_rd or posedge rst) begin
        if (rst) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Full and empty flags
    always @(*) begin
        full = (wr_ptr_gray[LGFIFO] != rd_ptr_gray_sync[LGFIFO]) && (wr_ptr_gray[LGFIFO-1:0] == rd_ptr_gray_sync[LGFIFO-1:0]);
        empty = (wr_ptr_gray_sync[LGFIFO] == rd_ptr_gray[LGFIFO]) && (wr_ptr_gray_sync[LGFIFO-1:0] == rd_ptr_gray[LGFIFO-1:0]);
    end

    // Data memory
    always @(posedge clk_wr or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (wren && !full) begin
            mem[wr_ptr[LGFIFO-1:0]] <= din;
        end
    end

    always @(posedge clk_rd or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (rden && !empty) begin
            dout <= mem[rd_ptr[LGFIFO-1:0]];
        end
    end

endmodule
