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

    // Source domain
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] dst_rd_ptr_synced;

    // Destination domain
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] src_wr_ptr_synced;
    reg [WIDTH-1:0] dst_data_reg;
    reg             dst_valid_reg;

    // Gray code conversion
    function [PTR_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Source domain: write pointer and ready
    wire [PTR_W-1:0] src_wr_ptr_gray = bin2gray(src_wr_ptr);
    wire [PTR_W-1:0] dst_rd_ptr_gray_synced = bin2gray(dst_rd_ptr_synced);

    wire src_full = (src_wr_ptr_gray == dst_rd_ptr_gray_synced) &&
                    (src_wr_ptr[PTR_W-1] != dst_rd_ptr_synced[PTR_W-1]);
    wire src_can_write = src_valid_i && !src_full;

    assign src_ready_o = !src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
        end else if (src_can_write) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    // Synchronize source write pointer gray to destination domain
    reg [PTR_W-1:0] src_wr_ptr_gray_sync [0:SYNC_STAGES-1];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_sync[0] <= {PTR_W{1'b0}};
            src_wr_ptr_gray_sync[1] <= {PTR_W{1'b0}};
            if (SYNC_STAGES > 2) begin
                for (int i = 2; i < SYNC_STAGES; i = i + 1)
                    src_wr_ptr_gray_sync[i] <= {PTR_W{1'b0}};
            end
        end else begin
            src_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
            src_wr_ptr_gray_sync[1] <= src_wr_ptr_gray_sync[0];
            if (SYNC_STAGES > 2) begin
                for (int i = 2; i < SYNC_STAGES; i = i + 1)
                    src_wr_ptr_gray_sync[i] <= src_wr_ptr_gray_sync[i-1];
            end
        end
    end

    // Convert synced gray to binary in destination domain
    function [PTR_W-1:0] gray2bin;
        input [PTR_W-1:0] gray;
        integer i;
        begin
            gray2bin[PTR_W-1] = gray[PTR_W-1];
            for (i = PTR_W-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    wire [PTR_W-1:0] src_wr_ptr_synced_bin = gray2bin(src_wr_ptr_gray_sync[SYNC_STAGES-1]);

    // Synchronize destination read pointer gray to source domain
    wire [PTR_W-1:0] dst_rd_ptr_gray = bin2gray(dst_rd_ptr);
    reg [PTR_W-1:0] dst_rd_ptr_gray_sync [0:SYNC_STAGES-1];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_sync[0] <= {PTR_W{1'b0}};
            dst_rd_ptr_gray_sync[1] <= {PTR_W{1'b0}};
            if (SYNC_STAGES > 2) begin
                for (int i = 2; i < SYNC_STAGES; i = i + 1)
                    dst_rd_ptr_gray_sync[i] <= {PTR_W{1'b0}};
            end
        end else begin
            dst_rd_ptr_gray_sync[0] <= dst_rd_ptr_gray;
            dst_rd_ptr_gray_sync[1] <= dst_rd_ptr_gray_sync[0];
            if (SYNC_STAGES > 2) begin
                for (int i = 2; i < SYNC_STAGES; i = i + 1)
                    dst_rd_ptr_gray_sync[i] <= dst_rd_ptr_gray_sync[i-1];
            end
        end
    end

    wire [PTR_W-1:0] dst_rd_ptr_synced_bin = gray2bin(dst_rd_ptr_gray_sync[SYNC_STAGES-1]);
    assign dst_rd_ptr_synced = dst_rd_ptr_synced_bin;

    // Destination domain: read logic
    wire dst_empty = (dst_rd_ptr_gray == src_wr_ptr_gray_sync[SYNC_STAGES-1]) &&
                     (dst_rd_ptr[PTR_W-1] == src_wr_ptr_synced_bin[PTR_W-1]);
    wire dst_can_read = !dst_empty && dst_ready_i;

    // Two-stage pipeline for data transfer
    reg [WIDTH-1:0] pipe_data_1;
    reg             pipe_valid_1;
    reg [WIDTH-1:0] pipe_data_2;
    reg             pipe_valid_2;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_W{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
            pipe_data_1 <= {WIDTH{1'b0}};
            pipe_valid_1 <= 1'b0;
            pipe_data_2 <= {WIDTH{1'b0}};
            pipe_valid_2 <= 1'b0;
        end else begin
            // Stage 1: read from memory
            if (dst_can_read) begin
                pipe_data_1 <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                pipe_valid_1 <= 1'b1;
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
            end else begin
                pipe_valid_1 <= 1'b0;
            end

            // Stage 2: output
            pipe_data_2 <= pipe_data_1;
            pipe_valid_2 <= pipe_valid_1;
        end
    end

    assign dst_data_o = pipe_data_2;
    assign dst_valid_o = pipe_valid_2;

endmodule
