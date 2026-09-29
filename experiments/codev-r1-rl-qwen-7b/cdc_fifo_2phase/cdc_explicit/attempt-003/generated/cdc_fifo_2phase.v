module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
) (
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Memory
    reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

    // Write domain signals
    reg [PTR_WIDTH-1:0] wptr_bin;
    wire [PTR_WIDTH-1:0] wptr_bin_next = wptr_bin + (src_valid_i && src_ready_o);
    wire [PTR_WIDTH-1:0] wgraynext = (wptr_bin_next >> 1) ^ wptr_bin_next;

    // Synchronize read pointer's Gray code to write domain
    reg [PTR_WIDTH-1:0] rgray_sync1, rgray_sync2;

    // Read domain signals
    reg [PTR_WIDTH-1:0] rptr_bin;
    wire [PTR_WIDTH-1:0] rptr_bin_next = rptr_bin + (dst_ready_i && dst_valid_o);
    wire [PTR_WIDTH-1:0] rgraynext = (rptr_bin_next >> 1) ^ rptr_bin_next;

    // Synchronize write pointer's Gray code to read domain
    reg [PTR_WIDTH-1:0] wgray_sync1, wgray_sync2;

    // Full and empty conditions
    wire full;
    wire empty;

    // Write pointer and Gray code update
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr_bin <= 0;
        end else if (src_valid_i && src_ready_o) begin
            wptr_bin <= wptr_bin_next;
        end
    end

    // Gray code conversion for write pointer
    reg [PTR_WIDTH-1:0] wptr_gray;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr_gray <= 0;
        end else begin
            wptr_gray <= wgraynext;
        end
    end

    // Synchronize read pointer's Gray code
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rgray_sync1 <= 0;
            rgray_sync2 <= 0;
        end else begin
            rgray_sync1 <= rptr_gray;
            rgray_sync2 <= rgray_sync1;
        end
    end

    // Full condition
    assign full = (wgraynext == { ~rgray_sync2[PTR_WIDTH-1], ~rgray_sync2[PTR_WIDTH-2], rgray_sync2[PTR_WIDTH-3:0] });

    assign src_ready_o = ~full;

    // Read pointer and Gray code update
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr_bin <= 0;
        end else if (dst_ready_i && dst_valid_o) begin
            rptr_bin <= rptr_bin_next;
        end
    end

    // Gray code conversion for read pointer
    reg [PTR_WIDTH-1:0] rptr_gray;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr_gray <= 0;
        end else begin
            rptr_gray <= rgraynext;
        end
    end

    // Synchronize write pointer's Gray code
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wgray_sync1 <= 0;
            wgray_sync2 <= 0;
        end else begin
            wgray_sync1 <= wptr_gray;
            wgray_sync2 <= wgray_sync1;
        end
    end

    // Empty condition
    assign empty = (rptr_gray == wgray_sync2);

    assign dst_valid_o = ~empty;

    // Memory write
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o) begin
            mem[wptr_bin[PTR_WIDTH-2 : 0]] <= src_data_i;
        end
    end

    // Memory read
    assign dst_data_o = mem[rptr_bin[PTR_WIDTH-2 : 0]];

endmodule
