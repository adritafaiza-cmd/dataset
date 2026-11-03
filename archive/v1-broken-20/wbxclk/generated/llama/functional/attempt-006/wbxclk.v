module wbxclk #(
    parameter AW = 32,
              DW = 32,
              LGFIFO = 5
) (
    input wire            i_wb_clk, i_reset,
    input wire            i_wb_cyc, i_wb_stb, i_wb_we,
    input wire [(AW-1):0] i_wb_addr,
    input wire [(DW-1):0] i_wb_data,
    input wire [(DW/8-1):0] i_wb_sel,
    output wire           o_wb_stall,
    output reg            o_wb_ack,
    output reg [(DW-1):0] o_wb_data,
    output reg            o_wb_err,
    input wire            i_xclk_clk,
    output reg            o_xclk_cyc,
    output reg            o_xclk_stb,
    output reg            o_xclk_we,
    output reg [(AW-1):0] o_xclk_addr,
    output reg [(DW-1):0] o_xclk_data,
    output reg [(DW/8-1):0] o_xclk_sel,
    input wire            i_xclk_stall,
    input wire            i_xclk_ack,
    input wire [(DW-1):0] i_xclk_data,
    input wire            i_xclk_err
);

    reg [(AW-1):0] fifo_addr[(1<<LGFIFO)-1:0];
    reg [(DW-1):0] fifo_data[(1<<LGFIFO)-1:0];
    reg [(DW/8-1):0] fifo_sel[(1<<LGFIFO)-1:0];
    reg [LGFIFO-1:0] fifo_wr_ptr;
    reg [LGFIFO-1:0] fifo_rd_ptr;
    reg [LGFIFO:0] fifo_count;

    reg [LGFIFO:0] o_wb_stall_reg;

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
            fifo_wr_ptr <= {(LGFIFO){1'b0}};
            fifo_rd_ptr <= {(LGFIFO){1'b0}};
            fifo_count <= {(LGFIFO+1){1'b0}};
            o_wb_stall_reg <= {(LGFIFO+1){1'b0}};
        end else if (i_wb_cyc && i_wb_stb && !o_wb_stall_reg[LGFIFO]) begin
            fifo_addr[fifo_wr_ptr] <= i_wb_addr;
            fifo_data[fifo_wr_ptr] <= i_wb_data;
            fifo_sel[fifo_wr_ptr] <= i_wb_sel;
            fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
            fifo_count <= fifo_count + 1'b1;
            o_wb_stall_reg <= o_wb_stall_reg + 1'b1;
        end else if (i_xclk_ack && fifo_count > 0) begin
            fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
            fifo_count <= fifo_count - 1'b1;
            o_wb_stall_reg <= o_wb_stall_reg - 1'b1;
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
        end else if (!i_xclk_stall && fifo_count > 0) begin
            o_xclk_cyc <= 1'b1;
            o_xclk_stb <= 1'b1;
            o_xclk_we <= i_wb_we;
            o_xclk_addr <= fifo_addr[fifo_rd_ptr];
            o_xclk_data <= fifo_data[fifo_rd_ptr];
            o_xclk_sel <= fifo_sel[fifo_rd_ptr];
        end else begin
            o_xclk_cyc <= 1'b0;
            o_xclk_stb <= 1'b0;
            o_xclk_we <= 1'b0;
            o_xclk_addr <= {(AW){1'b0}};
            o_xclk_data <= {(DW){1'b0}};
            o_xclk_sel <= {(DW/8){1'b0}};
        end
    end

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 1'b0;
            o_wb_data <= {(DW){1'b0}};
            o_wb_err <= 1'b0;
        end else if (i_xclk_ack && fifo_count > 0) begin
            o_wb_ack <= 1'b1;
            o_wb_data <= i_xclk_data;
            o_wb_err <= i_xclk_err;
        end else begin
            o_wb_ack <= 1'b0;
            o_wb_data <= {(DW){1'b0}};
            o_wb_err <= 1'b0;
        end
    end

    assign o_wb_stall = o_wb_stall_reg[LGFIFO];

endmodule
