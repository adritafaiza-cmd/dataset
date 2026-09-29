module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
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

    // Local parameters
    localparam DEPTH = 1 << LOG_DEPTH;

    // FIFO memory
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Pointers
    reg [LOG_DEPTH:0] wptr, rptr;

    // Gray code conversions
    wire [LOG_DEPTH:0] wgray, rgray;

    // Synchronizers
    reg [LOG_DEPTH:0] rgray_sync1, rgray_sync2;
    reg [LOG_DEPTH:0] wgray_sync1, wgray_sync2;

    // Binary pointers from synchronized Gray codes
    reg [LOG_DEPTH:0] rptr_bin, wptr_bin;

    // Full and empty signals
    wire full, empty;

    // Assign Gray codes
    assign wgray = (wptr >> 1) ^ wptr; // bin2gray
    assign rgray = (rptr >> 1) ^ rptr;

    // Synchronize read pointer to write domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rgray_sync1 <= 0;
            rgray_sync2 <= 0;
        end else begin
            rgray_sync1 <= rgray;
            rgray_sync2 <= rgray_sync1;
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wgray_sync1 <= 0;
            wgray_sync2 <= 0;
        end else begin
            wgray_sync1 <= wgray;
            wgray_sync2 <= wgray_sync1;
        end
    end

    // Convert synchronized Gray to binary in write domain
    integer i;
    always @(*) begin
        rptr_bin[LOG_DEPTH] = rgray_sync2[LOG_DEPTH];
        for (i = LOG_DEPTH-1; i >=0; i = i -1) begin
            rptr_bin[i] = rptr_bin[i+1] ^ rgray_sync2[i];
        end
    end

    // Convert synchronized Gray to binary in read domain
    integer j;
    always @(*) begin
        wptr_bin[LOG_DEPTH] = wgray_sync2[LOG_DEPTH];
        for (j = LOG_DEPTH-1; j >=0; j = j -1) begin
            wptr_bin[j] = wptr_bin[j+1] ^ wgray_sync2[j];
        end
    end

    // Full and empty conditions
    assign full = ( (wptr - rptr_bin) >= DEPTH );
    assign empty = (rptr == wptr_bin);

    // Assign outputs
    assign src_ready_o = !full;
    assign dst_valid_o = !empty;

    // Write pointer update
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr <= 0;
        end else if (src_valid_i && src_ready_o) begin
            wptr <= wptr + 1;
            mem[wptr[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Read pointer update
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            rptr <= rptr + 1;
        end
    end

    // Read data output
    assign dst_data_o = mem[rptr[LOG_DEPTH-1:0]];

endmodule
