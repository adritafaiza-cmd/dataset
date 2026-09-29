module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
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

    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Pointers
    reg [PTR_WIDTH-1:0] wptr, rptr;

    // Gray code pointers
    wire [PTR_WIDTH-1:0] wgray, rgray;

    // Synchronizers for read pointer in write domain
    reg [PTR_WIDTH-1:0] rgray_sync1, rgray_sync2;
    wire [PTR_WIDTH-1:0] synced_rgray;

    // Synchronizers for write pointer in read domain
    reg [PTR_WIDTH-1:0] wgray_sync1, wgray_sync2;
    wire [PTR_WIDTH-1:0] synced_wgray;

    // Convert synced Gray pointers to binary
    wire [PTR_WIDTH-1:0] synced_rptr, synced_wptr;

    // Full and empty conditions
    wire full, empty;

    // Memory
    reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

    // Write pointer logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr <= 0;
        end else if (src_valid_i && src_ready_o) begin
            wptr <= wptr + 1;
            mem[wptr[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Read pointer logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            rptr <= rptr + 1;
        end
    end

    // Gray code conversions
    assign wgray = (wptr >> 1) ^ wptr;
    assign rgray = (rptr >> 1) ^ rptr;

    // Synchronizers for read pointer in write domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rgray_sync1 <= 0;
            rgray_sync2 <= 0;
        end else begin
            rgray_sync1 <= rgray;
            rgray_sync2 <= rgray_sync1;
        end
    end
    assign synced_rgray = rgray_sync2;

    // Convert synced_rgray to binary
    function [PTR_WIDTH-1:0] gray2bin;
        input [PTR_WIDTH-1:0] gray;
        integer i;
        reg [PTR_WIDTH-1:0] bin;
        begin
            bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >=0; i = i -1)
                bin[i] = bin[i+1] ^ gray[i];
            gray2bin = bin;
        end
    endfunction
    assign synced_rptr = gray2bin(synced_rgray);

    // Synchronizers for write pointer in read domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wgray_sync1 <= 0;
            wgray_sync2 <= 0;
        end else begin
            wgray_sync1 <= wgray;
            wgray_sync2 <= wgray_sync1;
        end
    end
    assign synced_wgray = wgray_sync2;

    // Convert synced_wgray to binary
    assign synced_wptr = gray2bin(synced_wgray);

    // Full and empty conditions
    assign full = ( (wptr[PTR_WIDTH-1] != synced_rptr[PTR_WIDTH-1]) && 
                    (wptr[PTR_WIDTH-2:0] == synced_rptr[PTR_WIDTH-2:0]) );
    assign empty = (rptr == synced_wptr);

    // Assign outputs
    assign src_ready_o = !full;
    assign dst_valid_o = !empty;

    // Read data
    assign dst_data_o = mem[rptr[LOG_DEPTH-1:0]];

endmodule
