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

    reg [LGFIFO-1:0] fifo_count;
    reg [AW-1:0] fifo_addr[(1<<LGFIFO)-1:0];
    reg [DW-1:0] fifo_data[(1<<LGFIFO)-1:0];
    reg [(DW/8-1):0] fifo_sel[(1<<LGFIFO)-1:0];
    reg [1:0] fifo_we[(1<<LGFIFO)-1:0];

    reg [LGFIFO-1:0] read_ptr;
    reg [LGFIFO-1:0] write_ptr;

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
            read_ptr <= {(LGFIFO){1'b0}};
            write_ptr <= {(LGFIFO){1'b0}};
        end else begin
            if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
                if (fifo_count < (1<<LGFIFO)-1) begin
                    fifo_addr[write_ptr] <= i_wb_addr;
                    fifo_data[write_ptr] <= i_wb_data;
                    fifo_sel[write_ptr] <= i_wb_sel;
                    fifo_we[write_ptr] <= {i_wb_we, 1'b0};
                    write_ptr <= write_ptr + 1;
                    fifo_count <= fifo_count + 1;
                end
                o_wb_stall <= (fifo_count == (1<<LGFIFO)-1);
            end
            if (i_xclk_ack) begin
                if (fifo_count > 0) begin
                    o_wb_ack <= 1'b1;
                    o_wb_data <= i_xclk_data;
                    o_wb_err <= i_xclk_err;
                    read_ptr <= read_ptr + 1;
                    fifo_count <= fifo_count - 1;
                end
            end else begin
                o_wb_ack <= 1'b0;
            end
            if (i_xclk_stall) begin
                o_xclk_cyc <= 1'b0;
                o_xclk_stb <= 1'b0;
                o_xclk_we <= 1'b0;
                o_xclk_addr <= {(AW){1'b0}};
                o_xclk_data <= {(DW){1'b0}};
                o_xclk_sel <= {(DW/8){1'b0}};
            end else if (fifo_count > 0) begin
                o_xclk_cyc <= 1'b1;
                o_xclk_stb <= 1'b1;
                o_xclk_we <= fifo_we[read_ptr][0];
                o_xclk_addr <= fifo_addr[read_ptr];
                o_xclk_data <= fifo_data[read_ptr];
                o_xclk_sel <= fifo_sel[read_ptr];
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
