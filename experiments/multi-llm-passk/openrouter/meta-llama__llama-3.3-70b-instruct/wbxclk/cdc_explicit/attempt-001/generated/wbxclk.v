module wbxclk #(
    parameter AW = 32,
             DW = 32,
             LGFIFO = 5
) (
    input  wire            i_wb_clk, i_reset,
    input  wire            i_wb_cyc, i_wb_stb, i_wb_we,
    input  wire [(AW-1):0]  i_wb_addr,
    input  wire [(DW-1):0]  i_wb_data,
    input  wire [(DW/8-1):0] i_wb_sel,
    output wire            o_wb_stall,
    output reg             o_wb_ack,
    output reg [(DW-1):0]  o_wb_data,
    output reg             o_wb_err,
    input  wire            i_xclk_clk,
    output reg             o_xclk_cyc,
    output reg             o_xclk_stb,
    output reg             o_xclk_we,
    output reg [(AW-1):0]  o_xclk_addr,
    output reg [(DW-1):0]  o_xclk_data,
    output reg [(DW/8-1):0] o_xclk_sel,
    input  wire            i_xclk_stall,
    input  wire            i_xclk_ack,
    input  wire [(DW-1):0]  i_xclk_data,
    input  wire            i_xclk_err
);

    reg [LGFIFO:0] wb_fifo_empty;
    reg [LGFIFO:0] wb_fifo_full;
    reg [LGFIFO:0] xclk_fifo_empty;
    reg [LGFIFO:0] xclk_fifo_full;

    reg [AW-1:0] wb_fifo_addr[(1 << LGFIFO)-1:0];
    reg [DW-1:0] wb_fifo_data[(1 << LGFIFO)-1:0];
    reg [DW/8-1:0] wb_fifo_sel[(1 << LGFIFO)-1:0];
    reg wb_fifo_we[(1 << LGFIFO)-1:0];

    reg [AW-1:0] xclk_fifo_addr[(1 << LGFIFO)-1:0];
    reg [DW-1:0] xclk_fifo_data[(1 << LGFIFO)-1:0];
    reg [DW/8-1:0] xclk_fifo_sel[(1 << LGFIFO)-1:0];
    reg xclk_fifo_we[(1 << LGFIFO)-1:0];

    reg [LGFIFO-1:0] wb_fifo_rd_ptr;
    reg [LGFIFO-1:0] wb_fifo_wr_ptr;
    reg [LGFIFO-1:0] xclk_fifo_rd_ptr;
    reg [LGFIFO-1:0] xclk_fifo_wr_ptr;

    assign o_wb_stall = wb_fifo_full[LGFIFO];

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 1'b0;
            o_wb_data <= {(DW){1'b0}};
            o_wb_err <= 1'b0;
            o_xclk_cyc <= 1'b0;
            o_xclk_stb <= 1'b0;
            o_xclk_we <= 1'b0;
            o_xclk_addr <= {(AW){1'b0}};
            o_xclk_data <= {(DW){1'b0}};
            o_xclk_sel <= {(DW/8){1'b0}};
            wb_fifo_empty <= {(LGFIFO+1){1'b1}};
            wb_fifo_full <= {(LGFIFO+1){1'b0}};
            xclk_fifo_empty <= {(LGFIFO+1){1'b1}};
            xclk_fifo_full <= {(LGFIFO+1){1'b0}};
            wb_fifo_rd_ptr <= {(LGFIFO){1'b0}};
            wb_fifo_wr_ptr <= {(LGFIFO){1'b0}};
            xclk_fifo_rd_ptr <= {(LGFIFO){1'b0}};
            xclk_fifo_wr_ptr <= {(LGFIFO){1'b0}};
        end else begin
            if (i_wb_cyc && i_wb_stb && !wb_fifo_full[LGFIFO]) begin
                wb_fifo_addr[wb_fifo_wr_ptr] <= i_wb_addr;
                wb_fifo_data[wb_fifo_wr_ptr] <= i_wb_data;
                wb_fifo_sel[wb_fifo_wr_ptr] <= i_wb_sel;
                wb_fifo_we[wb_fifo_wr_ptr] <= i_wb_we;
                wb_fifo_wr_ptr <= wb_fifo_wr_ptr + 1'b1;
                wb_fifo_empty <= wb_fifo_empty - 1'b1;
                wb_fifo_full <= wb_fifo_full + 1'b1;
            end

            if (i_xclk_ack && !xclk_fifo_empty[LGFIFO]) begin
                o_wb_ack <= 1'b1;
                o_wb_data <= xclk_fifo_data[xclk_fifo_rd_ptr];
                o_wb_err <= i_xclk_err;
                xclk_fifo_rd_ptr <= xclk_fifo_rd_ptr + 1'b1;
                xclk_fifo_empty <= xclk_fifo_empty + 1'b1;
                xclk_fifo_full <= xclk_fifo_full - 1'b1;
            end else begin
                o_wb_ack <= 1'b0;
            end
        end
    end

    always @(posedge i_xclk_clk or posedge i_reset) begin
        if (i_reset) begin
            o_xclk_cyc <= 1'b0;
            o_xclk_stb <= 1'b0;
            o_xclk_we <= 1'b0;
            o_xclk_addr <= {(AW){1'b0}};
            o_xclk_data <= {(DW){1'b0}};
            o_xclk_sel <= {(DW/8){1'b0}};
            xclk_fifo_empty <= {(LGFIFO+1){1'b1}};
            xclk_fifo_full <= {(LGFIFO+1){1'b0}};
            xclk_fifo_rd_ptr <= {(LGFIFO){1'b0}};
            xclk_fifo_wr_ptr <= {(LGFIFO){1'b0}};
        end else begin
            if (!xclk_fifo_empty[LGFIFO] && !i_xclk_stall) begin
                o_xclk_cyc <= 1'b1;
                o_xclk_stb <= 1'b1;
                o_xclk_we <= wb_fifo_we[wb_fifo_rd_ptr];
                o_xclk_addr <= wb_fifo_addr[wb_fifo_rd_ptr];
                o_xclk_data <= wb_fifo_data[wb_fifo_rd_ptr];
                o_xclk_sel <= wb_fifo_sel[wb_fifo_rd_ptr];
                wb_fifo_rd_ptr <= wb_fifo_rd_ptr + 1'b1;
                wb_fifo_empty <= wb_fifo_empty + 1'b1;
                wb_fifo_full <= wb_fifo_full - 1'b1;
            end else begin
                o_xclk_cyc <= 1'b0;
                o_xclk_stb <= 1'b0;
                o_xclk_we <= 1'b0;
                o_xclk_addr <= {(AW){1'b0}};
                o_xclk_data <= {(DW){1'b0}};
                o_xclk_sel <= {(DW/8){1'b0}};
            end
        end
    end

endmodule
