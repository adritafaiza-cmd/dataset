module afifo #(
    parameter LGFIFO = 3,
    parameter WIDTH = 16,
    parameter NFF = 2,
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

    localparam DEPTH = 1 << LGFIFO;
    localparam ADDR_WIDTH = LGFIFO;

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg wr_en, rd_en;

    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            wr_ptr <= 0;
            o_wr_full <= 0;
        end else begin
            wr_en <= i_wr && !o_wr_full;
            if (wr_en) begin
                mem[wr_ptr] <= i_wr_data;
                wr_ptr <= wr_ptr + 1;
            end
            if (wr_ptr == DEPTH) begin
                o_wr_full <= 1;
            end else begin
                o_wr_full <= 0;
            end
        end
    end

    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            rd_ptr <= 0;
            o_rd_empty <= 1;
            o_rd_data <= 0;
        end else begin
            rd_en <= i_rd && !o_rd_empty;
            if (rd_en) begin
                o_rd_data <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
            end
            if (rd_ptr == DEPTH) begin
                rd_ptr <= 0;
            end
            if (rd_ptr == wr_ptr) begin
                o_rd_empty <= 1;
            end else begin
                o_rd_empty <= 0;
            end
        end
    end

endmodule
