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
    reg [WIDTH-1:0]       fifo_data [0:2**LOG_DEPTH-1];
    reg [LOG_DEPTH:0]     src_gray_counter;
    reg [LOG_DEPTH:0]     dst_gray_counter;
    reg                   src_valid_sync;
    reg                   dst_ready_sync;

    // Synchronizers
    sync_reg #(.WIDTH(1)) src_valid_sync_inst (
        .sync_reg_valid_i(src_valid_i),
        .sync_clk_i(src_clk_i),
        .sync_rst_ni(src_rst_ni),
        .sync_reg_valid_o(src_valid_sync)
    );

    sync_reg #(.WIDTH(1)) dst_ready_sync_inst (
        .sync_reg_valid_i(dst_ready_i),
        .sync_clk_i(dst_clk_i),
        .sync_rst_ni(dst_rst_ni),
        .sync_reg_valid_o(dst_ready_sync)
    );

    // Gray counters
    gray_counter #(.WIDTH(LOG_DEPTH+1)) src_gray_counter_inst (
        .gray_counter_valid(src_valid_sync),
        .gray_counter_clk(src_clk_i),
        .gray_counter_rst_ni(src_rst_ni),
        .gray_counter_gray(src_gray_counter)
    );

    gray_counter #(.WIDTH(LOG_DEPTH+1)) dst_gray_counter_inst (
        .gray_counter_valid(dst_ready_sync),
        .gray_counter_clk(dst_clk_i),
        .gray_counter_rst_ni(dst_rst_ni),
        .gray_counter_gray(dst_gray_counter)
    );

    // FIFO logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_counter <= 0;
        end else if (src_valid_i && src_ready_sync) begin
            src_gray_counter <= src_gray_counter + 1;
        end else if (dst_ready_sync && src_gray_counter > 0) begin
            src_gray_counter <= src_gray_counter - 1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_counter <= 0;
        end else if (dst_ready_sync && dst_gray_counter > 0) begin
            dst_gray_counter <= dst_gray_counter - 1;
        end else if (src_valid_i && src_ready_sync && dst_gray_counter < 2**LOG_DEPTH) begin
            dst_gray_counter <= dst_gray_counter + 1;
        end
    end

    // FIFO storage
    integer i;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (i = 0; i < 2**LOG_DEPTH; i = i + 1) begin
                fifo_data[i] <= 0;
            end
        end else if (src_valid_i && src_ready_sync && dst_gray_counter < 2**LOG_DEPTH) begin
            fifo_data[dst_gray_counter] <= src_data_i;
        end
    end

    // Output logic
    reg [WIDTH-1:0]       dst_data_reg;
    reg                   dst_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
        end else if (dst_ready_sync && dst_gray_counter > 0) begin
            dst_data_reg <= fifo_data[dst_gray_counter - 1];
            dst_valid_reg <= 1;
        end else begin
            dst_valid_reg <= 0;
        end
    end

    // Assignments to ports
    assign src_ready_o = src_gray_counter < 2**LOG_DEPTH;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule

module sync_reg #(
    parameter WIDTH = 1
)(
    input                  sync_reg_valid_i,
    input                  sync_clk_i,
    input                  sync_rst_ni,
    output                 sync_reg_valid_o
);

    reg [WIDTH-1:0]       sync_reg;

    always @(posedge sync_clk_i or negedge sync_rst_ni) begin
        if (!sync_rst_ni) begin
            sync_reg <= 0;
        end else begin
            sync_reg <= sync_reg_valid_i;
        end
    end

    assign sync_reg_valid_o = sync_reg;

endmodule

module gray_counter #(
    parameter WIDTH = 2
)(
    input                  gray_counter_valid,
    input                  gray_counter_clk,
    input                  gray_counter_rst_ni,
    output reg [WIDTH-1:0]   gray_counter_gray
);

    always @(posedge gray_counter_clk or negedge gray_counter_rst_ni) begin
        if (!gray_counter_rst_ni) begin
            gray_counter_gray <= 0;
        end else if (gray_counter_valid) begin
            gray_counter_gray <= gray_counter_gray + 1;
        end
    end

endmodule
