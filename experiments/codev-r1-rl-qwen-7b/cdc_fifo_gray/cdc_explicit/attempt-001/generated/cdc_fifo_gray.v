module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
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

    reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

    // Write domain signals
    reg [PTR_WIDTH-1:0] wptr_bin;
    wire [PTR_WIDTH-1:0] wptr_bin_next = wptr_bin + (src_valid_i & src_ready_o);
    wire [PTR_WIDTH-1:0] wgray_next = (wptr_bin_next >> 1) ^ wptr_bin_next;
    wire [PTR_WIDTH-1:0] wgray = (wptr_bin >> 1) ^ wptr_bin;

    // Read domain signals
    reg [PTR_WIDTH-1:0] rptr_bin;
    wire [PTR_WIDTH-1:0] rptr_bin_next = rptr_bin + (dst_ready_i & dst_valid_o);
    wire [PTR_WIDTH-1:0] rgray = (rptr_bin >> 1) ^ rptr_bin;

    // Synchronizers
    reg [PTR_WIDTH-1:0] rgray_sync [SYNC_STAGES-1:0];
    reg [PTR_WIDTH-1:0] wgray_sync [SYNC_STAGES-1:0];

    // Synchronize read pointer's Gray code to write domain
    integer s;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (s = 0; s < SYNC_STAGES; s = s + 1)
                rgray_sync[s] <= 0;
        end else begin
            rgray_sync[0] <= rgray;
            for (s = 1; s < SYNC_STAGES; s = s + 1)
                rgray_sync[s] <= rgray_sync[s-1];
        end
    end

    // Synchronize write pointer's Gray code to read domain
    integer t;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (t = 0; t < SYNC_STAGES; t = t + 1)
                wgray_sync[t] <= 0;
        end else begin
            wgray_sync[0] <= wgray;
            for (t = 1; t < SYNC_STAGES; t = t + 1)
                wgray_sync[t] <= wgray_sync[t-1];
        end
    end

    // Full condition
    wire full;
    assign full = (wgray_next == { ~rgray_sync[SYNC_STAGES-1][PTR_WIDTH-1],
                                   ~rgray_sync[SYNC_STAGES-1][PTR_WIDTH-2],
                                   rgray_sync[SYNC_STAGES-1][PTR_WIDTH-3:0] });

    // Empty condition
    wire empty;
    assign empty = (rgray == wgray_sync[SYNC_STAGES-1]);

    // Assign outputs
    assign src_ready_o = ~full;
    assign dst_valid_o = ~empty;
    assign dst_data_o = mem[rptr_bin[LOG_DEPTH-1:0]];

    // Update write pointer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            wptr_bin <= 0;
        else
            wptr_bin <= wptr_bin_next;
    end

    // Update read pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            rptr_bin <= 0;
        else
            rptr_bin <= rptr_bin_next;
    end

    // Memory write
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o)
            mem[wptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
    end

endmodule
