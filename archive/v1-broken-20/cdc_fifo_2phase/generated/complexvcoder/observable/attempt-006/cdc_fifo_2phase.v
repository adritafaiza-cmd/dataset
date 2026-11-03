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

    localparam FIFO_SIZE = 2**LOG_DEPTH;

    // FIFO core signals
    logic [FIFO_SIZE-1:0] fifo;
    logic [FIFO_SIZE-1:0] wr_ptr;
    logic [FIFO_SIZE-1:0] rd_ptr;
    logic full;
    logic empty;

    // Async FIFO signals
    logic [WIDTH-1:0] async_fifo_data_out;
    logic async_fifo_valid_out;
    logic async_fifo_ready_in;

    // FIFO core
    fifo_core #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_core_inst (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_in(src_data_i),
        .valid_in(src_valid_i),
        .ready_out(src_ready_o),
        .data_out(fifo[wr_ptr]),
        .valid_out(full),
        .ready_in(empty)
    );

    // Async FIFO
    async_fifo #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) async_fifo_inst (
        .src_clk_i(src_clk_i),
        .src_rst_ni(src_rst_ni),
        .src_ready_o(async_fifo_ready_in),
        .dst_clk_i(dst_clk_i),
        .dst_rst_ni(dst_rst_ni),
        .dst_valid_o(dst_valid_o),
        .dst_data_o(dst_data_o),
        .dst_ready_i(dst_ready_i)
    );

    // Write pointer update
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
        end else if (src_valid_i && src_ready_o && !full) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer update
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
        end else if (async_fifo_valid_out && dst_ready_i && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Full and empty flags
    assign full = (wr_ptr + 1 == rd_ptr) || (wr_ptr == FIFO_SIZE-1 && rd_ptr == 0);
    assign empty = wr_ptr == rd_ptr;

endmodule

module fifo_core #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     data_in,
    input                  valid_in,
    output                 ready_out,
    output [WIDTH-1:0]     data_out,
    output                 valid_out,
    input                  ready_in
);

    localparam FIFO_SIZE = 2**LOG_DEPTH;

    logic [FIFO_SIZE-1:0] fifo;
    logic [FIFO_SIZE-1:0] wr_ptr;
    logic [FIFO_SIZE-1:0] rd_ptr;
    logic full;
    logic empty;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (valid_in && !ready_out && !full) begin
                fifo[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
            end
            if (valid_out && ready_in && !empty) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    assign data_out = fifo[rd_ptr];
    assign valid_out = (wr_ptr != rd_ptr);
    assign ready_out = (wr_ptr != rd_ptr);

endmodule

module async_fifo #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_clk_i,
    input                  src_rst_ni,
    input                  src_ready_o,
    input                  dst_clk_i,
    input                  dst_rst_ni,
    output                 dst_valid_o,
    output [WIDTH-1:0]     dst_data_o,
    input                  dst_ready_i
);

    localparam FIFO_SIZE = 2**LOG_DEPTH;

    logic [WIDTH-1:0] fifo [0:FIFO_SIZE-1];
    logic [FIFO_SIZE-1:0] wr_ptr;
    logic [FIFO_SIZE-1:0] rd_ptr;
    logic full;
    logic empty;

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
        end else if (src_ready_o && !full) begin
            fifo[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
        end else if (dst_ready_i && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    assign dst_data_o = fifo[rd_ptr];
    assign dst_valid_o = (wr_ptr != rd_ptr);

endmodule
