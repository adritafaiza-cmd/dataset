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

    // Request FIFO parameters
    localparam FIFO_DEPTH = 2 ** LGFIFO;

    // Wishbone clock domain signals
    reg [LGFIFO:0] wr_ptr_wb = 0, rd_ptr_x = 0;
    reg [AW-1:0] fifo_addr [0:FIFO_DEPTH-1];
    reg [DW-1:0] fifo_data [0:FIFO_DEPTH-1];
    reg [DW/8-1:0] fifo_sel [0:FIFO_DEPTH-1];
    reg fifo_we [0:FIFO_DEPTH-1];
    reg fifo_full, fifo_empty;

    // Synchronizers for read pointer in WB domain
    reg [LGFIFO:0] rd_ptr_x_sync1 = 0, rd_ptr_x_sync2 = 0;

    // X clock domain signals
    reg [LGFIFO:0] wr_ptr_wb_sync1 = 0, wr_ptr_wb_sync2 = 0;
    reg fifo_empty_x;

    // Response FIFO parameters
    reg [LGFIFO:0] wr_ptr_resp = 0, rd_ptr_wb_resp = 0;
    reg [(DW-1):0] resp_fifo [0:FIFO_DEPTH-1];
    reg resp_fifo_full, resp_fifo_empty;

    // Synchronizers for response write pointer in WB domain
    reg [LGFIFO:0] wr_ptr_resp_sync1 = 0, wr_ptr_resp_sync2 = 0;

    // WB side logic
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wr_ptr_wb <= 0;
            rd_ptr_x_sync1 <= 0;
            rd_ptr_x_sync2 <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
            o_wb_stall <= 1;
        end else begin
            // Synchronize read pointer
            rd_ptr_x_sync1 <= rd_ptr_x;
            rd_ptr_x_sync2 <= rd_ptr_x_sync1;

            // Update full and empty
            fifo_full <= (wr_ptr_wb - rd_ptr_x_sync2) >= FIFO_DEPTH;
            fifo_empty <= (wr_ptr_wb == rd_ptr_x_sync2);

            // Stall is based on full
            o_wb_stall <= fifo_full;

            // Write to FIFO when transaction starts
            if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
                fifo_addr[wr_ptr_wb] <= i_wb_addr;
                fifo_data[wr_ptr_wb] <= i_wb_data;
                fifo_sel[wr_ptr_wb] <= i_wb_sel;
                fifo_we[wr_ptr_wb] <= i_wb_we;
                wr_ptr_wb <= wr_ptr_wb + 1;
            end
        end
    end

    // X side logic
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            rd_ptr_x <= 0;
            wr_ptr_wb_sync1 <= 0;
            wr_ptr_wb_sync2 <= 0;
            fifo_empty_x <= 1;
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
            o_xclk_we <= 0;
            o_xclk_addr <= 0;
            o_xclk_data <= 0;
            o_xclk_sel <= 0;
        end else begin
            // Synchronize write pointer
            wr_ptr_wb_sync1 <= wr_ptr_wb;
            wr_ptr_wb_sync2 <= wr_ptr_wb_sync1;

            fifo_empty_x <= (rd_ptr_x == wr_ptr_wb_sync2);

            // Read from FIFO when possible
            if (!fifo_empty_x && !i_xclk_stall) begin
                o_xclk_cyc <= 1;
                o_xclk_stb <= 1;
                o_xclk_we <= fifo_we[rd_ptr_x];
                o_xclk_addr <= fifo_addr[rd_ptr_x];
                o_xclk_data <= fifo_data[rd_ptr_x];
                o_xclk_sel <= fifo_sel[rd_ptr_x];
                rd_ptr_x <= rd_ptr_x + 1;
            end else begin
                o_xclk_cyc <= 0;
                o_xclk_stb <= 0;
            end

            // Handle X response
            if (i_xclk_ack) begin
                resp_fifo[wr_ptr_resp] <= i_xclk_data;
                wr_ptr_resp <= wr_ptr_resp + 1;
            end
        end
    end

    // Response FIFO to WB
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            rd_ptr_wb_resp <= 0;
            resp_fifo_empty <= 1;
            o_wb_ack <= 0;
            o_wb_err <= 0;
            o_wb_data <= 0;
        end else begin
            // Synchronize write pointer from X side
            wr_ptr_resp_sync1 <= wr_ptr_resp;
            wr_ptr_resp_sync2 <= wr_ptr_resp_sync1;
            resp_fifo_empty <= (rd_ptr_wb_resp == wr_ptr_resp_sync2);

            if (!resp_fifo_empty) begin
                o_wb_ack <= 1;
                o_wb_data <= resp_fifo[rd_ptr_wb_resp];
                o_wb_err <= i_xclk_err;
                rd_ptr_wb_resp <= rd_ptr_wb_resp + 1;
            end else begin
                o_wb_ack <= 0;
            end
        end
    end

endmodule
