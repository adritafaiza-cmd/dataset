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

    localparam DEPTH = 2**LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [WIDTH-1:0] mem [DEPTH-1:0];

    reg [ADDR_WIDTH:0] src_wr_ptr_gray, src_wr_ptr_gray_nxt, src_wr_ptr_bin;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray, dst_rd_ptr_gray_nxt, dst_rd_ptr_bin;

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= 0;
        end else begin
            src_wr_ptr_gray <= src_wr_ptr_gray_nxt;
        end
    end

    always @(*) begin
        src_wr_ptr_gray_nxt = src_wr_ptr_gray;
        if (src_valid_i && src_ready_o) begin
            src_wr_ptr_gray_nxt = src_wr_ptr_gray + 1;
        end
    end

    assign src_wr_ptr_bin = (src_wr_ptr_gray >> 1) ^ src_wr_ptr_gray;

    // Destination side logic
    reg [ADDR_WIDTH:0] src_wr_ptr_gray_sync [SYNC_STAGES-1:0];

    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    src_wr_ptr_gray_sync[i] <= 0;
                end else begin
                    src_wr_ptr_gray_sync[i] <= (i == 0) ? src_wr_ptr_gray : src_wr_ptr_gray_sync[i-1];
                end
            end
        end
    endgenerate

    assign dst_wr_ptr_gray = src_wr_ptr_gray_sync[SYNC_STAGES-1];
    assign dst_wr_ptr_bin = (dst_wr_ptr_gray >> 1) ^ dst_wr_ptr_gray;

    reg [ADDR_WIDTH:0] dst_rd_ptr_gray_nxt;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_gray <= 0;
        end else begin
            dst_rd_ptr_gray <= dst_rd_ptr_gray_nxt;
        end
    end

    always @(*) begin
        dst_rd_ptr_gray_nxt = dst_rd_ptr_gray;
        if (dst_valid_o && dst_ready_i) begin
            dst_rd_ptr_gray_nxt = dst_rd_ptr_gray + 1;
        end
    end

    assign dst_rd_ptr_bin = (dst_rd_ptr_gray >> 1) ^ dst_rd_ptr_gray;

    // FIFO control signals
    assign src_ready_o = (src_wr_ptr_bin != (dst_wr_ptr_bin - 1));
    assign dst_valid_o = (dst_wr_ptr_bin != dst_rd_ptr_bin);

    // Data memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            // No action needed for memory reset
        end else if (src_valid_i && src_ready_o) begin
            mem[src_wr_ptr_bin[ADDR_WIDTH-1:0]] <= src_data_i;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_data_o <= mem[dst_rd_ptr_bin[ADDR_WIDTH-1:0]];
        end
    end

endmodule
