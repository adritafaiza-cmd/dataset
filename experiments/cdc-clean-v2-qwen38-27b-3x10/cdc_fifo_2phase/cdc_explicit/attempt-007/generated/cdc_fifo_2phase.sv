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
    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Source domain: write pointer
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [ADDR_WIDTH-1:0] src_wr_addr;

    // Destination domain: read pointer
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [ADDR_WIDTH-1:0] dst_rd_addr;

    // Synchronizers for pointers
    reg [PTR_WIDTH-1:0] src_wr_ptr_dst_sync1;
    reg [PTR_WIDTH-1:0] src_wr_ptr_dst_sync2;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_src_sync1;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_src_sync2;

    // FIFO storage
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Destination domain: two-stage pipeline for data
    reg [WIDTH-1:0] dst_data_stage1;
    reg [WIDTH-1:0] dst_data_stage2;
    reg             dst_valid_stage1;
    reg             dst_valid_stage2;

    // Source domain: write enable
    wire src_wr_en = src_valid_i & src_ready_o;

    // Destination domain: read enable
    wire dst_rd_en = dst_valid_o & dst_ready_i;

    // Compute src_ready_o: FIFO not full
    // Full when write pointer has lapped read pointer by DEPTH
    wire [PTR_WIDTH-1:0] src_wr_ptr_synced = src_wr_ptr;
    wire [PTR_WIDTH-1:0] dst_rd_ptr_src = dst_rd_ptr_src_sync2;
    wire src_full = (src_wr_ptr[PTR_WIDTH-1] != dst_rd_ptr_src[PTR_WIDTH-1]) &&
                    (src_wr_ptr[ADDR_WIDTH-1:0] == dst_rd_ptr_src[ADDR_WIDTH-1:0]);
    assign src_ready_o = ~src_full;

    // Compute dst_valid_o: stage2 valid
    assign dst_valid_o = dst_valid_stage2;
    assign dst_data_o = dst_data_stage2;

    // Source domain: write to memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_wr_addr <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (src_wr_en) begin
                mem[src_wr_addr] <= src_data_i;
                src_wr_addr <= src_wr_addr + 1'b1;
                src_wr_ptr <= src_wr_ptr + 1'b1;
            end
        end
    end

    // Destination domain: read from memory and pipeline
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_addr <= {ADDR_WIDTH{1'b0}};
            dst_data_stage1 <= {WIDTH{1'b0}};
            dst_data_stage2 <= {WIDTH{1'b0}};
            dst_valid_stage1 <= 1'b0;
            dst_valid_stage2 <= 1'b0;
        end else begin
            // Stage 2 -> output
            dst_data_stage2 <= dst_data_stage1;
            dst_valid_stage2 <= dst_valid_stage1;

            // Stage 1 -> Stage 2
            if (dst_rd_en) begin
                dst_data_stage1 <= mem[dst_rd_addr];
                dst_valid_stage1 <= 1'b1;
                dst_rd_addr <= dst_rd_addr + 1'b1;
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
            end else begin
                dst_data_stage1 <= {WIDTH{1'b0}};
                dst_valid_stage1 <= 1'b0;
            end
        end
    end

    // Synchronize write pointer to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_dst_sync1 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_dst_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            src_wr_ptr_dst_sync1 <= src_wr_ptr;
            src_wr_ptr_dst_sync2 <= src_wr_ptr_dst_sync1;
        end
    end

    // Synchronize read pointer to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_src_sync1 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_src_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_rd_ptr_src_sync1 <= dst_rd_ptr;
            dst_rd_ptr_src_sync2 <= dst_rd_ptr_src_sync1;
        end
    end

endmodule
