```verilog
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
    logic [WIDTH-1:0]       fifo_data;
    logic                   fifo_valid;
    logic                   fifo_ready;
    logic                   src_gray_counter_output;
    logic                   dst_gray_counter_output;

    // Gray counter instances
    gray_counter #(
        .WIDTH(1)
    ) src_gray_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .clear_pending_o(src_clear_pending_o),
        .output(src_gray_counter_output)
    );

    gray_counter #(
        .WIDTH(1)
    ) dst_gray_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .clear_pending_o(dst_clear_pending_o),
        .output(dst_gray_counter_output)
    );

    // Asynchronous FIFO instance
    async_fifo #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo (
        .clk_i(src_clk_i),
        .clk_o(dst_clk_i),
        .rst_ni(src_rst_ni),
        .wdata_i(src_data_i),
        .wvalid_i(src_valid_i),
        .wready_o(src_ready_o),
        .rdata_o(fifo_data),
        .rvalid_o(fifo_valid),
        .rready_i(dst_ready_i)
    );

    // Source ready logic
    assign src_ready_o = fifo_ready;

endmodule

module gray_counter #(
    parameter WIDTH = 1
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    output                 clear_pending_o,
    output reg [WIDTH-1:0] output
);

    reg [WIDTH-1:0] gray_counter;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray_counter <= 0;
            output <= 0;
            clear_pending_o <= 0;
        end else if (clear_i) begin
            gray_counter <= 0;
            output <= 0;
            clear_pending_o <= 1;
        end else begin
            gray_counter <= gray_counter + 1;
            output <= gray_counter[0];
            clear_pending_o <= 0;
        end
    end

endmodule

module async_fifo #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  clk_i,
    input                  clk_o,
    input                  rst_ni,
    input  [WIDTH-1:0]     wdata_i,
    input                  wvalid_i,
    output                 wready_o,
    output [WIDTH-1:0]     rdata_o,
    output                 rvalid_o,
    input                  rready_i
);

    reg [WIDTH-1:0] mem [0:((1<<LOG_DEPTH)-1)];
    reg [LOG_DEPTH:0] wptr;
    reg [LOG_DEPTH:0] rptr;
    reg [LOG_DEPTH:0] wptr_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray;
    reg [LOG_DEPTH:0] rptr_gray;
    reg [LOG_DEPTH:0] wptr_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_sync [0:SYNC_STAGES-1];
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] rptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray;
    reg [LOG_DEPTH:0] wptr_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray_gray