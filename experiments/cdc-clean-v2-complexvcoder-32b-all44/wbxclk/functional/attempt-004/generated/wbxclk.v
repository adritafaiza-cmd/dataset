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
    reg wb_stall;
    reg xclk_cyc_reg;
    reg xclk_stb_reg;

    // FIFO instances
    fifo_sync #(.DW(AW), .LGFIFO(LGFIFO)) fifo_addr (
        .i_clk(i_wb_clk),
        .i_reset(i_reset),
        .i_data(i_wb_addr),
        .o_clk(i_xclk_clk),
        .o_data(o_xclk_addr)
    );

    fifo_sync #(.DW(DW), .LGFIFO(LGFIFO)) fifo_data (
        .i_clk(i_wb_clk),
        .i_reset(i_reset),
        .i_data(i_wb_data),
        .o_clk(i_xclk_clk),
        .o_data(o_xclk_data)
    );

    fifo_sync #(.DW(DW/8), .LGFIFO(LGFIFO)) fifo_sel (
        .i_clk(i_wb_clk),
        .i_reset(i_reset),
        .i_data(i_wb_sel),
        .o_clk(i_xclk_clk),
        .o_data(o_xclk_sel)
    );

    fifo_sync #(.DW(1), .LGFIFO(LGFIFO)) fifo_we (
        .i_clk(i_wb_clk),
        .i_reset(i_reset),
        .i_data(i_wb_we),
        .o_clk(i_xclk_clk),
        .o_data(o_xclk_we)
    );

    // WB side logic
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_stall <= 0;
            o_wb_ack <= 0;
            o_wb_data <= 0;
            o_wb_err <= 0;
            wb_stall <= 0;
        end else begin
            wb_stall <= fifo_addr.full | fifo_data.full | fifo_sel.full | fifo_we.full;
            o_wb_stall <= wb_stall;

            if (i_wb_cyc && i_wb_stb && !wb_stall) begin
                o_wb_ack <= 0;
                o_wb_err <= 0;
            end

            if (i_xclk_ack) begin
                o_wb_ack <= 1;
                o_wb_err <= i_xclk_err;
                o_wb_data <= i_xclk_data;
            end
        end
    end

    // XCLK side logic
    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_xclk_cyc <= 0;
            o_xclk_stb <= 0;
            xclk_cyc_reg <= 0;
            xclk_stb_reg <= 0;
        end else begin
            if (i_wb_cyc && i_wb_stb && !wb_stall) begin
                xclk_cyc_reg <= 1;
                xclk_stb_reg <= 1;
            end

            if (i_xclk_ack || i_xclk_stall) begin
                xclk_stb_reg <= 0;
            end

            o_xclk_cyc <= xclk_cyc_reg;
            o_xclk_stb <= xclk_stb_reg;
        end
    end

endmodule

module fifo_sync #(
    parameter DW = 32,
              LGFIFO = 5
) (
    input wire i_clk,
    input wire i_reset,
    input wire [DW-1:0] i_data,
    input wire o_clk,
    output reg [DW-1:0] o_data
);

    reg [DW-1:0] mem [0:(1<<LGFIFO)-1];
    reg [LGFIFO-1:0] wr_ptr, rd_ptr;
    reg [LGFIFO:0] count;

    wire full = (count == (1<<LGFIFO));
    wire empty = (count == 0);

    // Write side
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            wr_ptr <= 0;
            count <= 0;
        end else if (i_data_valid && !full) begin
            mem[wr_ptr] <= i_data;
            wr_ptr <= wr_ptr + 1;
            count <= count + 1;
        end
    end

    // Read side
    always @(posedge o_clk or posedge i_reset) begin
        if (i_reset) begin
            rd_ptr <= 0;
            o_data <= 0;
        end else if (o_data_valid && !empty) begin
            o_data <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
            count <= count - 1;
        end
    end

    // Control signals
    assign i_data_valid = !full;
    assign o_data_valid = !empty;

endmodule
