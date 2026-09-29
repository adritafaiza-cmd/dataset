module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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

    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // FIFO memory
    reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

    // Pointers
    reg [PTR_WIDTH-1:0] wptr_bin, rptr_bin;

    // Gray code pointers
    wire [PTR_WIDTH-1:0] wptr_gray, rptr_gray;

    // Synchronized pointers
    reg [PTR_WIDTH-1:0] rptr_sync_gray1, rptr_sync_gray;
    reg [PTR_WIDTH-1:0] wptr_sync_gray1, wptr_sync_gray;

    // Full and empty signals
    wire full, empty;

    // Gray code conversions
    assign wptr_gray = wptr_bin ^ (wptr_bin >> 1);
    assign rptr_gray = rptr_bin ^ (rptr_bin >> 1);

    // Synchronize read pointer to write domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rptr_sync_gray1 <= 0;
            rptr_sync_gray <= 0;
        end else begin
            rptr_sync_gray1 <= rptr_gray;
            rptr_sync_gray <= rptr_sync_gray1;
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wptr_sync_gray1 <= 0;
            wptr_sync_gray <= 0;
        end else begin
            wptr_sync_gray1 <= wptr_gray;
            wptr_sync_gray <= wptr_sync_gray1;
        end
    end

    // Full condition: compare with inverted top two bits of synchronized read pointer
    assign full = (wptr_gray == { ~rptr_sync_gray[PTR_WIDTH-1], ~rptr_sync_gray[PTR_WIDTH-2], rptr_sync_gray[PTR_WIDTH-3:0] });

    // Empty condition: compare read and synchronized write pointers
    assign empty = (rptr_gray == wptr_sync_gray);

    // Ready and valid assignments
    assign src_ready_o = !full;
    assign dst_valid_o = !empty;

    // Write pointer update
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr_bin <= 0;
        end else if (src_valid_i && src_ready_o) begin
            wptr_bin <= wptr_bin + 1;
        end
    end

    // Read pointer update
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr_bin <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            rptr_bin <= rptr_bin + 1;
        end
    end

    // Memory write
    wire [LOG_DEPTH-1:0] waddr = wptr_bin[LOG_DEPTH-1:0];
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o) begin
            mem[waddr] <= src_data_i;
        end
    end

    // Memory read
    wire [LOG_DEPTH-1:0] raddr = rptr_bin[LOG_DEPTH-1:0];
    assign dst_data_o = mem[raddr];

endmodule
