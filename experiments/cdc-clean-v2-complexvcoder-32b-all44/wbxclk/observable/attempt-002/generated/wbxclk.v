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

    // Internal signals for FIFOs
    reg [DW+AW+3:0] wb_to_xclk_fifo_data_in;
    reg wb_to_xclk_fifo_wren;
    reg wb_to_xclk_fifo_full;
    reg [DW+AW+3:0] wb_to_xclk_fifo_data_out;
    reg wb_to_xclk_fifo_rden;
    reg wb_to_xclk_fifo_empty;

    reg [DW+2:0] xclk_to_wb_fifo_data_in;
    reg xclk_to_wb_fifo_wren;
    reg xclk_to_wb_fifo_full;
    reg [DW+2:0] xclk_to_wb_fifo_data_out;
    reg xclk_to_wb_fifo_rden;
    reg xclk_to_wb_fifo_empty;

    // Instantiate the cross-domain FIFOs
    cdc_fifo #(
        .DATA_WIDTH(DW+AW+4),
        .FIFO_DEPTH(2**LGFIFO)
    ) wb_to_xclk_fifo (
        .clk(i_wb_clk),
        .reset(i_reset),
        .data_in(wb_to_xclk_fifo_data_in),
        .wren(wb_to_xclk_fifo_wren),
        .full(wb_to_xclk_fifo_full),
        .clk_out(i_xclk_clk),
        .data_out(wb_to_xclk_fifo_data_out),
        .rden(wb_to_xclk_fifo_rden),
        .empty(wb_to_xclk_fifo_empty)
    );

    cdc_fifo #(
        .DATA_WIDTH(DW+3),
        .FIFO_DEPTH(2**LGFIFO)
    ) xclk_to_wb_fifo (
        .clk(i_xclk_clk),
        .reset(i_reset),
        .data_in(xclk_to_wb_fifo_data_in),
        .wren(xclk_to_wb_fifo_wren),
        .full(xclk_to_wb_fifo_full),
        .clk_out(i_wb_clk),
        .data_out(xclk_to_wb_fifo_data_out),
        .rden(xclk_to_wb_fifo_rden),
        .empty(xclk_to_wb_fifo_empty)
    );

    // Drive the FIFO input for Wishbone to XCLK
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_to_xclk_fifo_wren <= 0;
        end else begin
            wb_to_xclk_fifo_wren <= ~wb_to_xclk_fifo_full & i_wb_cyc & i_wb_stb;
        end
    end

    always @(posedge i_wb_clk) begin
        wb_to_xclk_fifo_data_in[0] <= i_wb_cyc;
        wb_to_xclk_fifo_data_in[1] <= i_wb_stb;
        wb_to_xclk_fifo_data_in[2] <= i_wb_we;
        wb_to_xclk_fifo_data_in[3:AW+2] <= i_wb_addr;
        wb_to_xclk_fifo_data_in[AW+3:AW+DW+2] <= i_wb_data;
        wb_to_xclk_fifo_data_in[AW+DW+3:AW+DW+(DW/8)+2] <= i_wb_sel;
    end

    // Drive the FIFO read for Wishbone to XCLK
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_to_xclk_fifo_rden <= 0;
        end else begin
            wb_to_xclk_fifo_rden <= ~wb_to_xclk_fifo_empty & ~i_xclk_stall;
        end
    end

    // Drive the XCLK outputs from the FIFO
    always @(posedge i_xclk_clk) begin
        o_xclk_cyc <= wb_to_xclk_fifo_data_out[0];
        o_xclk_stb <= wb_to_xclk_fifo_data_out[1];
        o_xclk_we <= wb_to_xclk_fifo_data_out[2];
        o_xclk_addr <= wb_to_xclk_fifo_data_out[3:AW+2];
        o_xclk_data <= wb_to_xclk_fifo_data_out[AW+3:AW+DW+2];
        o_xclk_sel <= wb_to_xclk_fifo_data_out[AW+DW+3:AW+DW+(DW/8)+2];
    end

    // Drive the FIFO input for XCLK to Wishbone
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_to_wb_fifo_wren <= 0;
        end else begin
            xclk_to_wb_fifo_wren <= ~xclk_to_wb_fifo_full & (o_xclk_cyc | i_xclk_err);
        end
    end

    always @(posedge i_xclk_clk) begin
        xclk_to_wb_fifo_data_in[0] <= o_xclk_cyc;
        xclk_to_wb_fifo_data_in[1] <= o_xclk_stb;
        xclk_to_wb_fifo_data_in[2:DW+1] <= i_xclk_data;
        xclk_to_wb_fifo_data_in[DW+2] <= i_xclk_err;
    end

    // Drive the FIFO read for XCLK to Wishbone
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_to_wb_fifo_rden <= 0;
        end else begin
            xclk_to_wb_fifo_rden <= ~xclk_to_wb_fifo_empty;
        end
    end

    // Drive the Wishbone outputs from the FIFO
    always @(posedge i_wb_clk) begin
        o_wb_ack <= xclk_to_wb_fifo_data_out[0];
        o_wb_data <= xclk_to_wb_fifo_data_out[2:DW+1];
        o_wb_err <= xclk_to_wb_fifo_data_out[DW+2];
    end

    // Drive the stall output
    assign o_wb_stall = wb_to_xclk_fifo_full;

endmodule

module cdc_fifo #(
    parameter DATA_WIDTH = 36,
              FIFO_DEPTH = 32
) (
    input wire clk, reset,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire wren,
    output wire full,
    input wire clk_out,
    output reg [DATA_WIDTH-1:0] data_out,
    input wire rden,
    output reg empty
);

    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray, rd_ptr_gray_sync, wr_ptr_gray_sync;

    // Write pointer logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
        end else if (wren & ~full) begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Gray code conversion for write pointer
    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);

    // Synchronize write pointer gray code to read clock domain
    always @(posedge clk_out or posedge reset) begin
        if (reset) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Read pointer logic
    always @(posedge clk_out or posedge reset) begin
        if (reset) begin
            rd_ptr <= 0;
        end else if (rden & ~empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Gray code conversion for read pointer
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    // Synchronize read pointer gray code to write clock domain
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // Binary conversion for synchronized read pointer
    reg [$clog2(FIFO_DEPTH)-1:0] rd_ptr_sync;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rd_ptr_sync <= 0;
        end else begin
            rd_ptr_sync <= rd_ptr_sync + (rd_ptr_gray_sync ^ rd_ptr_sync);
        end
    end

    // Binary conversion for synchronized write pointer
    reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr_sync;
    always @(posedge clk_out or posedge reset) begin
        if (reset) begin
            wr_ptr_sync <= 0;
        end else begin
            wr_ptr_sync <= wr_ptr_sync + (wr_ptr_gray_sync ^ wr_ptr_sync);
        end
    end

    // Output data from memory
    always @(posedge clk_out) begin
        data_out <= mem[rd_ptr];
    end

    // Full and empty flags
    assign full = (wr_ptr_gray == {wr_ptr_gray[$clog2(FIFO_DEPTH)-1], ~rd_ptr_gray_sync[$clog2(FIFO_DEPTH)-1], rd_ptr_gray_sync[$clog2(FIFO_DEPTH)-2:0]});
    assign empty = (rd_ptr_gray == {rd_ptr_gray[$clog2(FIFO_DEPTH)-1], ~wr_ptr_gray_sync[$clog2(FIFO_DEPTH)-1], wr_ptr_gray_sync[$clog2(FIFO_DEPTH)-2:0]});

endmodule
