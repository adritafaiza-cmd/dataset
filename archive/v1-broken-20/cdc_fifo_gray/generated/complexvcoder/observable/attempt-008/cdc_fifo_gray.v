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
    wire [WIDTH-1:0]       fifo_gray_data_out;
    wire                   fifo_gray_valid_out;
    wire                   fifo_gray_ready_in;
    wire [WIDTH-1:0]       fifo_gray_src_to_dst;
    wire                   fifo_gray_dst_to_src;
    wire [LOG_DEPTH-1:0]   gray_counter_src_gray;
    wire [LOG_DEPTH-1:0]   gray_counter_dst_gray;
    wire [LOG_DEPTH-1:0]   gray_counter_src_gray_sync;
    wire [LOG_DEPTH-1:0]   gray_counter_dst_gray_sync;

    // FIFO gray
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_gray_inst (
        .write_en(src_valid_i),
        .data_in(src_data_i),
        .data_out(fifo_gray_data_out),
        .valid_out(fifo_gray_valid_out),
        .read_en(dst_ready_i),
        .rst_ni(src_rst_ni & dst_rst_ni),
        .clk_i(src_clk_i)
    );

    // Gray counter for source side
    gray_counter gray_counter_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .out(gray_counter_src_gray)
    );

    // Gray counter for destination side
    gray_counter gray_counter_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .out(gray_counter_dst_gray)
    );

    // Asynchronous FIFO synchronization
    async_fifo_sync #(
        .WIDTH(WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) async_fifo_sync_inst (
        .src_to_dst(src_data_i),
        .dst_to_src(fifo_gray_src_to_dst)
    );

    // Synchronization for source and destination Gray counters
    sync_reg #(
        .WIDTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_reg_src_gray (
        .in(gray_counter_src_gray),
        .out(gray_counter_src_gray_sync)
    );

    sync_reg #(
        .WIDTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_reg_dst_gray (
        .in(gray_counter_dst_gray),
        .out(gray_counter_dst_gray_sync)
    );

    // Mux for selecting the appropriate data to output
    assign dst_data_o = fifo_gray_data_out;
    assign dst_valid_o = fifo_gray_valid_out & dst_ready_i;

    // Drive ready signals
    assign src_ready_o = ~src_rst_ni & ~fifo_gray_valid_out;

endmodule

module fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  write_en,
    input  [WIDTH-1:0]     data_in,
    output [WIDTH-1:0]     data_out,
    output                 valid_out,
    input                  read_en,
    input                  rst_ni,
    input                  clk_i
);

    // RAM gray
    ram_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) ram_gray_inst (
        .write_en(write_en),
        .data_in(data_in),
        .data_out(data_out),
        .valid_out(valid_out),
        .read_en(read_en),
        .rst_ni(rst_ni),
        .clk_i(clk_i)
    );

endmodule

module gray_counter (
    input                  clk_i,
    input                  rst_ni,
    output [LOG_DEPTH-1:0] out
);

    reg [LOG_DEPTH-1:0] count;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count <= 0;
        end else begin
            count <= count + 1;
        end
    end

    assign out = count ^ (count >> 1);

endmodule

module async_fifo_sync #(
    parameter WIDTH = 8,
    parameter SYNC_STAGES = 2
)(
    input  [WIDTH-1:0]     src_to_dst,
    output [WIDTH-1:0]     dst_to_src
);

    sync_reg #(
        .WIDTH(WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_reg_inst (
        .in(src_to_dst),
        .out(dst_to_src)
    );

endmodule

module ram_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  write_en,
    input  [WIDTH-1:0]     data_in,
    output [WIDTH-1:0]     data_out,
    output                 valid_out,
    input                  read_en,
    input                  rst_ni,
    input                  clk_i
);

    reg [WIDTH-1:0] mem [0:2**LOG_DEPTH-1];
    reg [LOG_DEPTH-1:0] address_in;
    reg [LOG_DEPTH-1:0] address_out;
    reg [WIDTH-1:0] data_out_reg;
    reg valid_out_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            address_in <= 0;
            address_out <= 0;
            data_out_reg <= 0;
            valid_out_reg <= 0;
        end else begin
            if (write_en) begin
                mem[address_in] <= data_in;
                address_in <= address_in + 1;
            end
            if (read_en && address_out < 2**LOG_DEPTH) begin
                data_out_reg <= mem[address_out];
                valid_out_reg <= 1;
                address_out <= address_out + 1;
            end else begin
                valid_out_reg <= 0;
            end
        end
    end

    assign data_out = data_out_reg;
    assign valid_out = valid_out_reg;

endmodule

module sync_reg #(
    parameter WIDTH = 8,
    parameter SYNC_STAGES = 2
)(
    input  [WIDTH-1:0]     in,
    output [WIDTH-1:0]     out
);

    reg [WIDTH-1:0] sync_reg_out;

    always @(posedge clk_i) begin
        sync_reg_out <= in;
    end

    assign out = sync_reg_out;

endmodule
