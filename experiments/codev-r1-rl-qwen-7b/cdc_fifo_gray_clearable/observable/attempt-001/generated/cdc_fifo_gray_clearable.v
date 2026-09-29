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
    reg [PTR_WIDTH-1:0] wr_ptr_bin, wr_ptr_gray;
    reg [PTR_WIDTH-1:0] rd_ptr_bin, rd_ptr_gray;

    function [PTR_WIDTH-1:0] bin2gray(input [PTR_WIDTH-1:0] bin);
        bin2gray = (bin >> 1) ^ bin;
    endfunction

    // Write domain signals
    reg [SYNC_STAGES-1:0] dst_clear_sync [0:1];
    reg src_clear_pending;

    // Read domain signals
    reg [SYNC_STAGES-1:0] src_clear_sync [0:1];
    reg dst_clear_pending;

    // Write domain logic
    wire clear_src = src_clear_i | |dst_clear_sync[0];
    wire full;
    wire [PTR_WIDTH-1:0] wr_ptr_bin_next = wr_ptr_bin + 1;

    // Synchronize dst_clear to src_clk
    integer i;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (i=0; i < SYNC_STAGES; i=i+1)
                dst_clear_sync[0][i] <= 0;
        end else begin
            dst_clear_sync[0] <= {dst_clear_sync[0][SYNC_STAGES-2:0], dst_clear_i};
        end
    end

    // Write pointer update
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else if (clear_src) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else if (src_valid_i && src_ready_o) begin
            wr_ptr_bin <= wr_ptr_bin_next;
            wr_ptr_gray <= bin2gray(wr_ptr_bin_next);
        end
    end

    // Read pointer synchronization in write domain
    reg [PTR_WIDTH-1:0] rd_ptr_gray_sync [0:SYNC_STAGES-1];
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (i=0; i < SYNC_STAGES; i=i+1)
                rd_ptr_gray_sync[i] <= 0;
        end else begin
            rd_ptr_gray_sync[0] <= rd_ptr_gray;
            for (i=1; i < SYNC_STAGES; i=i+1)
                rd_ptr_gray_sync[i] <= rd_ptr_gray_sync[i-1];
        end
    end

    // Full condition
    assign full = (wr_ptr_gray == { ~rd_ptr_gray_sync[SYNC_STAGES-1][PTR_WIDTH-2:0], rd_ptr_gray_sync[SYNC_STAGES-1][PTR_WIDTH-1] });

    // Source ready
    assign src_ready_o = !full;

    // Pending in write domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 0;
        end else begin
            if (clear_src)
                src_clear_pending <= 1;
            else if (wr_ptr_bin == 0)
                src_clear_pending <= 0;
        end
    end
    assign src_clear_pending_o = src_clear_pending;

    // Read domain logic
    wire clear_dst = dst_clear_i | |src_clear_sync[0];
    wire empty;
    wire [PTR_WIDTH-1:0] rd_ptr_bin_next = rd_ptr_bin + 1;

    // Synchronize src_clear to dst_clk
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (i=0; i < SYNC_STAGES; i=i+1)
                src_clear_sync[0][i] <= 0;
        end else begin
            src_clear_sync[0] <= {src_clear_sync[0][SYNC_STAGES-2:0], src_clear_i};
        end
    end

    // Read pointer update
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
        end else if (clear_dst) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            rd_ptr_bin <= rd_ptr_bin_next;
            rd_ptr_gray <= bin2gray(rd_ptr_bin_next);
        end
    end

    // Write pointer synchronization in read domain
    reg [PTR_WIDTH-1:0] wr_ptr_gray_sync [0:SYNC_STAGES-1];
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (i=0; i < SYNC_STAGES; i=i+1)
                wr_ptr_gray_sync[i] <= 0;
        end else begin
            wr_ptr_gray_sync[0] <= wr_ptr_gray;
            for (i=1; i < SYNC_STAGES; i=i+1)
                wr_ptr_gray_sync[i] <= wr_ptr_gray_sync[i-1];
        end
    end

    // Empty condition
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync[SYNC_STAGES-1]);

    // Destination valid
    assign dst_valid_o = !empty;

    // Data output
    assign dst_data_o = mem[rd_ptr_bin[LOG_DEPTH-1:0]];

    // Pending in read domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 0;
        end else begin
            if (clear_dst)
                dst_clear_pending <= 1;
            else if (rd_ptr_bin == 0)
                dst_clear_pending <= 0;
        end
    end
    assign dst_clear_pending_o = dst_clear_pending;

    // Memory write
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o)
            mem[wr_ptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
    end

endmodule
