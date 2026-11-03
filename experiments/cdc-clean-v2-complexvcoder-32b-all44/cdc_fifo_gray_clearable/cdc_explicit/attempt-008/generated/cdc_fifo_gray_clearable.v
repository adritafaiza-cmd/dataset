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
    reg [LOG_DEPTH:0] src_gray_count;
    reg [LOG_DEPTH:0] dst_gray_count;
    reg [LOG_DEPTH:0] synced_gray_count;
    reg src_clear_pending;
    reg dst_clear_pending;
    reg src_ready;
    reg dst_valid;
    reg [WIDTH-1:0] fifo_memory [0:(1<<LOG_DEPTH)-1];

    // Source Gray Counter
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) src_gray_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i | src_clear_pending),
        .gray_count(src_gray_count)
    );

    // Destination Gray Counter
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_gray_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i | dst_clear_pending),
        .gray_count(dst_gray_count)
    );

    // Synchronization Register
    sync_register #(
        .WIDTH(LOG_DEPTH+1),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_reg (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_in(src_gray_count),
        .data_out(synced_gray_count)
    );

    // Source-side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1'b1;
            end else if (src_clear_pending && (src_gray_count == dst_gray_count)) begin
                src_clear_pending <= 1'b0;
            end
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready <= 1'b0;
        end else begin
            if (src_clear_i || src_clear_pending) begin
                src_ready <= 1'b0;
            end else if (src_valid_i && src_ready) begin
                fifo_memory[src_gray_count[LOG_DEPTH-1:0]] <= src_data_i;
                src_gray_count <= src_gray_count + 1'b1;
            end
            src_ready <= (src_gray_count != (dst_gray_count + 1'b1) % (1<<LOG_DEPTH));
        end
    end

    assign src_clear_pending_o = src_clear_pending;
    assign src_ready_o = src_ready;

    // Destination-side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending <= 1'b1;
            end else if (dst_clear_pending && (synced_gray_count == dst_gray_count)) begin
                dst_clear_pending <= 1'b0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid <= 1'b0;
            dst_data_o <= {WIDTH{1'b0}};
        end else begin
            if (dst_clear_i || dst_clear_pending) begin
                dst_valid <= 1'b0;
            end else if (synced_gray_count != dst_gray_count) begin
                dst_data_o <= fifo_memory[dst_gray_count[LOG_DEPTH-1:0]];
                dst_valid <= 1'b1;
                dst_gray_count <= dst_gray_count + 1'b1;
            end else if (dst_ready_i && dst_valid) begin
                dst_valid <= 1'b0;
            end
        end
    end

    assign dst_clear_pending_o = dst_clear_pending;
    assign dst_valid_o = dst_valid;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    output reg [LOG_DEPTH:0] gray_count
);

    reg [LOG_DEPTH:0] binary_count;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            binary_count <= {LOG_DEPTH+1{1'b0}};
        end else if (clear_i) begin
            binary_count <= {LOG_DEPTH+1{1'b0}};
        end else begin
            binary_count <= binary_count + 1'b1;
        end
    end

    assign gray_count = binary_count ^ (binary_count >> 1);

endmodule

module sync_register #(
    parameter WIDTH = 4,
    parameter SYNC_STAGES = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     data_in,
    output reg [WIDTH-1:0] data_out
);

    reg [WIDTH-1:0] sync_stages [0:SYNC_STAGES-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_out <= {WIDTH{1'b0}};
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_stages[i] <= {WIDTH{1'b0}};
            end
        end else begin
            sync_stages[0] <= data_in;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stages[i] <= sync_stages[i-1];
            end
            data_out <= sync_stages[SYNC_STAGES-1];
        end
    end

endmodule
