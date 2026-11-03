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

    parameter FIFO_SIZE = 2**LGFIFO;
    parameter ADDR_WIDTH = LGFIFO + 1;

    reg [ADDR_WIDTH-1:0] write_pointer;
    reg [ADDR_WIDTH-1:0] read_pointer;
    reg [WIDTH-1:0] fifo [0:FIFO_SIZE-1];

    reg [ADDR_WIDTH-1:0] write_pointer_ff;
    reg [ADDR_WIDTH-1:0] read_pointer_ff;
    reg [WIDTH-1:0] fifo_ff [0:FIFO_SIZE-1];

    reg full_flag;
    reg empty_flag;

    // Write path
    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            write_pointer <= 0;
            full_flag <= 0;
        end else if (i_wr && !full_flag) begin
            fifo[write_pointer] <= i_wr_data;
            write_pointer <= (write_pointer + 1) % FIFO_SIZE;
            if (write_pointer == read_pointer)
                full_flag <= 1;
        end
    end

    // Read path
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            read_pointer <= 0;
            empty_flag <= 1;
        end else if (i_rd && !empty_flag) begin
            o_rd_data <= fifo[read_pointer];
            read_pointer <= (read_pointer + 1) % FIFO_SIZE;
            if (read_pointer == write_pointer)
                empty_flag <= 1;
        end
    end

    // Full/Empty flags
    assign o_wr_full = full_flag;
    assign o_rd_empty = empty_flag;

endmodule
