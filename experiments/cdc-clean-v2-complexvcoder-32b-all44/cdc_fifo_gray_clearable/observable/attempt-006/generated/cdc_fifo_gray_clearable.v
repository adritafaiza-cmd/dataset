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
    wire [LOG_DEPTH:0] src_gray_out, dst_gray_out;
    wire [LOG_DEPTH:0] sync_src_gray_q, sync_dst_gray_q;
    reg  [LOG_DEPTH-1:0] src_bin_ptr, dst_bin_ptr;
    reg                  src_full, src_empty, dst_full, dst_empty;
    reg  [WIDTH-1:0]     fifo_memory [2**LOG_DEPTH-1:0];
    reg                  src_clear_done, dst_clear_done;

    // Gray counters
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) src_gray_counter (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .gray_in(sync_dst_gray_q),
        .gray_out(src_gray_out)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) dst_gray_counter (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .gray_in(sync_src_gray_q),
        .gray_out(dst_gray_out)
    );

    // Synchronizers
    sync_register #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES)) sync_src_gray (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d(src_gray_out),
        .q(sync_src_gray_q)
    );

    sync_register #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES)) sync_dst_gray (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .d(dst_gray_out),
        .q(sync_dst_gray_q)
    );

    // FIFO control logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_bin_ptr <= 0;
            src_clear_done <= 0;
        end else begin
            if (src_clear_i) begin
                src_bin_ptr <= 0;
                src_clear_done <= 1;
            end else if (src_valid_i && src_ready_o) begin
                src_bin_ptr <= src_bin_ptr + 1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_bin_ptr <= 0;
            dst_clear_done <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_bin_ptr <= 0;
                dst_clear_done <= 1;
            end else if (dst_ready_i && dst_valid_o) begin
                dst_bin_ptr <= dst_bin_ptr + 1;
            end
        end
    end

    // FIFO full and empty flags
    assign src_full = (src_gray_out[LOG_DEPTH:1] == sync_dst_gray_q[LOG_DEPTH:1]) && (src_gray_out[0] != sync_dst_gray_q[0]);
    assign src_empty = (src_gray_out == sync_dst_gray_q);
    assign dst_full = (dst_gray_out[LOG_DEPTH:1] == sync_src_gray_q[LOG_DEPTH:1]) && (dst_gray_out[0] != sync_src_gray_q[0]);
    assign dst_empty = (dst_gray_out == sync_src_gray_q);

    // FIFO read and write
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_memory <= 0;
        end else if (src_valid_i && src_ready_o) begin
            fifo_memory[src_bin_ptr] <= src_data_i;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else if (dst_ready_i && dst_valid_o) begin
            dst_data_o <= fifo_memory[dst_bin_ptr];
        end
    end

    // Ready and valid signals
    assign src_ready_o = !src_full;
    assign dst_valid_o = !dst_empty;

    // Clear pending signals
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending_o <= 0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending_o <= 1;
            end else if (src_clear_done) begin
                src_clear_pending_o <= 0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending_o <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending_o <= 1;
            end else if (dst_clear_done) begin
                dst_clear_pending_o <= 0;
            end
        end
    end

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input                  clear_i,
    input  [LOG_DEPTH:0]   gray_in,
    output [LOG_DEPTH:0]   gray_out
);

    reg  [LOG_DEPTH-1:0] bin_ptr;
    reg  [LOG_DEPTH:0] gray_ptr;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_ptr <= 0;
            gray_ptr <= 0;
        end else if (clear_i) begin
            bin_ptr <= 0;
            gray_ptr <= 0;
        end else begin
            bin_ptr <= bin_ptr + 1;
            gray_ptr <= (bin_ptr ^ (bin_ptr >> 1));
        end
    end

    assign gray_out = gray_ptr;

endmodule

module sync_register #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  clk,
    input                  rst_ni,
    input  [LOG_DEPTH:0]   d,
    output [LOG_DEPTH:0]   q
);

    reg [LOG_DEPTH:0] sync_stage [SYNC_STAGES-1:0];

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= 0;
            end
        end else begin
            sync_stage[0] <= d;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= sync_stage[i-1];
            end
        end
    end

    assign q = sync_stage[SYNC_STAGES-1];

endmodule
