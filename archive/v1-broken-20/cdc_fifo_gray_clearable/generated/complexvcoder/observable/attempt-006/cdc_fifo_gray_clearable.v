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
    logic [WIDTH-1:0] src_data_gray;
    logic [WIDTH-1:0] dst_data_gray;
    logic src_valid_gray;
    logic dst_valid_gray;
    logic src_ready_gray;
    logic dst_ready_gray;
    logic src_clear_pending_int;
    logic dst_clear_pending_int;

    // FIFO instances
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_fifo (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_gray)
    );

    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_fifo (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_o(dst_data_gray),
        .valid_o(dst_valid_gray),
        .ready_i(dst_ready_gray)
    );

    // Clear pending signal generation
    clear_pending src_clear_pending (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .clear_pending_o(src_clear_pending_int)
    );

    clear_pending dst_clear_pending (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .clear_pending_o(dst_clear_pending_int)
    );

    // Gray encoding/decoding
    gray_encoder #(
        .WIDTH(WIDTH)
    ) src_gray_encoder (
        .clk_i(src_clk_i),
        .data_i(src_data_i),
        .data_o(src_data_gray)
    );

    gray_encoder #(
        .WIDTH(WIDTH)
    ) dst_gray_decoder (
        .clk_i(dst_clk_i),
        .data_i(dst_data_gray),
        .data_o(dst_data_o)
    );

    // Handshake logic
    assign src_ready_o = src_ready_gray;
    assign dst_valid_o = dst_valid_gray;

    // Clear both FIFOs when clear signal is received
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending_int <= 0;
        end else if (src_clear_i) begin
            src_clear_pending_int <= 1;
        end else if (src_clear_pending_int && src_ready_gray) begin
            src_clear_pending_int <= 0;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending_int <= 0;
        end else if (dst_clear_i) begin
            dst_clear_pending_int <= 1;
        end else if (dst_clear_pending_int && dst_ready_gray) begin
            dst_clear_pending_int <= 0;
        end
    end

    // Output clear pending signals
    assign src_clear_pending_o = src_clear_pending_int;
    assign dst_clear_pending_o = dst_clear_pending_int;

endmodule

module fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     data_i,
    input                  valid_i,
    output                 ready_o
);

    // FIFO implementation details (simplified for illustration)
    logic [WIDTH-1:0] mem [2**LOG_DEPTH-1:0];
    logic [LOG_DEPTH:0] wr_ptr, rd_ptr;
    logic [LOG_DEPTH:0] count;

    // Write logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
        end else if (valid_i && ready_o) begin
            mem[wr_ptr] <= data_i;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rd_ptr <= 0;
        end else if (rd_ptr < wr_ptr) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Count logic
    assign count = wr_ptr - rd_ptr;

    // Ready signal
    assign ready_o = (count < 2**LOG_DEPTH);

endmodule

module clear_pending (
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    output                 clear_pending_o
);

    logic clear_pending_int;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            clear_pending_int <= 0;
        end else if (clear_i) begin
            clear_pending_int <= 1;
        end else if (clear_pending_int && clear_i) begin
            clear_pending_int <= 0;
        end
    end

    assign clear_pending_o = clear_pending_int;

endmodule

module gray_encoder #(
    parameter WIDTH = 8
)(
    input                  clk_i,
    input  [WIDTH-1:0]     data_i,
    output [WIDTH-1:0]     data_o
);

    always_ff @(posedge clk_i) begin
        data_o <= data_i ^ (data_i >> 1);
    end

endmodule
