module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Synchronize clear signals across clock domains
    sync_reg #(.WIDTH(1)) src_clear_sync (
        .sync_in(src_clear_i),
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .sync_out(src_clear_sync_o)
    );

    sync_reg #(.WIDTH(1)) dst_clear_sync (
        .sync_in(dst_clear_i),
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .sync_out(dst_clear_sync_o)
    );

    // Synchronize valid and ready signals across clock domains
    sync_reg #(.WIDTH(1)) src_valid_sync (
        .sync_in(src_valid_i),
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .sync_out(src_valid_sync_o)
    );

    sync_reg #(.WIDTH(1)) dst_ready_sync (
        .sync_in(dst_ready_i),
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .sync_out(dst_ready_sync_o)
    );

    // Generate gray counter for source side
    gray_counter #(.WIDTH(LOG_DEPTH)) src_counter (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .clear(src_clear_sync_o),
        .counter_out(src_counter_out)
    );

    // Generate gray counter for destination side
    gray_counter #(.WIDTH(LOG_DEPTH)) dst_counter (
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .clear(dst_clear_sync_o),
        .counter_out(dst_counter_out)
    );

    // FIFO core
    fifo #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_core (
        .data_in(src_data_i),
        .valid_in(src_valid_sync_o),
        .clear(src_clear_sync_o),
        .ready_in(dst_ready_sync_o),
        .dst_data_o(dst_data_o),
        .dst_valid_o(dst_valid_o)
    );

    // Clear pending logic
    assign src_clear_pending_o = src_clear_sync_o;
    assign dst_clear_pending_o = dst_clear_sync_o;

    // Ready output logic
    assign src_ready_o = fifo_core.ready_out;

endmodule

module sync_reg #(
    parameter WIDTH = 1
) (
    input                  sync_in,
    input                  clk,
    input                  rst_n,
    output reg [WIDTH-1:0] sync_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_out <= {WIDTH{1'b0}};
        end else begin
            sync_out <= sync_in;
        end
    end

endmodule

module gray_counter #(
    parameter WIDTH = 3
) (
    input                  clk,
    input                  rst_n,
    input                  clear,
    output reg [WIDTH-1:0] counter_out
);

    reg [WIDTH-1:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {WIDTH{1'b0}};
        end else if (clear) begin
            counter <= {WIDTH{1'b0}};
        end else begin
            counter <= counter + 1;
        end
    end

    assign counter_out = counter;

endmodule

module fifo #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
) (
    input  [WIDTH-1:0]     data_in,
    input                  valid_in,
    input                  clear,
    input                  ready_in,
    output reg [WIDTH-1:0] data_out,
    output reg             valid_out,
    output reg             ready_out
);

    reg [WIDTH-1:0] memory [0:(2**LOG_DEPTH)-1];
    reg [LOG_DEPTH:0] head;
    reg [LOG_DEPTH:0] tail;
    reg [LOG_DEPTH:0] count;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            head <= 0;
            tail <= 0;
            count <= 0;
        end else if (clear) begin
            head <= 0;
            tail <= 0;
            count <= 0;
        end else if (valid_in && ready_in) begin
            memory[head] <= data_in;
            head <= head + 1;
            count <= count + 1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            data_out <= 0;
            valid_out <= 0;
        end else if (clear) begin
            data_out <= 0;
            valid_out <= 0;
        end else if (count > 0) begin
            data_out <= memory[tail];
            tail <= tail + 1;
            count <= count - 1;
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end
    end

    assign ready_out = (count < 2**LOG_DEPTH);

endmodule
