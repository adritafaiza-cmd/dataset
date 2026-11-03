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
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [ADDR_WIDTH:0] src_wr_ptr_gray, src_wr_ptr_gray_nxt;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray_sync;
    reg [WIDTH-1:0] mem [DEPTH-1:0];

    reg [ADDR_WIDTH:0] dst_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray, dst_rd_ptr_gray_nxt;

    // Source domain logic
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

    // Binary to Gray conversion for write pointer
    wire [ADDR_WIDTH:0] src_wr_ptr_bin = src_wr_ptr_gray ^ (src_wr_ptr_gray >> 1);

    // Gray to Binary conversion for read pointer sync
    wire [ADDR_WIDTH:0] src_rd_ptr_bin_sync = src_rd_ptr_gray_sync ^ (src_rd_ptr_gray_sync >> 1);

    // Source ready logic
    assign src_ready_o = (src_wr_ptr_bin != (src_rd_ptr_bin_sync + 1));

    // Memory write logic
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o) begin
            mem[src_wr_ptr_bin[ADDR_WIDTH-1:0]] <= src_data_i;
        end
    end

    // Synchronize write pointer to destination domain
    reg [ADDR_WIDTH:0] src_wr_ptr_gray_sync [SYNC_STAGES-1:0];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            src_wr_ptr_gray_sync[0] <= src_wr_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                src_wr_ptr_gray_sync[i] <= src_wr_ptr_gray_sync[i-1];
            end
        end
    end

    assign src_rd_ptr_gray_sync = src_wr_ptr_gray_sync[SYNC_STAGES-1];

    // Destination domain logic
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

    // Binary to Gray conversion for read pointer
    wire [ADDR_WIDTH:0] dst_rd_ptr_bin = dst_rd_ptr_gray ^ (dst_rd_ptr_gray >> 1);

    // Gray to Binary conversion for write pointer sync
    wire [ADDR_WIDTH:0] dst_wr_ptr_bin_sync = dst_wr_ptr_gray_sync ^ (dst_wr_ptr_gray_sync >> 1);

    // Destination valid logic
    assign dst_valid_o = (dst_wr_ptr_bin_sync != dst_rd_ptr_bin);

    // Memory read logic
    always @(posedge dst_clk_i) begin
        if (dst_valid_o && dst_ready_i) begin
            dst_data_o <= mem[dst_rd_ptr_bin[ADDR_WIDTH-1:0]];
        end
    end

    // Synchronize read pointer to source domain
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray_sync [SYNC_STAGES-1:0];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_rd_ptr_gray_sync[0] <= dst_rd_ptr_gray;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                dst_rd_ptr_gray_sync[i] <= dst_rd_ptr_gray_sync[i-1];
            end
        end
    end

    assign dst_wr_ptr_gray_sync = dst_rd_ptr_gray_sync[SYNC_STAGES-1];

endmodule
