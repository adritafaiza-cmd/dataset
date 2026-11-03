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

    // Source domain signals
    reg [ADDR_WIDTH:0] src_wr_ptr_gray;
    reg [ADDR_WIDTH:0] src_wr_ptr_bin;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray_sync;
    reg [WIDTH-1:0]    mem [DEPTH-1:0];

    // Destination domain signals
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray;
    reg [ADDR_WIDTH:0] dst_rd_ptr_bin;
    reg [ADDR_WIDTH:0] dst_wr_ptr_gray_sync;
    reg [WIDTH-1:0]    dst_data_reg [SYNC_STAGES-1:0];
    reg [SYNC_STAGES-1:0] dst_valid_reg;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= 0;
            src_wr_ptr_bin <= 0;
        end else if (src_valid_i && src_ready_o) begin
            src_wr_ptr_bin <= src_wr_ptr_bin + 1;
            src_wr_ptr_gray <= src_wr_ptr_bin ^ (src_wr_ptr_bin >> 1);
            mem[src_wr_ptr_bin[ADDR_WIDTH-1:0]] <= src_data_i;
        end
    end

    // Gray code to binary conversion for source read pointer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray_sync <= 0;
        end else begin
            src_rd_ptr_gray_sync <= dst_wr_ptr_gray_sync;
        end
    end

    assign src_ready_o = (src_wr_ptr_gray != src_rd_ptr_gray_sync);

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_gray <= 0;
            dst_rd_ptr_bin <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_rd_ptr_bin <= dst_rd_ptr_bin + 1;
            dst_rd_ptr_gray <= dst_rd_ptr_bin ^ (dst_rd_ptr_bin >> 1);
        end
    end

    // Gray code to binary conversion for destination write pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray_sync <= 0;
        end else begin
            dst_wr_ptr_gray_sync <= src_wr_ptr_gray;
        end
    end

    // Data and valid synchronization stages
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    dst_data_reg[i] <= 0;
                    dst_valid_reg[i] <= 0;
                end else if (i == 0) begin
                    if (src_valid_i && src_ready_o) begin
                        dst_data_reg[i] <= mem[src_wr_ptr_bin[ADDR_WIDTH-1:0]];
                        dst_valid_reg[i] <= 1;
                    end else begin
                        dst_valid_reg[i] <= 0;
                    end
                end else begin
                    dst_data_reg[i] <= dst_data_reg[i-1];
                    dst_valid_reg[i] <= dst_valid_reg[i-1];
                end
            end
        end
    endgenerate

    assign dst_data_o = dst_data_reg[SYNC_STAGES-1];
    assign dst_valid_o = dst_valid_reg[SYNC_STAGES-1];

endmodule
