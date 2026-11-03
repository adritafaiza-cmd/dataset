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

    // Internal signals
    logic [WIDTH-1:0]       fifo_data_out;
    logic                   fifo_valid_out;
    logic                   src_gray_counter_out;
    logic                   dst_gray_counter_out;
    logic                   src_clear_pending;
    logic                   dst_clear_pending;
    logic                   src_clear_done;
    logic                   dst_clear_done;

    // Gray counter for source domain
    gray_counter src_gray_counter (
        .reset(src_rst_ni),
        .clock(src_clk_i),
        .output(src_gray_counter_out)
    );

    // Gray counter for destination domain
    gray_counter dst_gray_counter (
        .reset(dst_rst_ni),
        .clock(dst_clk_i),
        .output(dst_gray_counter_out)
    );

    // Asynchronous FIFO
    fifo #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_inst (
        .reset(src_gray_counter_out),
        .clock(src_clk_i),
        .data_in(src_data_i),
        .valid_in(src_valid_i),
        .ready_out(src_ready_o),
        .data_out(fifo_data_out),
        .valid_out(fifo_valid_out),
        .reset(dst_gray_counter_out),
        .clock(dst_clk_i),
        .data_in(fifo_data_out),
        .valid_in(fifo_valid_out),
        .ready_out(dst_ready_o)
    );

    // Clear logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b0;
            src_clear_done <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1'b1;
                src_clear_done <= 1'b0;
            end else if (fifo_valid_out && src_ready_o) begin
                src_clear_done <= 1'b1;
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
            dst_clear_done <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending <= 1'b1;
                dst_clear_done <= 1'b0;
            end else if (fifo_valid_out && dst_ready_i) begin
                dst_clear_done <= 1'b1;
            end
        end
    end

    // Clear pending outputs
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule
