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

    localparam PTR_WIDTH = LOG_DEPTH + 1;

    reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

    // Source domain signals
    reg [PTR_WIDTH-1:0] wptr_bin, rptr_sync_bin;
    reg [PTR_WIDTH-1:0] wptr_gray;
    reg [PTR_WIDTH-1:0] rptr_sync [0:SYNC_STAGES-1];
    reg src_clear_pending;

    // Destination domain signals
    reg [PTR_WIDTH-1:0] rptr_bin, wptr_sync_bin;
    reg [PTR_WIDTH-1:0] rptr_gray;
    reg [PTR_WIDTH-1:0] wptr_sync [0:SYNC_STAGES-1];
    reg dst_clear_pending;

    integer i;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= 0;
        end else begin
            rptr_sync[0] <= rptr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= rptr_sync[i-1];
        end
    end
    assign rptr_sync_bin = rptr_sync[SYNC_STAGES-1];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr_bin <= 0;
            wptr_gray <= 0;
            src_clear_pending <= 0;
        end else begin
            if (src_clear_i) begin
                wptr_bin <= 0;
                wptr_gray <= 0;
                src_clear_pending <= 1;
            end else if (src_clear_pending) begin
                if (wptr_bin == rptr_sync_bin)
                    src_clear_pending <= 0;
            end else if (src_valid_i && src_ready_o) begin
                mem[wptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
                wptr_bin <= wptr_bin + 1;
                wptr_gray <= bin2gray(wptr_bin + 1);
            end
        end
    end

    wire full;
    assign full = ((wptr_bin - rptr_sync_bin) >= (1 << LOG_DEPTH));
    assign src_ready_o = !full;

    // Destination domain synchronization
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= 0;
        end else begin
            wptr_sync[0] <= wptr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= wptr_sync[i-1];
        end
    end
    assign wptr_sync_bin = wptr_sync[SYNC_STAGES-1];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr_bin <= 0;
            rptr_gray <= 0;
            dst_clear_pending <= 0;
        end else begin
            if (dst_clear_i) begin
                rptr_bin <= 0;
                rptr_gray <= 0;
                dst_clear_pending <= 1;
            end else if (dst_clear_pending) begin
                if (wptr_sync_bin == rptr_bin)
                    dst_clear_pending <= 0;
            end else if (dst_ready_i && dst_valid_o) begin
                rptr_bin <= rptr_bin + 1;
                rptr_gray <= bin2gray(rptr_bin + 1);
            end
        end
    end

    wire empty;
    assign empty = (rptr_bin == wptr_sync_bin);
    assign dst_valid_o = !empty;
    assign dst_data_o = mem[rptr_bin[LOG_DEPTH-1:0]];

    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

endmodule
