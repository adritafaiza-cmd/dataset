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
    wire [WIDTH-1:0] src_data_gray;
    wire [WIDTH-1:0] dst_data_gray;
    wire src_valid_gray;
    wire dst_valid_gray;
    wire src_ready_gray;
    wire dst_ready_gray;
    wire src_clear_gray;
    wire dst_clear_gray;
    wire src_clear_pending_gray;
    wire dst_clear_pending_gray;

    // Convert source data to Gray code
    assign src_data_gray = src_data_i ^ (src_data_i >> 1);

    // Convert destination data to Gray code
    assign dst_data_gray = dst_data_o ^ (dst_data_o >> 1);

    // FIFOs
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_gray_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(src_data_gray),
        .valid_i(src_valid_gray),
        .ready_o(src_ready_gray)
    );

    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_gray_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(dst_data_gray),
        .valid_i(dst_valid_gray),
        .ready_o(dst_ready_gray)
    );

    // Clear logic
    clear_logic #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) clear_logic_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .clear_pending_o(src_clear_pending_gray)
    );

    clear_logic #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) clear_logic_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .clear_pending_o(dst_clear_pending_gray)
    );

    // Connect clear logic to FIFOs
    assign src_clear_gray = src_clear_gray;
    assign dst_clear_gray = dst_clear_gray;

    // Connect FIFOs to clear logic
    assign src_clear_pending_o = src_clear_pending_gray;
    assign dst_clear_pending_o = dst_clear_pending_gray;

    // Connect FIFOs to interface
    assign src_ready_o = src_ready_gray;
    assign dst_valid_o = dst_valid_gray;
    assign dst_data_o = dst_data_gray;

    // Convert destination data back to binary
    assign dst_data_o = dst_data_gray ^ (dst_data_gray >> 1);

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

    // Internal signals
    reg  [WIDTH-1:0] mem [0:2**LOG_DEPTH-1];
    reg  [LOG_DEPTH:0] wr_ptr;
    reg  [LOG_DEPTH:0] rd_ptr;
    reg  [LOG_DEPTH:0] cnt;
    reg  full;
    reg  empty;

    // Write process
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
            cnt <= 0;
            full <= 0;
        end else if (!full && valid_i) begin
            mem[wr_ptr] <= data_i;
            wr_ptr <= wr_ptr + 1;
            cnt <= cnt + 1;
            if (cnt == 2**LOG_DEPTH)
                full <= 1;
        end
    end

    // Read process
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rd_ptr <= 0;
            empty <= 1;
        end else if (!empty && dst_ready_i) begin
            rd_ptr <= rd_ptr + 1;
            cnt <= cnt - 1;
            if (cnt == 0)
                empty <= 1;
        end
    end

    // Output process
    assign ready_o = !full;

endmodule

module clear_logic #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    output                 clear_pending_o
);

    // Internal signals
    reg  clear_pending;

    // Clear process
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            clear_pending <= 0;
        end else if (clear_i) begin
            clear_pending <= 1;
        end else if (clear_pending) begin
            clear_pending <= 0;
        end
    end

    // Output process
    assign clear_pending_o = clear_pending;

endmodule
