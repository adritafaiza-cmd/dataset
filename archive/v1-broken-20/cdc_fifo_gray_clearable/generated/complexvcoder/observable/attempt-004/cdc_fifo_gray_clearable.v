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

    // Internal signals for FIFOs
    logic [WIDTH-1:0] src_fifo_data_o;
    logic [WIDTH-1:0] dst_fifo_data_o;
    logic src_fifo_valid_o;
    logic src_fifo_ready_o;
    logic dst_fifo_valid_o;
    logic dst_fifo_ready_o;

    // FIFOs
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_fifo (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .clear_i(src_clear_i),
        .clear_pending_o(src_clear_pending_o),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_fifo_ready_o)
    );

    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_fifo (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .clear_i(dst_clear_i),
        .clear_pending_o(dst_clear_pending_o),
        .data_o(dst_fifo_data_o),
        .valid_o(dst_fifo_valid_o),
        .ready_i(dst_ready_i)
    );

    // Cross-clock-domain signals
    logic [WIDTH-1:0] src_clear_sync;
    logic [WIDTH-1:0] dst_clear_sync;

    sync_reset #(
        .WIDTH(1),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_clear_sync_reset (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .rst_o(src_clear_sync)
    );

    sync_reset #(
        .WIDTH(1),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_clear_sync_reset (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .rst_o(dst_clear_sync)
    );

    // Connect FIFOs
    assign src_fifo.data_o = src_clear_sync ? '0 : src_data_i;
    assign src_fifo.valid_i = src_clear_sync ? 1'b0 : src_valid_i;
    assign src_ready_o = src_fifo_ready_o;

    assign dst_data_o = dst_fifo_data_o;
    assign dst_valid_o = dst_fifo_valid_o;
    assign dst_fifo.ready_o = dst_ready_i;

endmodule

module fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  clear_i,
    output                 clear_pending_o,
    input  [WIDTH-1:0]     data_i,
    input                  valid_i,
    output                 ready_o
);

    // FIFO depth
    parameter DEPTH = 1 << LOG_DEPTH;

    // FIFO memory
    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [LOG_DEPTH:0] wr_ptr;
    logic [LOG_DEPTH:0] rd_ptr;
    logic [LOG_DEPTH:0] count;

    // Clear signal handling
    logic clear;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            clear <= 1'b0;
        end else begin
            clear <= clear_i | clear;
        end
    end

    // Clear pending output
    assign clear_pending_o = clear;

    // Write pointer logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
        end else if (valid_i && ready_o && !clear) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rd_ptr <= 0;
        end else if (dst_ready_i && count && !clear) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Count logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count <= 0;
        end else if (valid_i && ready_o && !clear) begin
            count <= count + 1;
        end else if (dst_ready_i && count && !clear) begin
            count <= count - 1;
        end else if (clear) begin
            count <= 0;
        end
    end

    // Memory write logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            mem <= '{default: 0};
        end else if (valid_i && ready_o && !clear) begin
            mem[wr_ptr] <= data_i;
        end
    end

    // Memory read logic
    assign dst_data_o = mem[rd_ptr];

    // Ready output
    assign ready_o = (count < DEPTH) && !clear;

endmodule

module sync_reset #(
    parameter WIDTH = 1,
    parameter SYNC_STAGES = 3
)(
    input                  clk_i,
    input                  rst_ni,
    output                 rst_o
);

    logic [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= '{default: 1'b1};
        end else begin
            sync_reg <= {sync_reg[SYNC_STAGES-2:0], rst_ni};
        end
    end

    assign rst_o = sync_reg[SYNC_STAGES-1];

endmodule
