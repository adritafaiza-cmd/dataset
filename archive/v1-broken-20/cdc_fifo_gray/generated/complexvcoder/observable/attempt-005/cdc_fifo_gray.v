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
    logic [WIDTH-1:0] fifo_out;
    logic [WIDTH-1:0] fifo_out_sync;
    logic [WIDTH-1:0] data_reg;
    logic [LOG_DEPTH-1:0] gray_count;
    logic [LOG_DEPTH-1:0] gray_count_sync;
    logic valid_reg;
    logic valid_sync;
    logic ready_reg;
    logic ready_sync;
    logic [LOG_DEPTH-1:0] write_ptr;
    logic [LOG_DEPTH-1:0] read_ptr;
    logic full_reg;
    logic empty_reg;
    logic [LOG_DEPTH-1:0] count_reg;

    // Gray counter for source side
    gray_counter #(.WIDTH(LOG_DEPTH)) src_gray_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .count_o(gray_count)
    );

    // Gray counter for destination side
    gray_counter #(.WIDTH(LOG_DEPTH)) dst_gray_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .count_o(gray_count_sync)
    );

    // FIFO core
    fifo #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_core (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .gray_count_i(gray_count),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .gray_count_o(gray_count_sync),
        .ready_i(dst_ready_i),
        .fifo_out_o(fifo_out),
        .fifo_valid_o(valid_sync),
        .fifo_ready_o(ready_sync)
    );

    // Synchronous flip-flops for synchronization
    sync_ff #(.WIDTH(WIDTH)) fifo_out_sync_ff (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(fifo_out),
        .data_o(fifo_out_sync)
    );

    sync_ff #(.WIDTH(1)) valid_sync_ff (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(valid_sync),
        .data_o(valid_reg)
    );

    sync_ff #(.WIDTH(1)) ready_sync_ff (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(ready_sync),
        .data_o(ready_reg)
    );

    // FIFO control logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_ptr <= 0;
            count_reg <= 0;
            full_reg <= 0;
            empty_reg <= 1;
        end else begin
            if (src_valid_i && ready_reg) begin
                write_ptr <= write_ptr + 1;
                count_reg <= count_reg + 1;
                if (count_reg == (2**LOG_DEPTH) - 1) begin
                    full_reg <= 1;
                end
                empty_reg <= 0;
            end else if (!dst_ready_i && valid_reg) begin
                write_ptr <= write_ptr;
                count_reg <= count_reg;
                full_reg <= full_reg;
                empty_reg <= 1;
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_ptr <= 0;
        end else begin
            if (valid_reg && dst_ready_i) begin
                read_ptr <= read_ptr + 1;
                count_reg <= count_reg - 1;
                if (count_reg == 0) begin
                    empty_reg <= 1;
                end
                full_reg <= 0;
            end
        end
    end

    // Assign outputs
    assign src_ready_o = ~full_reg;
    assign dst_data_o = fifo_out_sync;
    assign dst_valid_o = valid_reg;

endmodule

module gray_counter #(
    parameter WIDTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    output [WIDTH-1:0]     count_o
);

    logic [WIDTH-1:0] count;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count <= 0;
        end else begin
            count <= count + 1;
        end
    end

    assign count_o = count;

endmodule

module fifo #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     data_i,
    input                  valid_i,
    input  [LOG_DEPTH-1:0] gray_count_i,
    input  [LOG_DEPTH-1:0] gray_count_o,
    input                  ready_i,
    output [WIDTH-1:0]     fifo_out_o,
    output                 fifo_valid_o,
    output                 fifo_ready_o
);

    logic [WIDTH-1:0] mem [0:(2**LOG_DEPTH)-1];
    logic [LOG_DEPTH-1:0] write_ptr;
    logic [LOG_DEPTH-1:0] read_ptr;
    logic [LOG_DEPTH-1:0] count;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            write_ptr <= 0;
            read_ptr <= 0;
            count <= 0;
        end else begin
            if (valid_i && ready_i) begin
                mem[write_ptr] <= data_i;
                write_ptr <= write_ptr + 1;
                count <= count + 1;
            end else if (!ready_i && fifo_valid_o) begin
                write_ptr <= write_ptr;
                count <= count;
            end
        end
    end

    assign fifo_out_o = mem[read_ptr];
    assign fifo_valid_o = (count > 0) && ready_i;
    assign fifo_ready_o = (count < (2**LOG_DEPTH)) && valid_i;

endmodule

module sync_ff #(
    parameter WIDTH = 8
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     data_i,
    output [WIDTH-1:0]     data_o
);

    logic [WIDTH-1:0] data_reg;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_reg <= 0;
        end else begin
            data_reg <= data_i;
        end
    end

    assign data_o = data_reg;

endmodule
