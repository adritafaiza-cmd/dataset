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

    localparam FIFO_DEPTH = 1 << LGFIFO;

    reg [AW-1:0] wb_addr_fifo [0:FIFO_DEPTH-1];
    reg [DW-1:0] wb_data_fifo [0:FIFO_DEPTH-1];
    reg [DW/8-1:0] wb_sel_fifo [0:FIFO_DEPTH-1];
    reg wb_we_fifo [0:FIFO_DEPTH-1];
    reg wb_cyc_fifo [0:FIFO_DEPTH-1];
    reg wb_stb_fifo [0:FIFO_DEPTH-1];
    reg [LGFIFO-1:0] wb_wr_ptr, wb_rd_ptr;
    reg [LGFIFO:0] wb_fifo_count;

    reg [LGFIFO-1:0] xclk_wr_ptr, xclk_rd_ptr;
    reg [LGFIFO:0] xclk_fifo_count;

    reg wb_fifo_full, wb_fifo_empty;
    reg xclk_fifo_full, xclk_fifo_empty;

    // WB side FIFO write logic
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_wr_ptr <= 0;
            wb_fifo_count <= 0;
        end else if (i_wb_cyc && i_wb_stb && !wb_fifo_full) begin
            wb_addr_fifo[wb_wr_ptr] <= i_wb_addr;
            wb_data_fifo[wb_wr_ptr] <= i_wb_data;
            wb_sel_fifo[wb_wr_ptr] <= i_wb_sel;
            wb_we_fifo[wb_wr_ptr] <= i_wb_we;
            wb_cyc_fifo[wb_wr_ptr] <= i_wb_cyc;
            wb_stb_fifo[wb_wr_ptr] <= i_wb_stb;
            wb_wr_ptr <= wb_wr_ptr + 1;
            wb_fifo_count <= wb_fifo_count + 1;
        end
    end

    // WB side FIFO read logic
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_rd_ptr <= 0;
        end else if (!xclk_fifo_full && !wb_fifo_empty) begin
            wb_rd_ptr <= wb_rd_ptr + 1;
            wb_fifo_count <= wb_fifo_count - 1;
        end
    end

    // XCLK side FIFO write logic
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_wr_ptr <= 0;
            xclk_fifo_count <= 0;
        end else if (!xclk_fifo_full && !wb_fifo_empty) begin
            o_xclk_addr <= wb_addr_fifo[wb_rd_ptr];
            o_xclk_data <= wb_data_fifo[wb_rd_ptr];
            o_xclk_sel <= wb_sel_fifo[wb_rd_ptr];
            o_xclk_we <= wb_we_fifo[wb_rd_ptr];
            o_xclk_cyc <= wb_cyc_fifo[wb_rd_ptr];
            o_xclk_stb <= wb_stb_fifo[wb_rd_ptr];
            xclk_wr_ptr <= xclk_wr_ptr + 1;
            xclk_fifo_count <= xclk_fifo_count + 1;
        end
    end

    // XCLK side FIFO read logic
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_rd_ptr <= 0;
        end else if (i_xclk_ack && !xclk_fifo_empty) begin
            xclk_rd_ptr <= xclk_rd_ptr + 1;
            xclk_fifo_count <= xclk_fifo_count - 1;
        end
    end

    // FIFO status flags
    assign wb_fifo_full = (wb_fifo_count == FIFO_DEPTH);
    assign wb_fifo_empty = (wb_fifo_count == 0);
    assign xclk_fifo_full = (xclk_fifo_count == FIFO_DEPTH);
    assign xclk_fifo_empty = (xclk_fifo_count == 0);

    // WB stall signal
    assign o_wb_stall = wb_fifo_full;

    // XCLK side response handling
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 0;
            o_wb_err <= 0;
            o_wb_data <= 0;
        end else if (i_xclk_ack && !xclk_fifo_empty) begin
            o_wb_ack <= 1;
            o_wb_err <= i_xclk_err;
            o_wb_data <= i_xclk_data;
        end else if (o_wb_ack) begin
            o_wb_ack <= 0;
            o_wb_err <= 0;
            o_wb_data <= 0;
        end
    end

endmodule
