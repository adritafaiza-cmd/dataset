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

        wire wb_req_fifo_full;
        wire wb_req_fifo_empty;
        wire [AW+DW+(DW/8)+2:0] wb_req_fifo_data_out;
        wire wb_req_fifo_read;
        wire wb_req_fifo_write;

        wire xclk_resp_fifo_full;
        wire xclk_resp_fifo_empty;
        wire [DW+1:0] xclk_resp_fifo_data_out;
        wire xclk_resp_fifo_read;
        wire xclk_resp_fifo_write;

        fifo #(
                .WIDTH(AW+DW+(DW/8)+3),
                .DEPTH(1<<LGFIFO)
        ) wb_req_fifo (
                .write_clk(i_wb_clk),
                .reset(i_reset),
                .write_data({i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel}),
                .write_en(wb_req_fifo_write),
                .full(wb_req_fifo_full),
                .read_clk(i_xclk_clk),
                .read_data(wb_req_fifo_data_out),
                .read_en(wb_req_fifo_read),
                .empty(wb_req_fifo_empty)
        );

        fifo #(
                .WIDTH(DW+2),
                .DEPTH(1<<LGFIFO)
        ) xclk_resp_fifo (
                .write_clk(i_xclk_clk),
                .reset(i_reset),
                .write_data({i_xclk_ack, i_xclk_data, i_xclk_err}),
                .write_en(xclk_resp_fifo_write),
                .full(xclk_resp_fifo_full),
                .read_clk(i_wb_clk),
                .read_data(xclk_resp_fifo_data_out),
                .read_en(xclk_resp_fifo_read),
                .empty(xclk_resp_fifo_empty)
        );

        assign o_wb_stall = wb_req_fifo_full;

        always @(posedge i_wb_clk or posedge i_reset) begin
                if (i_reset) begin
                        o_wb_ack <= 0;
                        o_wb_data <= 0;
                        o_wb_err <= 0;
                        wb_req_fifo_write <= 0;
                        xclk_resp_fifo_read <= 0;
                end else begin
                        wb_req_fifo_write <= i_wb_stb && !wb_req_fifo_full;
                        xclk_resp_fifo_read <= !xclk_resp_fifo_empty;

                        if (!xclk_resp_fifo_empty) begin
                                o_wb_ack <= xclk_resp_fifo_data_out[0];
                                o_wb_data <= xclk_resp_fifo_data_out[DW+1:2];
                                o_wb_err <= xclk_resp_fifo_data_out[1];
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
                        wb_req_fifo_read <= 0;
                        xclk_resp_fifo_write <= 0;
                end else begin
                        wb_req_fifo_read <= !wb_req_fifo_empty && !i_xclk_stall;
                        xclk_resp_fifo_write <= i_xclk_ack || i_xclk_err;

                        if (!wb_req_fifo_empty && !i_xclk_stall) begin
                                o_xclk_cyc <= wb_req_fifo_data_out[0];
                                o_xclk_stb <= wb_req_fifo_data_out[1];
                                o_xclk_we <= wb_req_fifo_data_out[2];
                                o_xclk_addr <= wb_req_fifo_data_out[AW+2:3];
                                o_xclk_data <= wb_req_fifo_data_out[AW+DW+2:AW+3];
                                o_xclk_sel <= wb_req_fifo_data_out[AW+DW+3+(DW/8)-1:AW+DW+3];
                        end
                end
        end

endmodule

module fifo #(
        parameter WIDTH = 32,
                DEPTH = 32
) (
        input wire write_clk,
        input wire reset,
        input wire [WIDTH-1:0] write_data,
        input wire write_en,
        output wire full,
        input wire read_clk,
        output reg [WIDTH-1:0] read_data,
        input wire read_en,
        output wire empty
);

        reg [WIDTH-1:0] mem [0:DEPTH-1];
        reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
        reg [$clog2(DEPTH):0] wr_ptr_gray, rd_ptr_gray;
        reg [$clog2(DEPTH):0] wr_ptr_gray_sync, rd_ptr_gray_sync;

        assign full = (wr_ptr_gray_sync == {~rd_ptr_gray[$clog2(DEPTH)], rd_ptr_gray[$clog2(DEPTH)-1:0]});
        assign empty = (wr_ptr_gray_sync == rd_ptr_gray_sync);

        always @(posedge write_clk or posedge reset) begin
                if (reset) begin
                        wr_ptr <= 0;
                        wr_ptr_gray <= 0;
                end else if (write_en && !full) begin
                        mem[wr_ptr[$clog2(DEPTH)-1:0]] <= write_data;
                        wr_ptr <= wr_ptr + 1;
                        wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
                end
        end

        always @(posedge read_clk or posedge reset) begin
                if (reset) begin
                        rd_ptr <= 0;
                        rd_ptr_gray <= 0;
                        rd_ptr_gray_sync <= 0;
                        wr_ptr_gray_sync <= 0;
                end else begin
                        rd_ptr_gray_sync <= wr_ptr_gray;
                        wr_ptr_gray_sync <= rd_ptr_gray;

                        if (read_en && !empty) begin
                                rd_ptr <= rd_ptr + 1;
                                rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);
                        end
                end
        end

        always @(posedge read_clk or posedge reset) begin
                if (reset) begin
                        read_data <= 0;
                end else if (read_en && !empty) begin
                        read_data <= mem[rd_ptr[$clog2(DEPTH)-1:0]];
                end
        end

endmodule
