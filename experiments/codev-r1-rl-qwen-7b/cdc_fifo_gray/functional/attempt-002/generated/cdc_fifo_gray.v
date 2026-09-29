module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
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

    // Memory
    reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

    // Write domain signals
    reg [LOG_DEPTH:0] wptr_bin;
    wire [LOG_DEPTH:0] wgray;
    reg [LOG_DEPTH:0] rgray_sync [SYNC_STAGES-1:0];

    // Read domain signals
    reg [LOG_DEPTH:0] rptr_bin;
    wire [LOG_DEPTH:0] rgray;
    reg [LOG_DEPTH:0] wgray_sync [SYNC_STAGES-1:0];

    // Full and empty signals
    wire full;
    wire empty;

    // Write pointer logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr_bin <= 0;
        end else if (src_valid_i && src_ready_o) begin
            wptr_bin <= wptr_bin + 1;
        end
    end

    // Convert binary to Gray
    assign wgray = (wptr_bin >> 1) ^ wptr_bin;

    // Synchronize read pointer's Gray code into write domain
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

    // Function to convert Gray to binary
    function [LOG_DEPTH:0] gray2bin;
        input [LOG_DEPTH:0] gray;
        integer j;
        begin
            gray2bin[LOG_DEPTH] = gray[LOG_DEPTH];
            for (j = LOG_DEPTH-1; j >= 0; j = j - 1)
                gray2bin[j] = gray2bin[j+1] ^ gray[j];
        end
    endfunction

    // Convert synchronized Gray to binary
    wire [LOG_DEPTH:0] rptr_sync_bin;
    assign rptr_sync_bin = gray2bin(rgray_sync[SYNC_STAGES-1]);

    // Full condition
    assign full = ( (wptr_bin - rptr_sync_bin) >= (1 << LOG_DEPTH) );

    // Source ready is not full
    assign src_ready_o = !full;

    // Write data to memory
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o) begin
            mem[wptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Read domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr_bin <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            rptr_bin <= rptr_bin + 1;
        end
    end

    // Convert binary to Gray
    assign rgray = (rptr_bin >> 1) ^ rptr_bin;

    // Synchronize write pointer's Gray code into read domain
    integer k;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (k = 0; k < SYNC_STAGES; k = k + 1)
                wgray_sync[k] <= 0;
        end else begin
            wgray_sync[0] <= wgray;
            for (k = 1; k < SYNC_STAGES; k = k + 1)
                wgray_sync[k] <= wgray_sync[k-1];
        end
    end

    // Function to convert Gray to binary for write pointer
    function [LOG_DEPTH:0] gray2bin_w;
        input [LOG_DEPTH:0] gray;
        integer m;
        begin
            gray2bin_w[LOG_DEPTH] = gray[LOG_DEPTH];
            for (m = LOG_DEPTH-1; m >= 0; m = m - 1)
                gray2bin_w[m] = gray2bin_w[m+1] ^ gray[m];
        end
    endfunction

    // Convert synchronized Gray to binary
    wire [LOG_DEPTH:0] wptr_sync_bin;
    assign wptr_sync_bin = gray2bin_w(wgray_sync[SYNC_STAGES-1]);

    // Empty condition
    assign empty = (rptr_bin == wptr_sync_bin);

    // Destination valid is not empty
    assign dst_valid_o = !empty;

    // Read data from memory
    assign dst_data_o = mem[rptr_bin[LOG_DEPTH-1:0]];

endmodule
