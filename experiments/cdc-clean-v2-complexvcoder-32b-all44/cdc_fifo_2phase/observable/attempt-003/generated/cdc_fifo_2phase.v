module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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

    // Internal signals for reset synchronization
    wire sync_src_rst_out;
    wire sync_dst_rst_out;

    // Synchronize source reset to destination clock domain
    sync_ff sync_src_rst (
        .async_rst(~src_rst_ni),
        .clk(dst_clk_i),
        .rst(sync_src_rst_out)
    );

    // Synchronize destination reset to source clock domain
    sync_ff sync_dst_rst (
        .async_rst(~dst_rst_ni),
        .clk(src_clk_i),
        .rst(sync_dst_rst_out)
    );

    // Asynchronous FIFO core
    fifo async_fifo (
        .clk(src_clk_i),
        .rst(sync_src_rst_out),
        .data_in(src_data_i),
        .write_en(src_valid_i),
        .full_n(src_ready_o),
        .clk_read(dst_clk_i),
        .rst_read(sync_dst_rst_out),
        .data_out(dst_data_o),
        .read_en(dst_valid_o),
        .empty_n(dst_ready_i)
    );

endmodule

// Synchronizer flip-flop module
module sync_ff (
    input async_rst,
    input clk,
    output reg rst
);

    reg ff1, ff2;

    always @(posedge clk or negedge async_rst) begin
        if (!async_rst) begin
            ff1 <= 1'b1;
            ff2 <= 1'b1;
            rst <= 1'b1;
        end else begin
            ff1 <= 1'b0;
            ff2 <= ff1;
            rst <= ff2;
        end
    end

endmodule

// FIFO module
module fifo #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input clk,
    input rst,
    input [WIDTH-1:0] data_in,
    input write_en,
    output reg full_n,
    input clk_read,
    input rst_read,
    output reg [WIDTH-1:0] data_out,
    output reg read_en,
    input empty_n
);

    // Gray-coded write and read pointers
    wire [LOG_DEPTH:0] gray_write_ptr;
    wire [LOG_DEPTH:0] gray_read_ptr;

    // Binary write and read pointers
    wire [LOG_DEPTH-1:0] bin_write_ptr;
    wire [LOG_DEPTH-1:0] bin_read_ptr;

    // Gray code counters
    gray_counter write_gray_counter (
        .clk(clk),
        .rst(rst),
        .en(write_en),
        .gray_count(gray_write_ptr)
    );

    gray_counter read_gray_counter (
        .clk(clk_read),
        .rst(rst_read),
        .en(empty_n),
        .gray_count(gray_read_ptr)
    );

    // Gray to binary converters
    gray_to_bin gray_to_bin_write (
        .gray(gray_write_ptr),
        .bin(bin_write_ptr)
    );

    gray_to_bin gray_to_bin_read (
        .gray(gray_read_ptr),
        .bin(bin_read_ptr)
    );

    // Dual-port memory
    memory fifo_memory (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .write_addr(bin_write_ptr),
        .write_en(write_en),
        .read_addr(bin_read_ptr),
        .data_out(data_out)
    );

    // Full and empty flags
    wire [LOG_DEPTH:0] write_ptr_plus_one;
    wire [LOG_DEPTH:0] gray_write_ptr_plus_one;

    assign write_ptr_plus_one = bin_write_ptr + 1;
    assign gray_write_ptr_plus_one = (write_ptr_plus_one ^ (write_ptr_plus_one >> 1));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            full_n <= 1'b1;
        end else begin
            full_n <= ~(gray_write_ptr_plus_one == gray_read_ptr);
        end
    end

    always @(posedge clk_read or posedge rst_read) begin
        if (rst_read) begin
            read_en <= 1'b0;
        end else begin
            read_en <= ~(gray_write_ptr == gray_read_ptr);
        end
    end

endmodule

// Gray code counter module
module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input clk,
    input rst,
    input en,
    output reg [LOG_DEPTH:0] gray_count
);

    reg [LOG_DEPTH:0] count;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            count <= {LOG_DEPTH+1{1'b0}};
            gray_count <= {LOG_DEPTH+1{1'b0}};
        end else if (en) begin
            count <= count + 1;
            gray_count <= (count ^ (count >> 1));
        end
    end

endmodule

// Gray to binary converter module
module gray_to_bin #(
    parameter LOG_DEPTH = 3
)(
    input [LOG_DEPTH:0] gray,
    output reg [LOG_DEPTH-1:0] bin
);

    integer i;

    always @(*) begin
        bin[LOG_DEPTH-1] = gray[LOG_DEPTH];
        for (i = LOG_DEPTH-2; i >= 0; i = i - 1) begin
            bin[i] = gray[i+1] ^ bin[i+1];
        end
    end

endmodule

// Dual-port memory module
module memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input clk,
    input rst,
    input [WIDTH-1:0] data_in,
    input [LOG_DEPTH-1:0] write_addr,
    input write_en,
    input [LOG_DEPTH-1:0] read_addr,
    output reg [WIDTH-1:0] data_out
);

    reg [WIDTH-1:0] mem [0:(2**LOG_DEPTH)-1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= {WIDTH{1'b0}};
            for (integer i = 0; i < (2**LOG_DEPTH); i = i + 1) begin
                mem[i] <= {WIDTH{1'b0}};
            end
        end else begin
            if (write_en) begin
                mem[write_addr] <= data_in;
            end
            data_out <= mem[read_addr];
        end
    end

endmodule
