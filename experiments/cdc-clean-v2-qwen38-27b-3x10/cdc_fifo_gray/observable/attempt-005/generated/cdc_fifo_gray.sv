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

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Storage
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Source side pointers
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] src_rd_ptr_synced;

    // Destination side pointers
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_synced;

    // Gray code pointers
    wire [PTR_WIDTH-1:0] src_wr_ptr_gray = src_wr_ptr ^ (src_wr_ptr >> 1);
    wire [PTR_WIDTH-1:0] src_rd_ptr_gray = src_rd_ptr_synced ^ (src_rd_ptr_synced >> 1);
    wire [PTR_WIDTH-1:0] dst_rd_ptr_gray = dst_rd_ptr ^ (dst_rd_ptr >> 1);
    wire [PTR_WIDTH-1:0] dst_wr_ptr_gray = dst_wr_ptr_synced ^ (dst_wr_ptr_synced >> 1);

    // Synchronizers for write pointer (src -> dst)
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync [0:SYNC_STAGES-1];
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_sync[0] <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_sync[1] <= {PTR_WIDTH{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    src_wr_ptr_gray_sync[i] <= {PTR_WIDTH{1'b0}};
            end
        end else begin
            src_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
            src_wr_ptr_gray_sync[1] <= src_wr_ptr_gray_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    src_wr_ptr_gray_sync[i] <= src_wr_ptr_gray_sync[i-1];
            end
        end
    end

    // Synchronizers for read pointer (dst -> src)
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync [0:SYNC_STAGES-1];
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_sync[0] <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_sync[1] <= {PTR_WIDTH{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    dst_rd_ptr_gray_sync[i] <= {PTR_WIDTH{1'b0}};
            end
        end else begin
            dst_rd_ptr_gray_sync[0] <= dst_rd_ptr_gray;
            dst_rd_ptr_gray_sync[1] <= dst_rd_ptr_gray_sync[0];
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    dst_rd_ptr_gray_sync[i] <= dst_rd_ptr_gray_sync[i-1];
            end
        end
    end

    // Convert synchronized gray to binary
    function [PTR_WIDTH-1:0] gray_to_bin;
        input [PTR_WIDTH-1:0] gray;
        integer i;
        begin
            gray_to_bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
                gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
        end
    endfunction

    // Synchronized binary pointers
    wire [PTR_WIDTH-1:0] src_wr_ptr_synced_bin = gray_to_bin(src_wr_ptr_gray_sync[SYNC_STAGES-1]);
    wire [PTR_WIDTH-1:0] dst_rd_ptr_synced_bin = gray_to_bin(dst_rd_ptr_gray_sync[SYNC_STAGES-1]);

    // Update synced pointers
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_rd_ptr_synced <= {PTR_WIDTH{1'b0}};
        else
            src_rd_ptr_synced <= dst_rd_ptr_synced_bin;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_wr_ptr_synced <= {PTR_WIDTH{1'b0}};
        else
            dst_wr_ptr_synced <= src_wr_ptr_synced_bin;
    end

    // Full and empty detection
    // Full: write pointer has lapped read pointer by DEPTH
    wire src_full = (src_wr_ptr[PTR_WIDTH-1:1] == src_rd_ptr_synced[PTR_WIDTH-1:1]) &&
                    (src_wr_ptr[0] != src_rd_ptr_synced[0]);

    wire dst_empty = (dst_rd_ptr == dst_wr_ptr_synced);

    // Source side: write
    wire src_write_en = src_valid_i && !src_full;
    assign src_ready_o = !src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
        else if (src_write_en) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    // Destination side: read
    wire dst_read_en = dst_ready_i && !dst_empty;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_data_o <= {WIDTH{1'b0}};
            dst_valid_o <= 1'b0;
        end else begin
            if (dst_read_en) begin
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
            end
            // Output valid and data
            if (!dst_empty) begin
                dst_data_o <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_o <= 1'b1;
            end else begin
                dst_valid_o <= 1'b0;
            end
        end
    end

endmodule
