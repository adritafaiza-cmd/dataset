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
    reg wb_req_fifo_wr_en, wb_req_fifo_rd_en, wb_req_fifo_empty, wb_req_fifo_full;
    reg [AW+DW+(DW/8)+1:0] wb_req_fifo_data_out, wb_req_fifo_wdata;
    reg xclk_req_fifo_wr_en, xclk_req_fifo_rd_en, xclk_req_fifo_empty, xclk_req_fifo_full;
    reg [AW+DW+(DW/8)+1:0] xclk_req_fifo_data_out, xclk_req_fifo_wdata;
    reg wb_ack_fifo_wr_en, wb_ack_fifo_rd_en, wb_ack_fifo_empty, wb_ack_fifo_full;
    reg [DW+1:0] wb_ack_fifo_data_out, wb_ack_fifo_wdata;
    reg wb_stb_reg, wb_cyc_reg, xclk_stb_reg, xclk_cyc_reg;
    reg wb_ack_reg, wb_err_reg;
    reg [DW-1:0] wb_data_reg;
    reg xclk_ack_reg, xclk_err_reg;
    reg [DW-1:0] xclk_data_reg;

    // WB request FIFO
    fifo_sync #(
        .DATA_WIDTH(AW+DW+(DW/8)+2),
        .ADDR_WIDTH(LGFIFO)
    ) wb_req_fifo (
        .clk(i_wb_clk),
        .rst(i_reset),
        .wr_en(wb_req_fifo_wr_en),
        .rd_en(wb_req_fifo_rd_en),
        .data_in(wb_req_fifo_wdata),
        .data_out(wb_req_fifo_data_out),
        .full(wb_req_fifo_full),
        .empty(wb_req_fifo_empty)
    );

    // XCLK request FIFO
    fifo_sync #(
        .DATA_WIDTH(AW+DW+(DW/8)+2),
        .ADDR_WIDTH(LGFIFO)
    ) xclk_req_fifo (
        .clk(i_xclk_clk),
        .rst(i_reset),
        .wr_en(xclk_req_fifo_wr_en),
        .rd_en(xclk_req_fifo_rd_en),
        .data_in(xclk_req_fifo_wdata),
        .data_out(xclk_req_fifo_data_out),
        .full(xclk_req_fifo_full),
        .empty(xclk_req_fifo_empty)
    );

    // WB ack FIFO
    fifo_sync #(
        .DATA_WIDTH(DW+2),
        .ADDR_WIDTH(LGFIFO)
    ) wb_ack_fifo (
        .clk(i_wb_clk),
        .rst(i_reset),
        .wr_en(wb_ack_fifo_wr_en),
        .rd_en(wb_ack_fifo_rd_en),
        .data_in(wb_ack_fifo_wdata),
        .data_out(wb_ack_fifo_data_out),
        .full(wb_ack_fifo_full),
        .empty(wb_ack_fifo_empty)
    );

    // WB to XCLK path
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_stb_reg <= 0;
            wb_cyc_reg <= 0;
            wb_req_fifo_wr_en <= 0;
        end else begin
            wb_stb_reg <= i_wb_stb;
            wb_cyc_reg <= i_wb_cyc;

            if (i_wb_stb && i_wb_cyc && !wb_req_fifo_full) begin
                wb_req_fifo_wdata <= {i_wb_addr, i_wb_data, i_wb_sel, i_wb_we, i_wb_cyc};
                wb_req_fifo_wr_en <= 1;
            end else begin
                wb_req_fifo_wr_en <= 0;
            end
        end
    end

    assign o_wb_stall = wb_req_fifo_full;

    // XCLK to WB path
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            xclk_stb_reg <= 0;
            xclk_cyc_reg <= 0;
            xclk_req_fifo_rd_en <= 0;
            wb_ack_fifo_wr_en <= 0;
        end else begin
            xclk_stb_reg <= o_xclk_stb;
            xclk_cyc_reg <= o_xclk_cyc;

            if (xclk_req_fifo_empty) begin
                xclk_req_fifo_rd_en <= 0;
                o_xclk_cyc <= 0;
                o_xclk_stb <= 0;
            end else begin
                xclk_req_fifo_rd_en <= 1;
                o_xclk_cyc <= xclk_req_fifo_data_out[AW+DW+(DW/8)+1];
                o_xclk_stb <= xclk_req_fifo_data_out[AW+DW+(DW/8)];
                o_xclk_we <= xclk_req_fifo_data_out[AW+DW+(DW/8)-1];
                o_xclk_addr <= xclk_req_fifo_data_out[AW+DW-1:DW];
                o_xclk_data <= xclk_req_fifo_data_out[DW-1:0];
                o_xclk_sel <= xclk_req_fifo_data_out[DW+(DW/8)-1:DW];
            end

            if (i_xclk_ack || i_xclk_err) begin
                wb_ack_fifo_wdata <= {i_xclk_data, i_xclk_err, i_xclk_ack};
                wb_ack_fifo_wr_en <= 1;
            end else begin
                wb_ack_fifo_wr_en <= 0;
            end
        end
    end

    // WB ack path
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_ack_reg <= 0;
            wb_err_reg <= 0;
            wb_data_reg <= 0;
            wb_ack_fifo_rd_en <= 0;
        end else begin
            if (!wb_ack_fifo_empty) begin
                wb_ack_fifo_rd_en <= 1;
                wb_ack_reg <= wb_ack_fifo_data_out[1];
                wb_err_reg <= wb_ack_fifo_data_out[0];
                wb_data_reg <= wb_ack_fifo_data_out[DW+1:2];
            end else begin
                wb_ack_fifo_rd_en <= 0;
            end

            o_wb_ack <= wb_ack_reg;
            o_wb_err <= wb_err_reg;
            o_wb_data <= wb_data_reg;
        end
    end

endmodule

// Synchronous FIFO module
module fifo_sync #(
    parameter DATA_WIDTH = 8,
              ADDR_WIDTH = 4
) (
    input wire clk,
    input wire rst,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg full,
    output reg empty
);

    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Write pointer and read pointer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= data_in;
                wr_ptr <= wr_ptr + 1;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    // Gray code conversion
    assign wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;
    assign rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;

    // Synchronize gray pointers to the read and write domains
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr_gray_sync <= 0;
            rd_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // Calculate full and empty flags
    assign full = (wr_ptr_gray[ADDR_WIDTH] != rd_ptr_gray_sync[ADDR_WIDTH]) && (wr_ptr_gray[ADDR_WIDTH-1:0] == rd_ptr_gray_sync[ADDR_WIDTH-1:0]);
    assign empty = (wr_ptr_gray_sync == rd_ptr_gray);

    // Output data
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 0;
        end else if (rd_en && !empty) begin
            data_out <= mem[rd_ptr[ADDR_WIDTH-1:0]];
        end
    end

endmodule
