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
    localparam PTR_W = LOG_DEPTH + 1;

    // Source domain registers
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] src_wr_ptr;
    reg [PTR_W-1:0] dst_rd_ptr_src;
    reg [PTR_W-1:0] dst_rd_ptr_src_d1;
    reg [PTR_W-1:0] dst_rd_ptr_src_d2;

    // Destination domain registers
    reg [WIDTH-1:0] dst_data_reg;
    reg             dst_valid_reg;
    reg [PTR_W-1:0] dst_rd_ptr;
    reg [PTR_W-1:0] src_wr_ptr_dst;
    reg [PTR_W-1:0] src_wr_ptr_dst_d1;
    reg [PTR_W-1:0] src_wr_ptr_dst_d2;

    // Synchronizer for write pointer (src -> dst)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_src_d1 <= {PTR_W{1'b0}};
            dst_rd_ptr_src_d2 <= {PTR_W{1'b0}};
        end else begin
            dst_rd_ptr_src_d1 <= dst_rd_ptr_src;
            dst_rd_ptr_src_d2 <= dst_rd_ptr_src_d1;
        end
    end

    // Synchronizer for read pointer (dst -> src)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_dst_d1 <= {PTR_W{1'b0}};
            src_wr_ptr_dst_d2 <= {PTR_W{1'b0}};
        end else begin
            src_wr_ptr_dst_d1 <= src_wr_ptr_dst;
            src_wr_ptr_dst_d2 <= src_wr_ptr_dst_d1;
        end
    end

    // Write pointer synchronization: src_wr_ptr -> dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_dst <= {PTR_W{1'b0}};
        end else begin
            src_wr_ptr_dst <= src_wr_ptr;
        end
    end

    // Read pointer synchronization: dst_rd_ptr -> src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_src <= {PTR_W{1'b0}};
        end else begin
            dst_rd_ptr_src <= dst_rd_ptr;
        end
    end

    // Full/Empty logic
    wire src_full = (src_wr_ptr == dst_rd_ptr_src_d2);
    wire dst_empty = (dst_rd_ptr == src_wr_ptr_dst_d2);

    // Source ready
    assign src_ready_o = ~src_full;

    // Write to memory in source domain
    wire src_write = src_valid_i & src_ready_o;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_W{1'b0}};
        end else if (src_write) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    // Destination domain: read from memory and output
    wire dst_read = dst_valid_reg & dst_ready_i;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
            dst_rd_ptr <= {PTR_W{1'b0}};
        end else begin
            if (dst_read) begin
                dst_valid_reg <= 1'b0;
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
            end else if (!dst_valid_reg && !dst_empty) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1'b1;
            end
        end
    end

    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
