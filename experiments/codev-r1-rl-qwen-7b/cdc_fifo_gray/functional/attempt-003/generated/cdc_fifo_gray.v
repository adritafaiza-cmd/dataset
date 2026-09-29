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

    // Source domain (write) signals
    reg [PTR_WIDTH-1:0] wptr_bin, wptr_bin_next;
    wire [PTR_WIDTH-1:0] wptr_gray;

    // Destination domain (read) signals
    reg [PTR_WIDTH-1:0] rptr_bin, rptr_bin_next;
    wire [PTR_WIDTH-1:0] rptr_gray;

    // Synchronization registers
    reg [PTR_WIDTH-1:0] rptr_gray_sync [SYNC_STAGES-1:0];
    reg [PTR_WIDTH-1:0] wptr_gray_sync [SYNC_STAGES-1:0];

    // Convert Gray to binary
    function [PTR_WIDTH-1:0] gray2bin;
        input [PTR_WIDTH-1:0] gray;
        integer i;
        begin
            gray2bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >=0; i = i-1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Memory
    reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

    // Source domain logic
    wire full;
    reg [PTR_WIDTH-1:0] rptr_bin_sync;

    always @* begin
        rptr_bin_sync = gray2bin(rptr_gray_sync[SYNC_STAGES-1]);
    end

    assign full = ( (wptr_bin_next[PTR_WIDTH-1] != rptr_bin_sync[PTR_WIDTH-1]) &&
                   (wptr_bin_next[PTR_WIDTH-2:0] == rptr_bin_sync[PTR_WIDTH-2:0]) );

    assign src_ready_o = !full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            wptr_bin <= 0;
        else
            wptr_bin <= wptr_bin_next;
    end

    always @* begin
        wptr_bin_next = wptr_bin;
        if (src_valid_i && src_ready_o)
            wptr_bin_next = wptr_bin + 1;
    end

    assign wptr_gray = (wptr_bin_next >> 1) ^ wptr_bin_next;

    integer i;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (i=0; i < SYNC_STAGES; i=i+1)
                rptr_gray_sync[i] <= 0;
        end else begin
            rptr_gray_sync[0] <= rptr_gray;
            for (i=1; i < SYNC_STAGES; i=i+1)
                rptr_gray_sync[i] <= rptr_gray_sync[i-1];
        end
    end

    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o)
            mem[wptr_bin[PTR_WIDTH-2:0]] <= src_data_i;
    end

    // Destination domain logic
    wire empty;
    reg [PTR_WIDTH-1:0] wptr_bin_sync;

    always @* begin
        wptr_bin_sync = gray2bin(wptr_gray_sync[SYNC_STAGES-1]);
    end

    assign empty = (rptr_bin == wptr_bin_sync);
    assign dst_valid_o = !empty;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            rptr_bin <= 0;
        else
            rptr_bin <= rptr_bin_next;
    end

    always @* begin
        rptr_bin_next = rptr_bin;
        if (dst_valid_o && dst_ready_i)
            rptr_bin_next = rptr_bin + 1;
    end

    assign rptr_gray = (rptr_bin_next >> 1) ^ rptr_bin_next;

    integer j;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (j=0; j < SYNC_STAGES; j=j+1)
                wptr_gray_sync[j] <= 0;
        end else begin
            wptr_gray_sync[0] <= wptr_gray;
            for (j=1; j < SYNC_STAGES; j=j+1)
                wptr_gray_sync[j] <= wptr_gray_sync[j-1];
        end
    end

    assign dst_data_o = mem[rptr_bin[PTR_WIDTH-2:0]];

endmodule
