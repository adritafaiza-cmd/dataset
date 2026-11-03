module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Internal signals
    logic [LOG_DEPTH:0] src_gray_ptr;
    logic [LOG_DEPTH:0] dst_gray_ptr;
    logic [WIDTH-1:0] fifo_mem [2**LOG_DEPTH-1:0];
    logic full, empty;

    // Gray counter for source FIFO pointer
    gray_counter #(.WIDTH(LOG_DEPTH+1)) src_gray_cnt (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .out(src_gray_ptr)
    );

    // Gray counter for destination FIFO pointer
    gray_counter #(.WIDTH(LOG_DEPTH+1)) dst_gray_cnt (
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .out(dst_gray_ptr)
    );

    // FIFO memory to store data
    fifo_memory #(.WIDTH(WIDTH), .DEPTH(2**LOG_DEPTH)) fifo_mem_inst (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .write_addr(src_gray_ptr[LOG_DEPTH:1]),
        .read_addr(dst_gray_ptr[LOG_DEPTH:1]),
        .data_in(src_data_i),
        .data_out(dst_data_o),
        .full(full),
        .empty(empty)
    );

    // Source ready output logic
    assign src_ready_o = ~full;

    // Destination valid output logic
    assign dst_valid_o = ~empty;

endmodule

module gray_counter #(
    parameter WIDTH = 4
)(
    input                  clk,
    input                  rst_n,
    output reg [WIDTH-1:0] out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 0;
        end else begin
            out <= out ^ (out >> 1);
        end
    end

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter DEPTH = 8
)(
    input                  clk,
    input                  rst_n,
    input  [WIDTH-1:0]     data_in,
    output reg [WIDTH-1:0] data_out,
    input  [DEPTH-2:0]     write_addr,
    input  [DEPTH-2:0]     read_addr,
    output                 full,
    output                 empty
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [DEPTH-1:0] wr_ptr, rd_ptr;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (write_addr == read_addr && mem[write_addr] != 0) begin
                full <= 1;
                empty <= 1;
            end else begin
                full <= 0;
                empty <= 0;
                if (write_addr != rd_ptr) begin
                    mem[write_addr] <= data_in;
                    wr_ptr <= write_addr + 1;
                end
                if (rd_ptr != write_addr) begin
                    data_out <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1;
                end
            end
        end
    end

endmodule
