module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input  [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;
    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Source domain
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] src_wr_ptr_full;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_src;

    // Destination domain
    reg [ADDR_WIDTH-1:0] dst_rd_ptr;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_full;
    reg [PTR_WIDTH-1:0] src_wr_ptr_dst;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // CDC synchronizers
    reg [PTR_WIDTH-1:0] src_wr_ptr_sync1, src_wr_ptr_sync2;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_sync1, dst_rd_ptr_sync2;

    // Source domain logic
    wire src_wr_en = src_valid_i & src_ready_o;
    wire src_full = (src_wr_ptr_full == dst_rd_ptr_src);
    assign src_ready_o = ~src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {ADDR_WIDTH{1'b0}};
            src_wr_ptr_full <= {PTR_WIDTH{1'b0}};
        end else begin
            if (src_wr_en) begin
                mem[src_wr_ptr] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1'b1;
                src_wr_ptr_full <= src_wr_ptr_full + 1'b1;
            end
        end
    end

    // Synchronize source write pointer to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            src_wr_ptr_sync1 <= src_wr_ptr_full;
            src_wr_ptr_sync2 <= src_wr_ptr_sync1;
        end
    end

    // Synchronize destination read pointer to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_rd_ptr_sync1 <= dst_rd_ptr_full;
            dst_rd_ptr_sync2 <= dst_rd_ptr_sync1;
        end
    end

    assign dst_rd_ptr_src = dst_rd_ptr_sync2;

    // Destination domain logic
    wire dst_rd_en = dst_valid_reg & dst_ready_i;
    wire dst_empty = (dst_rd_ptr_full == src_wr_ptr_sync2);

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {ADDR_WIDTH{1'b0}};
            dst_rd_ptr_full <= {PTR_WIDTH{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_rd_en) begin
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
                dst_rd_ptr_full <= dst_rd_ptr_full + 1'b1;
            end
            if (dst_rd_en) begin
                dst_data_reg <= mem[dst_rd_ptr + 1'b1];
                dst_valid_reg <= ~dst_empty;
            end else if (!dst_valid_reg && !dst_empty) begin
                dst_data_reg <= mem[dst_rd_ptr];
                dst_valid_reg <= 1'b1;
            end
        end
    end

    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
