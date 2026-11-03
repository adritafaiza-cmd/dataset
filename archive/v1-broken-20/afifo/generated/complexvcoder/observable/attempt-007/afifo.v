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

    // Internal signals
    reg [LGFIFO-1:0] wr_addr, rd_addr;
    reg wr_en, rd_en;
    reg [WIDTH-1:0] wr_data, rd_data;
    reg [LGFIFO:0] count;

    // FIFO memory
    reg [WIDTH-1:0] mem [0:2**LGFIFO-1];

    // FIFO controller
    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            wr_addr <= 0;
            wr_en <= 0;
        end else begin
            wr_en <= i_wr;
            if (i_wr && !o_wr_full) begin
                wr_addr <= wr_addr + 1;
                mem[wr_addr] <= i_wr_data;
            end
        end
    end

    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            rd_addr <= 0;
            rd_en <= 0;
        end else begin
            rd_en <= i_rd;
            if (i_rd && !o_rd_empty) begin
                rd_addr <= rd_addr + 1;
            end
        end
    end

    // Full/empty flags
    assign count = wr_addr - rd_addr;
    assign o_wr_full = (count == (2**LGFIFO - 1));
    assign o_rd_empty = (count == 0);

    // Read data output
    assign o_rd_data = mem[rd_addr];

endmodule
