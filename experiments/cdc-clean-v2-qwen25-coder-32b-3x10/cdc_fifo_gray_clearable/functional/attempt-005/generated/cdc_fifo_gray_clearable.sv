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

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [ADDR_WIDTH:0] src_wr_ptr_gray, src_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] src_wr_ptr_bin, src_wr_ptr_bin_next;
    reg [ADDR_WIDTH:0] src_rd_ptr_gray, src_rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] src_rd_ptr_bin, src_rd_ptr_bin_next;

    reg [ADDR_WIDTH:0] dst_wr_ptr_gray, dst_wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] dst_wr_ptr_bin, dst_wr_ptr_bin_next;
    reg [ADDR_WIDTH:0] dst_rd_ptr_gray, dst_rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] dst_rd_ptr_bin, dst_rd_ptr_bin_next;

    reg [WIDTH-1:0] mem [0:DEPTH-1];

    reg src_clear_pending, dst_clear_pending;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= 0;
            src_wr_ptr_bin <= 0;
            src_clear_pending <= 0;
        end else if (src_clear_i) begin
            src_wr_ptr_gray <= 0;
            src_wr_ptr_bin <= 0;
            src_clear_pending <= 1;
        end else if (src_ready_o && src_valid_i) begin
            src_wr_ptr_bin <= src_wr_ptr_bin_next;
            src_wr_ptr_gray <= src_wr_ptr_bin_next ^ (src_wr_ptr_bin_next >> 1);
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_gray <= 0;
            src_rd_ptr_bin <= 0;
        end else if (src_clear_i) begin
            src_rd_ptr_gray <= 0;
            src_rd_ptr_bin <= 0;
        end else if (dst_ready_i && dst_valid_o) begin
            src_rd_ptr_bin <= src_rd_ptr_bin_next;
            src_rd_ptr_gray <= src_rd_ptr_bin_next ^ (src_rd_ptr_bin_next >> 1);
        end
    end

    always @(*) begin
        src_wr_ptr_bin_next = src_wr_ptr_bin + 1;
        src_rd_ptr_bin_next = src_rd_ptr_bin + 1;
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending_o <= 0;
        end else begin
            src_clear_pending_o <= src_clear_pending;
        end
    end

    assign src_ready_o = (src_wr_ptr_bin_next != src_rd_ptr_bin);

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_gray <= 0;
            dst_wr_ptr_bin <= 0;
            dst_clear_pending <= 0;
        end else if (dst_clear_i) begin
            dst_wr_ptr_gray <= 0;
            dst_wr_ptr_bin <= 0;
            dst_clear_pending <= 1;
        end else if (dst_ready_i && dst_valid_o) begin
            dst_wr_ptr_bin <= dst_wr_ptr_bin_next;
            dst_wr_ptr_gray <= dst_wr_ptr_bin_next ^ (dst_wr_ptr_bin_next >> 1);
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_gray <= 0;
            dst_rd_ptr_bin <= 0;
        end else if (dst_clear_i) begin
            dst_rd_ptr_gray <= 0;
            dst_rd_ptr_bin <= 0;
        end else if (src_ready_o && src_valid_i) begin
            dst_rd_ptr_bin <= dst_rd_ptr_bin_next;
            dst_rd_ptr_gray <= dst_rd_ptr_bin_next ^ (dst_rd_ptr_bin_next >> 1);
        end
    end

    always @(*) begin
        dst_wr_ptr_bin_next = dst_wr_ptr_bin + 1;
        dst_rd_ptr_bin_next = dst_rd_ptr_bin + 1;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending_o <= 0;
        end else begin
            dst_clear_pending_o <= dst_clear_pending;
        end
    end

    // Gray code synchronization
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    src_wr_ptr_gray_sync[i] <= 0;
                end else begin
                    src_wr_ptr_gray_sync[i] <= (i == 0) ? src_wr_ptr_gray[0] : src_wr_ptr_gray_sync[i-1];
                end
            end

            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    dst_wr_ptr_gray_sync[i] <= 0;
                end else begin
                    dst_wr_ptr_gray_sync[i] <= (i == 0) ? dst_wr_ptr_gray[0] : dst_wr_ptr_gray_sync[i-1];
                end
            end

            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    src_rd_ptr_gray_sync[i] <= 0;
                end else begin
                    src_rd_ptr_gray_sync[i] <= (i == 0) ? src_rd_ptr_gray[0] : src_rd_ptr_gray_sync[i-1];
                end
            end

            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    dst_rd_ptr_gray_sync[i] <= 0;
                end else begin
                    dst_rd_ptr_gray_sync[i] <= (i == 0) ? dst_rd_ptr_gray[0] : dst_rd_ptr_gray_sync[i-1];
                end
            end
        end
    endgenerate

    // Convert synchronized Gray code to binary
    always @(*) begin
        src_wr_ptr_bin_sync = src_wr_ptr_gray_sync[SYNC_STAGES-1];
        src_rd_ptr_bin_sync = src_rd_ptr_gray_sync[SYNC_STAGES-1];
        dst_wr_ptr_bin_sync = dst_wr_ptr_gray_sync[SYNC_STAGES-1];
        dst_rd_ptr_bin_sync = dst_rd_ptr_gray_sync[SYNC_STAGES-1];

        for (i = ADDR_WIDTH-1; i > 0; i = i - 1) begin
            src_wr_ptr_bin_sync = src_wr_ptr_bin_sync ^ src_wr_ptr_gray_sync[SYNC_STAGES-1][i];
            src_rd_ptr_bin_sync = src_rd_ptr_bin_sync ^ src_rd_ptr_gray_sync[SYNC_STAGES-1][i];
            dst_wr_ptr_bin_sync = dst_wr_ptr_bin_sync ^ dst_wr_ptr_gray_sync[SYNC_STAGES-1][i];
            dst_rd_ptr_bin_sync = dst_rd_ptr_bin_sync ^ dst_rd_ptr_gray_sync[SYNC_STAGES-1][i];
        end
    end

    // Memory write and read
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            mem <= '{default: 0};
        end else if (src_ready_o && src_valid_i) begin
            mem[src_wr_ptr_bin] <= src_data_i;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
            dst_valid_o <= 0;
        end else if (dst_ready_i && dst_valid_o) begin
            dst_valid_o <= 0;
        end else if (src_wr_ptr_bin_sync != dst_rd_ptr_bin) begin
            dst_data_o <= mem[dst_rd_ptr_bin];
            dst_valid_o <= 1;
        end
    end

endmodule
