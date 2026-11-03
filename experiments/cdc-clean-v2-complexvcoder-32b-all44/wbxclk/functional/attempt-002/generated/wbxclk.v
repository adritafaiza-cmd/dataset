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
    wire wb_stall_int;
    wire wb_ack_int;
    wire [DW-1:0] wb_data_int;
    wire wb_err_int;
    wire xclk_cyc_int;
    wire xclk_stb_int;
    wire xclk_we_int;
    wire [AW-1:0] xclk_addr_int;
    wire [DW-1:0] xclk_data_int;
    wire [DW/8-1:0] xclk_sel_int;
    wire xclk_ack_int;
    wire xclk_err_int;

    // FIFO instances
    async_fifo #(.WIDTH(1), .LGFIFO(LGFIFO)) fifo_cyc (
        .i_clk(i_wb_clk),
        .i_reset(i_reset),
        .i_wr_en(i_wb_cyc & i_wb_stb & ~wb_stall_int),
        .i_data(i_wb_cyc),
        .o_full(wb_stall_int),
        .o_data(xclk_cyc_int),
        .i_clk_rd(i_xclk_clk),
        .i_reset_rd(i_reset)
    );

    async_fifo #(.WIDTH(1), .LGFIFO(LGFIFO)) fifo_stb (
        .i_clk(i_wb_clk),
        .i_reset(i_reset),
        .i_wr_en(i_wb_stb & ~wb_stall_int),
        .i_data(i_wb_stb),
        .o_full(wb_stall_int),
        .o_data(xclk_stb_int),
        .i_clk_rd(i_xclk_clk),
        .i_reset_rd(i_reset)
    );

    async_fifo #(.WIDTH(1), .LGFIFO(LGFIFO)) fifo_we (
        .i_clk(i_wb_clk),
        .i_reset(i_reset),
        .i_wr_en(i_wb_stb & ~wb_stall_int),
        .i_data(i_wb_we),
        .o_full(wb_stall_int),
        .o_data(xclk_we_int),
        .i_clk_rd(i_xclk_clk),
        .i_reset_rd(i_reset)
    );

    async_fifo #(.WIDTH(AW), .LGFIFO(LGFIFO)) fifo_addr (
        .i_clk(i_wb_clk),
        .i_reset(i_reset),
        .i_wr_en(i_wb_stb & ~wb_stall_int),
        .i_data(i_wb_addr),
        .o_full(wb_stall_int),
        .o_data(xclk_addr_int),
        .i_clk_rd(i_xclk_clk),
        .i_reset_rd(i_reset)
    );

    async_fifo #(.WIDTH(DW), .LGFIFO(LGFIFO)) fifo_data (
        .i_clk(i_wb_clk),
        .i_reset(i_reset),
        .i_wr_en(i_wb_stb & ~wb_stall_int),
        .i_data(i_wb_data),
        .o_full(wb_stall_int),
        .o_data(xclk_data_int),
        .i_clk_rd(i_xclk_clk),
        .i_reset_rd(i_reset)
    );

    async_fifo #(.WIDTH(DW/8), .LGFIFO(LGFIFO)) fifo_sel (
        .i_clk(i_wb_clk),
        .i_reset(i_reset),
        .i_wr_en(i_wb_stb & ~wb_stall_int),
        .i_data(i_wb_sel),
        .o_full(wb_stall_int),
        .o_data(xclk_sel_int),
        .i_clk_rd(i_xclk_clk),
        .i_reset_rd(i_reset)
    );

    async_fifo #(.WIDTH(1), .LGFIFO(LGFIFO)) fifo_ack (
        .i_clk(i_xclk_clk),
        .i_reset(i_reset),
        .i_wr_en(i_xclk_ack),
        .i_data(i_xclk_ack),
        .o_full(),
        .o_data(wb_ack_int),
        .i_clk_rd(i_wb_clk),
        .i_reset_rd(i_reset)
    );

    async_fifo #(.WIDTH(1), .LGFIFO(LGFIFO)) fifo_err (
        .i_clk(i_xclk_clk),
        .i_reset(i_reset),
        .i_wr_en(i_xclk_err),
        .i_data(i_xclk_err),
        .o_full(),
        .o_data(wb_err_int),
        .i_clk_rd(i_wb_clk),
        .i_reset_rd(i_reset)
    );

    // Output assignments
    assign o_wb_stall = wb_stall_int;
    assign o_wb_ack = wb_ack_int;
    assign o_wb_err = wb_err_int;
    assign o_wb_data = wb_data_int;

    // Cross-clock domain outputs
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
            o_xclk_we <= 0;
            o_xclk_addr <= 0;
            o_xclk_data <= 0;
            o_xclk_sel <= 0;
        end else begin
            o_xclk_cyc <= xclk_cyc_int;
            o_xclk_stb <= xclk_stb_int;
            o_xclk_we <= xclk_we_int;
            o_xclk_addr <= xclk_addr_int;
            o_xclk_data <= xclk_data_int;
            o_xclk_sel <= xclk_sel_int;
        end
    end

    // Cross-clock domain inputs
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_data_int <= 0;
        end else if (wb_ack_int) begin
            wb_data_int <= i_xclk_data;
        end
    end

endmodule

// Async FIFO module
module async_fifo #(
        parameter WIDTH = 8,
                  LGFIFO = 4
    ) (
        input wire i_clk,
        input wire i_reset,
        input wire i_wr_en,
        input wire [WIDTH-1:0] i_data,
        output wire o_full,
        output wire [WIDTH-1:0] o_data,
        input wire i_clk_rd,
        input wire i_reset_rd
    );

    localparam DEPTH = 1 << LGFIFO;
    localparam AW = LGFIFO;

    reg [WIDTH-1:0] mem [DEPTH-1:0];
    reg [AW:0] wr_ptr, rd_ptr;
    reg [AW:0] wr_ptr_gray, rd_ptr_gray;
    reg [AW:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Write pointer logic
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset)
            wr_ptr <= 0;
        else if (i_wr_en & ~o_full)
            wr_ptr <= wr_ptr + 1;
    end

    // Read pointer logic
    always @(posedge i_clk_rd or posedge i_reset_rd) begin
        if (i_reset_rd)
            rd_ptr <= 0;
        else if (i_xclk_ack & ~i_xclk_stall)
            rd_ptr <= rd_ptr + 1;
    end

    // Binary to Gray conversion
    assign wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;
    assign rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;

    // Gray to binary conversion and synchronization
    always @(posedge i_clk_rd or posedge i_reset_rd) begin
        if (i_reset_rd)
            wr_ptr_gray_sync <= 0;
        else
            wr_ptr_gray_sync <= wr_ptr_gray;
    end

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset)
            rd_ptr_gray_sync <= 0;
        else
            rd_ptr_gray_sync <= rd_ptr_gray;
    end

    // FIFO full condition
    assign o_full = (wr_ptr_gray_sync[AW-1:0] == {~rd_ptr_gray[AW-1:0], rd_ptr_gray[AW-2:0]}) & (wr_ptr_gray_sync[AW] != rd_ptr_gray[AW]);

    // Write data to memory
    always @(posedge i_clk) begin
        if (i_wr_en & ~o_full)
            mem[wr_ptr[AW-1:0]] <= i_data;
    end

    // Read data from memory
    assign o_data = mem[rd_ptr[AW-1:0]];

endmodule
