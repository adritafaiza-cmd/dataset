module wbxclk #(
    parameter AW = 32,
              DW = 32,
              LGFIFO = 5
) (
    input wire        i_wb_clk, i_reset,
    input wire        i_wb_cyc, i_wb_stb, i_wb_we,
    input wire [(AW-1):0] i_wb_addr,
    input wire [(DW-1):0] i_wb_data,
    input wire [(DW/8-1):0] i_wb_sel,
    output wire        o_wb_stall,
    output reg         o_wb_ack,
    output reg [(DW-1):0] o_wb_data,
    output reg         o_wb_err,
    input wire        i_xclk_clk,
    output reg         o_xclk_cyc,
    output reg         o_xclk_stb,
    output reg         o_xclk_we,
    output reg [(AW-1):0] o_xclk_addr,
    output reg [(DW-1):0] o_xclk_data,
    output reg [(DW/8-1):0] o_xclk_sel,
    input wire        i_xclk_stall,
    input wire        i_xclk_ack,
    input wire [(DW-1):0] i_xclk_data,
    input wire        i_xclk_err
);

    reg [LGFIFO-1:0] wb_fifo_cnt;
    reg [LGFIFO-1:0] xclk_fifo_cnt;
    reg [AW-1:0] wb_fifo_addr[(1<<LGFIFO)-1:0];
    reg [DW-1:0] wb_fifo_data[(1<<LGFIFO)-1:0];
    reg [DW/8-1:0] wb_fifo_sel[(1<<LGFIFO)-1:0];
    reg wb_fifo_we[(1<<LGFIFO)-1:0];
    reg [AW-1:0] xclk_fifo_addr[(1<<LGFIFO)-1:0];
    reg [DW-1:0] xclk_fifo_data[(1<<LGFIFO)-1:0];
    reg [DW/8-1:0] xclk_fifo_sel[(1<<LGFIFO)-1:0];
    reg xclk_fifo_we[(1<<LGFIFO)-1:0];

    reg wb_fifo_empty;
    reg xclk_fifo_empty;
    reg wb_fifo_full;
    reg xclk_fifo_full;

    reg [LGFIFO-1:0] wb_fifo_rptr;
    reg [LGFIFO-1:0] wb_fifo_wptr;
    reg [LGFIFO-1:0] xclk_fifo_rptr;
    reg [LGFIFO-1:0] xclk_fifo_wptr;

    assign o_wb_stall = wb_fifo_full;

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
            wb_fifo_cnt <= {(LGFIFO){1'b0}};
            xclk_fifo_cnt <= {(LGFIFO){1'b0}};
            wb_fifo_rptr <= {(LGFIFO){1'b0}};
            wb_fifo_wptr <= {(LGFIFO){1'b0}};
            xclk_fifo_rptr <= {(LGFIFO){1'b0}};
            xclk_fifo_wptr <= {(LGFIFO){1'b0}};
            wb_fifo_empty <= 1'b1;
            xclk_fifo_empty <= 1'b1;
            wb_fifo_full <= 1'b0;
            xclk_fifo_full <= 1'b0;
        end else begin
            if (i_wb_cyc && i_wb_stb &&!wb_fifo_full) begin
                wb_fifo_addr[wb_fifo_wptr] <= i_wb_addr;
                wb_fifo_data[wb_fifo_wptr] <= i_wb_data;
                wb_fifo_sel[wb_fifo_wptr] <= i_wb_sel;
                wb_fifo_we[wb_fifo_wptr] <= i_wb_we;
                wb_fifo_wptr <= wb_fifo_wptr + 1'b1;
                wb_fifo_cnt <= wb_fifo_cnt + 1'b1;
                wb_fifo_empty <= 1'b0;
                if (wb_fifo_cnt == (1<<LGFIFO)-1) begin
                    wb_fifo_full <= 1'b1;
                end
            end
            if (i_xclk_ack &&!xclk_fifo_empty) begin
                o_wb_ack <= 1'b1;
                o_wb_data <= xclk_fifo_data[xclk_fifo_rptr];
                o_wb_err <= 1'b0;
                xclk_fifo_rptr <= xclk_fifo_rptr + 1'b1;
                xclk_fifo_cnt <= xclk_fifo_cnt - 1'b1;
                xclk_fifo_empty <= (xclk_fifo_cnt == 1'b0);
                if (xclk_fifo_cnt == 1'b0) begin
                    xclk_fifo_full <= 1'b0;
                end
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
            xclk_fifo_cnt <= {(LGFIFO){1'b0}};
            xclk_fifo_rptr <= {(LGFIFO){1'b0}};
            xclk_fifo_wptr <= {(LGFIFO){1'b0}};
            xclk_fifo_empty <= 1'b1;
            xclk_fifo_full <= 1'b0;
        end else begin
            if (!xclk_fifo_empty &&!i_xclk_stall) begin
                o_xclk_cyc <= 1'b1;
                o_xclk_stb <= 1'b1;
                o_xclk_we <= xclk_fifo_we[xclk_fifo_rptr];
                o_xclk_addr <= xclk_fifo_addr[xclk_fifo_rptr];
                o_xclk_data <= xclk_fifo_data[xclk_fifo_rptr];
                o_xclk_sel <= xclk_fifo_sel[xclk_fifo_rptr];
                xclk_fifo_rptr <= xclk_fifo_rptr + 1'b1;
                xclk_fifo_cnt <= xclk_fifo_cnt - 1'b1;
                xclk_fifo_empty <= (xclk_fifo_cnt == 1'b0);
                if (xclk_fifo_cnt == 1'b0) begin
                    xclk_fifo_full <= 1'b0;
                end
            end else begin
                o_xclk_cyc <= 1'b0;
                o_xclk_stb <= 1'b0;
                o_xclk_we <= 1'b0;
                o_xclk_addr <= {(AW){1'b0}};
                o_xclk_data <= {(DW){1'b0}};
                o_xclk_sel <= {(DW/8){1'b0}};
            end
            if (i_xclk_ack &&!xclk_fifo_empty) begin
                xclk_fifo_rptr <= xclk_fifo_rptr + 1'b1;
                xclk_fifo_cnt <= xclk_fifo_cnt - 1'b1;
                xclk_fifo_empty <= (xclk_fifo_cnt == 1'b0);
                if (xclk_fifo_cnt == 1'b0) begin
                    xclk_fifo_full <= 1'b0;
                end
            end
            if (wb_fifo_empty &&!i_xclk_stall) begin
                xclk_fifo_addr[xclk_fifo_wptr] <= wb_fifo_addr[wb_fifo_rptr];
                xclk_fifo_data[xclk_fifo_wptr] <= wb_fifo_data[wb_fifo_rptr];
                xclk_fifo_sel[xclk_fifo_wptr] <= wb_fifo_sel[wb_fifo_rptr];
                xclk_fifo_we[xclk_fifo_wptr] <= wb_fifo_we[wb_fifo_rptr];
                xclk_fifo_wptr <= xclk_fifo_wptr + 1'b1;
                xclk_fifo_cnt <= xclk_fifo_cnt + 1'b1;
                xclk_fifo_empty <= 1'b0;
                if (xclk_fifo_cnt == (1<<LGFIFO)-1) begin
                    xclk_fifo_full <= 1'b1;
                end
                wb_fifo_rptr <= wb_fifo_rptr + 1'b1;
                wb_fifo_cnt <= wb_fifo_cnt - 1'b1;
                wb_fifo_empty <= (wb_fifo_cnt == 1'b0);
                if (wb_fifo_cnt == 1'b0) begin
                    wb_fifo_full <= 1'b0;
                end
            end
        end
    end

endmodule
