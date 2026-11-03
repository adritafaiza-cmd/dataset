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

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [WIDTH-1:0] mem [DEPTH-1:0];
    reg [ADDR_WIDTH:0] src_wr_ptr, src_wr_ptr_gray, src_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] dst_rd_ptr, dst_rd_ptr_gray, dst_rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] src_wr_ptr_gray_sync2;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray_sync2;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_wr_ptr_gray <= 0;
        end else begin
            if (src_ready_o && src_valid_i) begin
                mem[src_wr_ptr[ADDR_WIDTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1;
                src_wr_ptr_gray <= (src_wr_ptr + 1) ^ ((src_wr_ptr + 1) >> 1);
            end
        end
    end

    // Gray code synchronization for src_wr_ptr_gray to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_sync <= 0;
            src_wr_ptr_gray_sync2 <= 0;
        end else begin
            src_wr_ptr_gray_sync <= src_wr_ptr_gray;
            src_wr_ptr_gray_sync2 <= src_wr_ptr_gray_sync;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_rd_ptr_gray <= 0;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                dst_rd_ptr <= dst_rd_ptr + 1;
                dst_rd_ptr_gray <= (dst_rd_ptr + 1) ^ ((dst_rd_ptr + 1) >> 1);
            end
        end
    end

    // Gray code synchronization for dst_rd_ptr_gray to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_sync <= 0;
            dst_rd_ptr_gray_sync2 <= 0;
        end else begin
            dst_rd_ptr_gray_sync <= dst_rd_ptr_gray;
            dst_rd_ptr_gray_sync2 <= dst_rd_ptr_gray_sync;
        end
    end

    // Binary conversion and full/empty flags
    wire [ADDR_WIDTH:0] src_wr_ptr_bin_sync2;
    wire [ADDR_WIDTH:0] dst_rd_ptr_bin_sync2;

    assign src_wr_ptr_bin_sync2 = {src_wr_ptr_gray_sync2[ADDR_WIDTH], src_wr_ptr_gray_sync2[ADDR_WIDTH-1:0] ^ (src_wr_ptr_gray_sync2 >> 1)};
    assign dst_rd_ptr_bin_sync2 = {dst_rd_ptr_gray_sync2[ADDR_WIDTH], dst_rd_ptr_gray_sync2[ADDR_WIDTH-1:0] ^ (dst_rd_ptr_gray_sync2 >> 1)};

    wire full = (src_wr_ptr_bin_sync2 == {1'b1, dst_rd_ptr_bin_sync2[ADDR_WIDTH-1:0]});
    wire empty = (src_wr_ptr_bin_sync2 == dst_rd_ptr_bin_sync2);

    // Source ready and destination valid
    assign src_ready_o = ~full;
    assign dst_valid_o = ~empty;

    // Destination data output
    reg [WIDTH-1:0] dst_data_reg1, dst_data_reg2;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg1 <= 0;
            dst_data_reg2 <= 0;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                dst_data_reg1 <= mem[dst_rd_ptr[ADDR_WIDTH-1:0]];
                dst_data_reg2 <= dst_data_reg1;
            end
        end
    end

    assign dst_data_o = dst_data_reg2;

endmodule
