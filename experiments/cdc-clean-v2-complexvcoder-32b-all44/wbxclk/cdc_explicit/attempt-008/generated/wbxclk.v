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

    wire [(AW-1):0] fifo_addr_dout;
    wire [(DW-1):0] fifo_data_dout;
    wire [(DW/8-1):0] fifo_sel_dout;
    wire fifo_we_dout;
    wire fifo_addr_full, fifo_data_full, fifo_sel_full, fifo_we_full;

    // CDC FIFO for address
    cdc_fifo #(.DW(AW), .LGFIFO(LGFIFO))
    fifo_addr (
        .clk_wr(i_wb_clk),
        .rst_wr(i_reset),
        .wr_en(i_wb_cyc),
        .din(i_wb_addr),
        .clk_rd(i_xclk_clk),
        .rst_rd(i_reset),
        .rd_en(o_xclk_cyc),
        .dout(fifo_addr_dout),
        .full(fifo_addr_full)
    );

    // CDC FIFO for data
    cdc_fifo #(.DW(DW), .LGFIFO(LGFIFO))
    fifo_data (
        .clk_wr(i_wb_clk),
        .rst_wr(i_reset),
        .wr_en(i_wb_stb),
        .din(i_wb_data),
        .clk_rd(i_xclk_clk),
        .rst_rd(i_reset),
        .rd_en(o_xclk_stb),
        .dout(fifo_data_dout),
        .full(fifo_data_full)
    );

    // CDC FIFO for select
    cdc_fifo #(.DW(DW/8), .LGFIFO(LGFIFO))
    fifo_sel (
        .clk_wr(i_wb_clk),
        .rst_wr(i_reset),
        .wr_en(i_wb_stb),
        .din(i_wb_sel),
        .clk_rd(i_xclk_clk),
        .rst_rd(i_reset),
        .rd_en(o_xclk_stb),
        .dout(fifo_sel_dout),
        .full(fifo_sel_full)
    );

    // CDC FIFO for write enable
    cdc_fifo #(.DW(1), .LGFIFO(LGFIFO))
    fifo_we (
        .clk_wr(i_wb_clk),
        .rst_wr(i_reset),
        .wr_en(i_wb_stb),
        .din(i_wb_we),
        .clk_rd(i_xclk_clk),
        .rst_rd(i_reset),
        .rd_en(o_xclk_stb),
        .dout(fifo_we_dout),
        .full(fifo_we_full)
    );

    // Output assignments
    assign o_xclk_addr = fifo_addr_dout;
    assign o_xclk_data = fifo_data_dout;
    assign o_xclk_sel = fifo_sel_dout;
    assign o_xclk_we = fifo_we_dout;

    // Control signals
    assign o_wb_stall = fifo_addr_full | fifo_data_full | fifo_sel_full | fifo_we_full;

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 0;
            o_wb_data <= 0;
            o_wb_err <= 0;
        end else begin
            o_wb_ack <= i_xclk_ack;
            o_wb_data <= i_xclk_data;
            o_wb_err <= i_xclk_err;
        end
    end

    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
        end else begin
            o_xclk_cyc <= i_wb_cyc;
            o_xclk_stb <= i_wb_stb;
        end
    end

endmodule

module cdc_fifo #(
        parameter DW=32,
                  LGFIFO=5
    ) (
        input wire clk_wr, rst_wr, wr_en,
        input wire [DW-1:0] din,
        input wire clk_rd, rst_rd, rd_en,
        output wire [DW-1:0] dout,
        output wire full
    );

    localparam DEPTH = 1 << LGFIFO;
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [LGFIFO:0] wr_ptr, rd_ptr;
    reg [LGFIFO:0] wr_ptr_gray, rd_ptr_gray;
    reg [LGFIFO:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Write pointer logic
    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
        end else if (rd_en && (wr_ptr_gray_sync != rd_ptr_gray)) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Convert pointers to gray code
    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    // Synchronize gray pointers
    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // Write to memory
    always @(posedge clk_wr) begin
        if (wr_en && !full) begin
            mem[wr_ptr[0:LGFIFO-1]] <= din;
        end
    end

    // Read from memory
    always @(posedge clk_rd) begin
        if (rd_en && (wr_ptr_gray_sync != rd_ptr_gray)) begin
            dout <= mem[rd_ptr[0:LGFIFO-1]];
        end
    end

    // Full flag
    assign full = (wr_ptr_gray[LGFIFO] != rd_ptr_gray_sync[LGFIFO]) && (wr_ptr[LGFIFO-1:0] == rd_ptr_gray_sync[LGFIFO-1:0]);

endmodule
