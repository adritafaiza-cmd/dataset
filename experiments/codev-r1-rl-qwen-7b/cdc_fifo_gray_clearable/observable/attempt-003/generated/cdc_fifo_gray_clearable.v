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

    // Source domain signals
    reg [PTR_WIDTH-1:0] wptr_bin;
    wire [PTR_WIDTH-1:0] wptr_gray;
    reg [PTR_WIDTH-1:0] rptr_gray_synced [SYNC_STAGES-1:0];
    wire [PTR_WIDTH-1:0] rptr_bin_synced;

    // Destination domain signals
    reg [PTR_WIDTH-1:0] rptr_bin;
    wire [PTR_WIDTH-1:0] rptr_gray;
    reg [PTR_WIDTH-1:0] wptr_gray_synced [SYNC_STAGES-1:0];
    wire [PTR_WIDTH-1:0] wptr_bin_synced;

    // Memory
    reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH)-1];

    // Synchronization registers for clear
    reg [SYNC_STAGES-1:0] dst_clear_sync;
    reg [SYNC_STAGES-1:0] src_clear_sync;

    // Clear signals
    wire clear_src;
    wire clear_dst;

    // Gray code conversion functions
    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [PTR_WIDTH-1:0] gray2bin;
        input [PTR_WIDTH-1:0] gray;
        reg [PTR_WIDTH-1:0] bin;
        integer j;
        begin
            bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (j = PTR_WIDTH-2; j >= 0; j = j - 1)
                bin[j] = bin[j+1] ^ gray[j];
            gray2bin = bin;
        end
    endfunction

    // Source domain logic
    // Synchronize dst_clear_i to src_clk
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_clear_sync <= 0;
        else
            dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
    end
    wire dst_clear_synced = dst_clear_sync[SYNC_STAGES-1];
    assign clear_src = src_clear_i || dst_clear_synced;

    // Write pointer update
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            wptr_bin <= 0;
        else if (clear_src)
            wptr_bin <= 0;
        else if (src_valid_i && src_ready_o)
            wptr_bin <= wptr_bin + 1;
    end

    assign wptr_gray = bin2gray(wptr_bin);

    // Synchronize rptr_gray to src_clk
    generate
        genvar i;
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin: sync_rptr_src
            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni)
                    rptr_gray_synced[i] <= 0;
                else
                    rptr_gray_synced[i] <= (i == 0) ? rptr_gray : rptr_gray_synced[i-1];
            end
        end
    endgenerate

    assign rptr_bin_synced = gray2bin(rptr_gray_synced[SYNC_STAGES-1]);

    // Full condition
    wire full = ((wptr_bin[PTR_WIDTH-1] != rptr_bin_synced[PTR_WIDTH-1]) &&
                 (wptr_bin[PTR_WIDTH-2:0] == rptr_bin_synced[PTR_WIDTH-2:0]));

    // src_ready_o is !full
    assign src_ready_o = !full;

    // Memory write
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o)
            mem[wptr_bin[PTR_WIDTH-2:0]] <= src_data_i;
    end

    // Destination domain logic
    // Synchronize src_clear_i to dst_clk
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_clear_sync <= 0;
        else
            src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
    end
    wire src_clear_synced = src_clear_sync[SYNC_STAGES-1];
    assign clear_dst = dst_clear_i || src_clear_synced;

    // Read pointer update
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            rptr_bin <= 0;
        else if (clear_dst)
            rptr_bin <= 0;
        else if (dst_valid_o && dst_ready_i)
            rptr_bin <= rptr_bin + 1;
    end

    assign rptr_gray = bin2gray(rptr_bin);

    // Synchronize wptr_gray to dst_clk
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin: sync_wptr_dst
            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni)
                    wptr_gray_synced[i] <= 0;
                else
                    wptr_gray_synced[i] <= (i == 0) ? wptr_gray : wptr_gray_synced[i-1];
            end
        end
    endgenerate

    assign wptr_bin_synced = gray2bin(wptr_gray_synced[SYNC_STAGES-1]);

    // Empty condition
    wire empty = (rptr_bin == wptr_bin_synced);

    // dst_valid_o is !empty
    assign dst_valid_o = !empty;

    // Memory read
    assign dst_data_o = mem[rptr_bin[PTR_WIDTH-2:0]];

    // Pending flags
    reg src_clear_pending;
    reg dst_clear_pending;

    // Source pending flag
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_clear_pending <= 0;
        else begin
            if (clear_src)
                src_clear_pending <= 1;
            else if (empty)
                src_clear_pending <= 0;
        end
    end

    assign src_clear_pending_o = src_clear_pending;

    // Destination pending flag
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_clear_pending <= 0;
        else begin
            if (clear_dst)
                dst_clear_pending <= 1;
            else if (empty)
                dst_clear_pending <= 0;
        end
    end

    assign dst_clear_pending_o = dst_clear_pending;

endmodule
