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

    // FIFO definitions
    wire wb_fifo_full, wb_fifo_empty;
    wire xclk_fifo_full, xclk_fifo_empty;
    wire [(AW + DW + DW/8 + 3 - 1):0] wb_fifo_data_out;
    wire [(DW + 1 - 1):0] xclk_fifo_data_out;

    // FIFO instantiation
    wbxclk_fifo #(.WIDTH(AW + DW + DW/8 + 3), .LGFIFO(LGFIFO))
    wb_to_xclk_fifo (
        .clk(i_wb_clk),
        .reset(i_reset),
        .din({i_wb_addr, i_wb_data, i_wb_sel, i_wb_cyc, i_wb_stb, i_wb_we}),
        .wr_en(i_wb_stb && !wb_fifo_full),
        .rd_en(!xclk_fifo_full && !xclk_fifo_empty && !i_xclk_stall),
        .dout(wb_fifo_data_out),
        .full(wb_fifo_full),
        .empty(wb_fifo_empty)
    );

    wbxclk_fifo #(.WIDTH(DW + 1), .LGFIFO(LGFIFO))
    xclk_to_wb_fifo (
        .clk(i_xclk_clk),
        .reset(i_reset),
        .din({i_xclk_data, i_xclk_err}),
        .wr_en(i_xclk_ack && !xclk_fifo_full),
        .rd_en(!wb_fifo_full && !wb_fifo_empty),
        .dout(xclk_fifo_data_out),
        .full(xclk_fifo_full),
        .empty(xclk_fifo_empty)
    );

    // Register Wishbone inputs for transfer to cross-clock domain
    reg wb_cyc_reg, wb_stb_reg, wb_we_reg;
    reg [(AW-1):0] wb_addr_reg;
    reg [(DW-1):0] wb_data_reg;
    reg [(DW/8-1):0] wb_sel_reg;

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            wb_cyc_reg <= 1'b0;
            wb_stb_reg <= 1'b0;
            wb_we_reg <= 1'b0;
            wb_addr_reg <= {(AW){1'b0}};
            wb_data_reg <= {(DW){1'b0}};
            wb_sel_reg <= {(DW/8){1'b0}};
        end else begin
            wb_cyc_reg <= i_wb_cyc;
            wb_stb_reg <= i_wb_stb;
            wb_we_reg <= i_wb_we;
            wb_addr_reg <= i_wb_addr;
            wb_data_reg <= i_wb_data;
            wb_sel_reg <= i_wb_sel;
        end
    end

    // FIFO data unpacking
    assign o_xclk_cyc = wb_fifo_data_out[AW + DW + DW/8 + 2];
    assign o_xclk_stb = wb_fifo_data_out[AW + DW + DW/8 + 1];
    assign o_xclk_we = wb_fifo_data_out[AW + DW + DW/8];
    assign o_xclk_addr = wb_fifo_data_out[AW + DW + DW/8 - 1 : DW + DW/8];
    assign o_xclk_data = wb_fifo_data_out[DW + DW/8 - 1 : DW/8];
    assign o_xclk_sel = wb_fifo_data_out[DW/8 - 1 : 0];

    // Backpressure signal
    assign o_wb_stall = wb_fifo_full;

    // Acknowledge and error signals from cross-clock domain
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 1'b0;
            o_wb_err <= 1'b0;
            o_wb_data <= {(DW){1'b0}};
        end else if (!wb_fifo_full && !wb_fifo_empty && xclk_fifo_data_out[DW]) begin
            o_wb_ack <= 1'b1;
            o_wb_err <= xclk_fifo_data_out[0];
            o_wb_data <= xclk_fifo_data_out[DW-1:0];
        end else begin
            o_wb_ack <= 1'b0;
            o_wb_err <= 1'b0;
        end
    end

endmodule

// FIFO module
module wbxclk_fifo #(
    parameter WIDTH = 64,
              LGFIFO = 5
) (
    input wire clk,
    input wire reset,
    input wire [WIDTH-1:0] din,
    input wire wr_en,
    input wire rd_en,
    output reg [WIDTH-1:0] dout,
    output reg full,
    output reg empty
);

    reg [WIDTH-1:0] mem [(1<<LGFIFO)-1:0];
    reg [LGFIFO:0] wr_ptr, rd_ptr;
    reg [LGFIFO:0] count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            full <= 1'b0;
            empty <= 1'b1;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
            full <= (count == (1<<LGFIFO));
            empty <= (count == 0);
        end
    end

    always @(*) begin
        dout = mem[rd_ptr];
    end

endmodule
