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

    wire [WIDTH-1:0] src_data_gray;
    wire src_valid_gray;
    wire src_ready_gray;
    wire dst_ready_gray;
    wire [WIDTH-1:0] dst_data_gray;
    wire dst_valid_gray;

    // Gray encoder for source domain
    gray_encoder #(
        .WIDTH(WIDTH)
    ) src_gray_encoder (
        .data_i(src_data_i),
        .gray_o(src_data_gray)
    );

    // Gray decoder for destination domain
    gray_decoder #(
        .WIDTH(WIDTH)
    ) dst_gray_decoder (
        .gray_i(dst_data_gray),
        .data_o(dst_data_o)
    );

    // FIFO synchronization
    fifo_sync #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_sync_inst (
        .src_data_i(src_data_gray),
        .src_valid_i(src_valid_gray),
        .src_ready_o(src_ready_gray),
        .dst_data_i(dst_data_gray),
        .dst_valid_i(dst_valid_gray),
        .dst_ready_o(dst_ready_gray)
    );

    // Gray encoder for destination domain
    gray_encoder #(
        .WIDTH(WIDTH)
    ) dst_gray_encoder (
        .data_i(dst_data_i),
        .gray_o(dst_data_gray)
    );

    // FIFO control logic for source domain
    fifo_control #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_fifo_control (
        .valid_i(src_valid_i),
        .ready_o(src_ready_o),
        .full_o(),
        .empty_o(),
        .write_addr(),
        .read_addr(),
        .write_data(src_data_gray),
        .read_data()
    );

    // FIFO control logic for destination domain
    fifo_control #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_fifo_control (
        .valid_i(dst_valid_i),
        .ready_o(dst_ready_gray),
        .full_o(),
        .empty_o(),
        .write_addr(),
        .read_addr(),
        .write_data(dst_data_gray),
        .read_data()
    );

endmodule

module gray_encoder #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data_i,
    output [WIDTH-1:0] gray_o
);

    assign gray_o = data_i ^ (data_i >> 1);

endmodule

module gray_decoder #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] gray_i,
    output [WIDTH-1:0] data_o
);

    assign data_o = gray_i ^ (gray_i >> 1);

endmodule

module fifo_sync #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input  [WIDTH-1:0] src_data_i,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] dst_data_i,
    input              dst_valid_i,
    output             dst_ready_o
);

    wire [WIDTH-1:0] src_data_synced;
    wire src_valid_synced;
    wire src_ready_synced;
    wire dst_ready_synced;
    wire [WIDTH-1:0] dst_data_synced;
    wire dst_valid_synced;

    // Gray encoder for source domain
    gray_encoder #(
        .WIDTH(WIDTH)
    ) src_gray_encoder (
        .data_i(src_data_i),
        .gray_o(src_data_synced)
    );

    // Gray decoder for destination domain
    gray_decoder #(
        .WIDTH(WIDTH)
    ) dst_gray_decoder (
        .gray_i(dst_data_synced),
        .data_o(dst_data_o)
    );

    // FIFO control logic for source domain
    fifo_control #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_fifo_control (
        .valid_i(src_valid_i),
        .ready_o(src_ready_o),
        .full_o(),
        .empty_o(),
        .write_addr(),
        .read_addr(),
        .write_data(src_data_synced),
        .read_data()
    );

    // FIFO control logic for destination domain
    fifo_control #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_fifo_control (
        .valid_i(dst_valid_i),
        .ready_o(dst_ready_synced),
        .full_o(),
        .empty_o(),
        .write_addr(),
        .read_addr(),
        .write_data(dst_data_synced),
        .read_data()
    );

endmodule

module fifo_control #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input              valid_i,
    output             ready_o,
    output             full_o,
    output             empty_o,
    output [LOG_DEPTH-1:0] write_addr,
    output [LOG_DEPTH-1:0] read_addr,
    input  [WIDTH-1:0] write_data,
    output [WIDTH-1:0] read_data
);

    reg [LOG_DEPTH-1:0] write_ptr;
    reg [LOG_DEPTH-1:0] read_ptr;
    reg [WIDTH-1:0] mem [0:(2**LOG_DEPTH)-1];
    reg [LOG_DEPTH:0] count;

    assign full_o = (count == (2**LOG_DEPTH));
    assign empty_o = (count == 0);

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_ptr <= 0;
            read_ptr <= 0;
            count <= 0;
        end else begin
            if (valid_i && ready_o) begin
                mem[write_ptr] <= write_data;
                write_ptr <= write_ptr + 1;
                count <= count + 1;
            end
            if (dst_ready_i && !empty_o) begin
                read_ptr <= read_ptr + 1;
                count <= count - 1;
            end
        end
    end

    assign write_addr = write_ptr;
    assign read_addr = read_ptr;
    assign read_data = mem[read_ptr];

endmodule
