module afifo #(
    parameter LGFIFO = 3,
    parameter WIDTH  = 16,
    parameter NFF    = 2,
    parameter [0:0] WRITE_ON_POSEDGE = 1'b1,
    parameter [0:0] OPT_REGISTER_READS = 1'b1
) (
    input wire i_wclk, i_wr_reset_n, i_wr,
    input wire [WIDTH-1:0] i_wr_data,
    output reg o_wr_full,
    input wire i_rclk, i_rd_reset_n, i_rd,
    output reg [WIDTH-1:0] o_rd_data,
    output reg o_rd_empty
);

    localparam FIFO_DEPTH = 2**LGFIFO;

    reg [LGFIFO:0] wr_ptr, rd_ptr;
    reg [FIFO_DEPTH-1:0][WIDTH-1:0] fifo;
    reg [LGFIFO:0] count;

    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            o_wr_full <= 0;
            count <= 0;
        end else begin
            if (i_wr && !o_wr_full) begin
                fifo[wr_ptr] <= i_wr_data;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == FIFO_DEPTH) begin
                    wr_ptr <= 0;
                end
                count <= count + 1;
                if (count == FIFO_DEPTH) begin
                    o_wr_full <= 1;
                end
            end
        end
    end

    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            rd_ptr <= 0;
            o_rd_empty <= 1;
        end else begin
            if (i_rd && !o_rd_empty) begin
                o_rd_data <= fifo[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == FIFO_DEPTH) begin
                    rd_ptr <= 0;
                end
                count <= count - 1;
                if (count == 0) begin
                    o_rd_empty <= 1;
                end else begin
                    o_rd_empty <= 0;
                end
            end
        end
    end

endmodule
