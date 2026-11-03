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

        // FIFO signals
        wire wb_to_xclk_fifo_full, wb_to_xclk_fifo_empty;
        wire [(AW + DW + DW/8 + 2 - 1):0] wb_to_xclk_fifo_data;
        wire xclk_to_wb_fifo_full, xclk_to_wb_fifo_empty;
        wire [(DW + 2 - 1):0] xclk_to_wb_fifo_data;

        // Internal registers
        reg wb_cyc_reg, wb_stb_reg, wb_we_reg;
        reg [(AW-1):0] wb_addr_reg;
        reg [(DW-1):0] wb_data_reg;
        reg [(DW/8-1):0] wb_sel_reg;

        reg xclk_cyc_reg, xclk_stb_reg, xclk_we_reg;
        reg [(AW-1):0] xclk_addr_reg;
        reg [(DW-1):0] xclk_data_reg;
        reg [(DW/8-1):0] xclk_sel_reg;

        // FIFO instantiation
        async_fifo #(
                .DATA_WIDTH(AW + DW + DW/8 + 2),
                .ADDR_WIDTH(LGFIFO)
        ) wb_to_xclk_fifo (
                .rst(i_reset),
                .wr_clk(i_wb_clk),
                .rd_clk(i_xclk_clk),
                .din({i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel}),
                .wr_en(i_wb_stb && !wb_to_xclk_fifo_full),
                .rd_en(xclk_cyc_reg && !i_xclk_stall && i_xclk_ack),
                .dout(wb_to_xclk_fifo_data),
                .full(wb_to_xclk_fifo_full),
                .empty(wb_to_xclk_fifo_empty)
        );

        async_fifo #(
                .DATA_WIDTH(DW + 2),
                .ADDR_WIDTH(LGFIFO)
        ) xclk_to_wb_fifo (
                .rst(i_reset),
                .wr_clk(i_xclk_clk),
                .rd_clk(i_wb_clk),
                .din({i_xclk_data, i_xclk_ack, i_xclk_err}),
                .wr_en(i_xclk_ack),
                .rd_en(o_wb_ack),
                .dout(xclk_to_wb_fifo_data),
                .full(xclk_to_wb_fifo_full),
                .empty(xclk_to_wb_fifo_empty)
        );

        // WB to XCLK path
        always @(posedge i_wb_clk or posedge i_reset) begin
                if (i_reset) begin
                        o_wb_stall <= 1'b0;
                        o_wb_ack <= 1'b0;
                        o_wb_data <= {DW{1'b0}};
                        o_wb_err <= 1'b0;
                end else begin
                        if (i_wb_cyc && i_wb_stb && !wb_to_xclk_fifo_full) begin
                                wb_cyc_reg <= i_wb_cyc;
                                wb_stb_reg <= i_wb_stb;
                                wb_we_reg <= i_wb_we;
                                wb_addr_reg <= i_wb_addr;
                                wb_data_reg <= i_wb_data;
                                wb_sel_reg <= i_wb_sel;
                        end

                        o_wb_stall <= wb_to_xclk_fifo_full;

                        if (xclk_to_wb_fifo_empty) begin
                                o_wb_ack <= 1'b0;
                                o_wb_err <= 1'b0;
                        end else begin
                                o_wb_ack <= xclk_to_wb_fifo_data[DW + 1];
                                o_wb_err <= xclk_to_wb_fifo_data[DW];
                                o_wb_data <= xclk_to_wb_fifo_data[DW-1:0];
                        end
                end
        end

        // XCLK to WB path
        always @(posedge i_xclk_clk or posedge i_reset) begin
                if (i_reset) begin
                        o_xclk_cyc <= 1'b0;
                        o_xclk_stb <= 1'b0;
                        o_xclk_we <= 1'b0;
                        o_xclk_addr <= {AW{1'b0}};
                        o_xclk_data <= {DW{1'b0}};
                        o_xclk_sel <= {DW/8{1'b0}};
                end else begin
                        if (!wb_to_xclk_fifo_empty && !i_xclk_stall) begin
                                o_xclk_cyc <= wb_to_xclk_fifo_data[AW + DW + DW/8 + 1];
                                o_xclk_stb <= wb_to_xclk_fifo_data[AW + DW + DW/8];
                                o_xclk_we <= wb_to_xclk_fifo_data[AW + DW + DW/8 - 1];
                                o_xclk_addr <= wb_to_xclk_fifo_data[AW + DW + DW/8 - 2 -: AW];
                                o_xclk_data <= wb_to_xclk_fifo_data[AW + DW - 1 -: DW];
                                o_xclk_sel <= wb_to_xclk_fifo_data[AW - 1 -: DW/8];
                        end else begin
                                o_xclk_cyc <= 1'b0;
                                o_xclk_stb <= 1'b0;
                                o_xclk_we <= 1'b0;
                        end
                end
        end

endmodule

module async_fifo #(
        parameter DATA_WIDTH = 32,
                  ADDR_WIDTH = 5
) (
        input wire rst,
        input wire wr_clk,
        input wire rd_clk,
        input wire [DATA_WIDTH-1:0] din,
        input wire wr_en,
        input wire rd_en,
        output wire [DATA_WIDTH-1:0] dout,
        output wire full,
        output wire empty
);

        reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
        reg [ADDR_WIDTH:0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray, wr_ptr_gray_sync, rd_ptr_gray_sync;

        // Gray code conversion functions
        function [ADDR_WIDTH:0] bin2gray;
                input [ADDR_WIDTH:0] bin;
                bin2gray = bin ^ (bin >> 1);
        endfunction

        function [ADDR_WIDTH:0] gray2bin;
                input [ADDR_WIDTH:0] gray;
                integer i;
                reg [ADDR_WIDTH:0] bin;
                bin = gray;
                for (i = ADDR_WIDTH-1; i >= 0; i = i - 1)
                        bin[i] = bin[i] ^ bin[i+1];
                gray2bin = bin;
        endfunction

        // Write pointer and memory write
        always @(posedge wr_clk or posedge rst) begin
                if (rst) begin
                        wr_ptr <= 0;
                        wr_ptr_gray <= 0;
                end else if (wr_en && !full) begin
                        mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
                        wr_ptr <= wr_ptr + 1;
                        wr_ptr_gray <= bin2gray(wr_ptr + 1);
                end
        end

        // Read pointer
        always @(posedge rd_clk or posedge rst) begin
                if (rst) begin
                        rd_ptr <= 0;
                        rd_ptr_gray <= 0;
                end else if (rd_en && !empty) begin
                        rd_ptr <= rd_ptr + 1;
                        rd_ptr_gray <= bin2gray(rd_ptr + 1);
                end
        end

        // Gray code synchronization
        always @(posedge wr_clk or posedge rst) begin
                if (rst)
                        rd_ptr_gray_sync <= 0;
                else
                        rd_ptr_gray_sync <= rd_ptr_gray;
        end

        always @(posedge rd_clk or posedge rst) begin
                if (rst)
                        wr_ptr_gray_sync <= 0;
                else
                        wr_ptr_gray_sync <= wr_ptr_gray;
        end

        // Output data
        assign dout = mem[rd_ptr[ADDR_WIDTH-1:0]];

        // Full and empty flags
        assign full = (wr_ptr_gray[ADDR_WIDTH] != rd_ptr_gray_sync[ADDR_WIDTH]) && (wr_ptr_gray[ADDR_WIDTH-1:0] == rd_ptr_gray_sync[ADDR_WIDTH-1:0]);
        assign empty = (wr_ptr_gray_sync[ADDR_WIDTH] == rd_ptr_gray[ADDR_WIDTH]) && (wr_ptr_gray_sync[ADDR_WIDTH-1:0] == rd_ptr_gray[ADDR_WIDTH-1:0]);

endmodule
