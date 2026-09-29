module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
) (
    input src_rst_ni,
    input src_clk_i,
    input [WIDTH-1:0] src_data_i,
    input src_valid_i,
    output src_ready_o,
    input dst_rst_ni,
    input dst_clk_i,
    output [WIDTH-1:0] dst_data_o,
    output dst_valid_o,
    input dst_ready_i
);

    // Memory array
    reg [WIDTH-1:0] mem [0:(2**LOG_DEPTH)-1];

    // Write domain signals
    reg [LOG_DEPTH:0] wptr_bin;
    wire [LOG_DEPTH:0] wptr_bin_next;
    wire push;
    wire [LOG_DEPTH:0] wgray, wgray_next;
    wire full;

    // Read domain signals
    reg [LOG_DEPTH:0] rptr_bin;
    wire [LOG_DEPTH:0] rptr_bin_next;
    wire pop;
    wire [LOG_DEPTH:0] rgray;
    wire empty;

    // Gray code conversion function
    function [LOG_DEPTH:0] bin2gray;
        input [LOG_DEPTH:0] bin;
        begin
            bin2gray = (bin >> 1) ^ bin;
        end
    endfunction

    // Write pointer logic
    assign push = src_valid_i && src_ready_o;
    assign wptr_bin_next = wptr_bin + push;

    assign wgray = bin2gray(wptr_bin);
    assign wgray_next = bin2gray(wptr_bin_next);

    // Synchronize read pointer's Gray code into write domain
    reg [LOG_DEPTH:0] rgray_sync [SYNC_STAGES-1:0];
    integer i;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                rgray_sync[i] <= 0;
        end else begin
            rgray_sync[0] <= rgray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                rgray_sync[i] <= rgray_sync[i-1];
        end
    end

    // Full condition
    assign full = (wgray_next == { ~rgray_sync[SYNC_STAGES-1][LOG_DEPTH], ~rgray_sync[SYNC_STAGES-1][LOG_DEPTH-1], rgray_sync[SYNC_STAGES-1][LOG_DEPTH-2:0] });

    assign src_ready_o = !full;

    // Update write pointer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr_bin <= 0;
        end else if (push) begin
            wptr_bin <= wptr_bin_next;
        end
    end

    // Memory write
    always @(posedge src_clk_i) begin
        if (push)
            mem[wptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
    end

    // Read pointer logic
    assign pop = dst_valid_o && dst_ready_i;
    assign rptr_bin_next = rptr_bin + pop;

    assign rgray = bin2gray(rptr_bin);

    // Synchronize write pointer's Gray code into read domain
    reg [LOG_DEPTH:0] wgray_sync [SYNC_STAGES-1:0];
    integer j;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (j = 0; j < SYNC_STAGES; j = j + 1)
                wgray_sync[j] <= 0;
        end else begin
            wgray_sync[0] <= wgray;
            for (j = 1; j < SYNC_STAGES; j = j + 1)
                wgray_sync[j] <= wgray_sync[j-1];
        end
    end

    // Empty condition
    assign empty = (rgray == wgray_sync[SYNC_STAGES-1]);

    assign dst_valid_o = !empty;

    // Update read pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr_bin <= 0;
        end else if (pop) begin
            rptr_bin <= rptr_bin_next;
        end
    end

    // Memory read
    assign dst_data_o = mem[rptr_bin[LOG_DEPTH-1:0]];

endmodule
