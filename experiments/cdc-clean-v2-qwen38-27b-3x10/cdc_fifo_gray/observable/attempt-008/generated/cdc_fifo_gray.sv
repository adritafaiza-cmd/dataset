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
    localparam PTR_W = LOG_DEPTH + 1;

    // Storage
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Source-side pointers
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] src_rd_ptr_sync; // synchronized read pointer from dst

    // Destination-side pointers
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] dst_wr_ptr_sync; // synchronized write pointer from src

    // Gray code pointers
    wire [PTR_W-1:0] src_wr_ptr_gray = src_wr_ptr ^ (src_wr_ptr >> 1);
    wire [PTR_W-1:0] dst_rd_ptr_gray = dst_rd_ptr ^ (dst_rd_ptr >> 1);

    // Synchronize src_wr_ptr_gray to dst domain
    reg [PTR_W-1:0] src_wr_ptr_gray_sync [0:SYNC_STAGES-1];
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_sync[0] <= {PTR_W{1'b0}};
            src_wr_ptr_gray_sync[1] <= {PTR_W{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    src_wr_ptr_gray_sync[i] <= {PTR_W{1'b0}};
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

    // Synchronize dst_rd_ptr_gray to src domain
    reg [PTR_W-1:0] dst_rd_ptr_gray_sync [0:SYNC_STAGES-1];
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_sync[0] <= {PTR_W{1'b0}};
            dst_rd_ptr_gray_sync[1] <= {PTR_W{1'b0}};
            if (SYNC_STAGES > 2) begin
                integer i;
                for (i = 2; i < SYNC_STAGES; i = i + 1)
                    dst_rd_ptr_gray_sync[i] <= {PTR_W{1'b0}};
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

    // Convert synchronized gray codes back to binary
    function [PTR_W-1:0] gray2bin;
        input [PTR_W-1:0] gray;
        integer i;
        begin
            gray2bin[PTR_W-1] = gray[PTR_W-1];
            for (i = PTR_W-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    wire [PTR_W-1:0] dst_wr_ptr_sync_bin = gray2bin(src_wr_ptr_gray_sync[SYNC_STAGES-1]);
    wire [PTR_W-1:0] src_rd_ptr_sync_bin = gray2bin(dst_rd_ptr_gray_sync[SYNC_STAGES-1]);

    // Source side: write logic
    wire src_full = (src_wr_ptr == src_rd_ptr_sync_bin) && (src_wr_ptr[PTR_W-1] != src_rd_ptr_sync_bin[PTR_W-1]);
    wire src_can_write = src_valid_i && !src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_wr_ptr <= {PTR_W{1'b0}};
        else if (src_can_write)
            src_wr_ptr <= src_wr_ptr + 1'b1;
    end

    always @(posedge src_clk_i) begin
        if (src_can_write)
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
    end

    assign src_ready_o = !src_full;

    // Destination side: read logic
    wire dst_empty = (dst_rd_ptr == dst_wr_ptr_sync_bin) && (dst_rd_ptr[PTR_W-1] == dst_wr_ptr_sync_bin[PTR_W-1]);
    wire dst_can_read = !dst_empty && dst_ready_i;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_rd_ptr <= {PTR_W{1'b0}};
        else if (dst_can_read)
            dst_rd_ptr <= dst_rd_ptr + 1'b1;
    end

    assign dst_data_o = mem[dst_rd_ptr[LOG_DEPTH-1:0]];
    assign dst_valid_o = !dst_empty;

endmodule
