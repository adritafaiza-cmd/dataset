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

    reg [(AW-1):0] fifo_addr [2**LGFIFO-1:0];
    reg [(DW-1):0] fifo_data [2**LGFIFO-1:0];
    reg [(DW/8-1):0] fifo_sel [2**LGFIFO-1:0];
    reg [LGFIFO-1:0] fifo_count;
    reg [LGFIFO:0] fifo_empty;
    reg [LGFIFO:0] fifo_full;

    reg [LGFIFO-1:0] fifo_read_ptr;
    reg [LGFIFO-1:0] fifo_write_ptr;

    reg wb_valid;
    reg xclk_valid;

    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_stall <= 1'b0;
            o_wb_ack <= 1'b0;
            o_wb_data <= {(DW){1'b0}};
            o_wb_err <= 1'b0;
            o_xclk_cyc <= 1'b0;
            o_xclk_stb <= 1'b0;
            o_xclk_we <= 1'b0;
            o_xclk_addr <= {(AW){1'b0}};
            o_xclk_data <= {(DW){1'b0}};
            o_xclk_sel <= {(DW/8){1'b0}};
            fifo_count <= {(LGFIFO){1'b0}};
            fifo_empty <= {(LGFIFO+1){1'b1}};
            fifo_full <= {(LGFIFO+1){1'b0}};
            fifo_read_ptr <= {(LGFIFO){1'b0}};
            fifo_write_ptr <= {(LGFIFO){1'b0}};
            wb_valid <= 1'b0;
            xclk_valid <= 1'b0;
        end else begin
            if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
                wb_valid <= 1'b1;
                fifo_addr[fifo_write_ptr] <= i_wb_addr;
                fifo_data[fifo_write_ptr] <= i_wb_data;
                fifo_sel[fifo_write_ptr] <= i_wb_sel;
                if (fifo_count == (2**LGFIFO)-1) begin
                    fifo_full <= {(LGFIFO+1){1'b1}};
                end else begin
                    fifo_count <= fifo_count + 1'b1;
                    fifo_write_ptr <= fifo_write_ptr + 1'b1;
                end
            end else begin
                wb_valid <= 1'b0;
            end

            if (i_xclk_ack) begin
                xclk_valid <= 1'b1;
                o_wb_data <= i_xclk_data;
                o_wb_ack <= 1'b1;
                o_wb_err <= i_xclk_err;
            end else begin
                xclk_valid <= 1'b0;
                o_wb_ack <= 1'b0;
                o_wb_err <= 1'b0;
            end

            if (fifo_count > 0 && !i_xclk_stall) begin
                o_xclk_cyc <= 1'b1;
                o_xclk_stb <= 1'b1;
                o_xclk_we <= wb_valid;
                o_xclk_addr <= fifo_addr[fifo_read_ptr];
                o_xclk_data <= fifo_data[fifo_read_ptr];
                o_xclk_sel <= fifo_sel[fifo_read_ptr];
                if (fifo_count == 1) begin
                    fifo_empty <= {(LGFIFO+1){1'b1}};
                end else begin
                    fifo_count <= fifo_count - 1'b1;
                    fifo_read_ptr <= fifo_read_ptr + 1'b1;
                end
            end else begin
                o_xclk_cyc <= 1'b0;
                o_xclk_stb <= 1'b0;
                o_xclk_we <= 1'b0;
                o_xclk_addr <= {(AW){1'b0}};
                o_xclk_data <= {(DW){1'b0}};
                o_xclk_sel <= {(DW/8){1'b0}};
            end

            if (fifo_full) begin
                o_wb_stall <= 1'b1;
            end else begin
                o_wb_stall <= 1'b0;
            end
        end
    end

endmodule
