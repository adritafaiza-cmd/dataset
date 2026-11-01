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
    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Source domain
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_src;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_src_d1;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_src_d2;

    // Destination domain
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_dst;
    reg [PTR_WIDTH-1:0] src_wr_ptr_dst;
    reg [PTR_WIDTH-1:0] src_wr_ptr_dst_d1;
    reg [PTR_WIDTH-1:0] src_wr_ptr_dst_d2;

    // Source domain signals
    wire src_wr_en = src_valid_i & src_ready_o;
    wire src_full = (src_wr_ptr[PTR_WIDTH-1] != dst_rd_ptr_src[PTR_WIDTH-1]) &&
                    (src_wr_ptr[LOG_DEPTH-1:0] == dst_rd_ptr_src[LOG_DEPTH-1:0]);
    assign src_ready_o = ~src_full;

    // Destination domain signals
    wire dst_rd_en = dst_valid_reg & dst_ready_i;
    wire dst_full = (dst_wr_ptr_dst[PTR_WIDTH-1] != src_wr_ptr_dst[PTR_WIDTH-1]) &&
                    (dst_wr_ptr_dst[LOG_DEPTH-1:0] == src_wr_ptr_dst[LOG_DEPTH-1:0]);
    assign dst_valid_o = dst_valid_reg;
    assign dst_data_o = dst_data_reg;

    // Source domain: write to memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_src <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_src_d1 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_src_d2 <= {PTR_WIDTH{1'b0}};
        end else begin
            if (src_wr_en) begin
                mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1'b1;
            end
            dst_rd_ptr_src <= dst_rd_ptr_src_d2;
            dst_rd_ptr_src_d1 <= dst_rd_ptr_src_d2;
            dst_rd_ptr_src_d2 <= dst_rd_ptr_src;
        end
    end

    // Destination domain: read from memory
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_dst <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_dst <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_dst_d1 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_dst_d2 <= {PTR_WIDTH{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            src_wr_ptr_dst <= src_wr_ptr_dst_d2;
            src_wr_ptr_dst_d1 <= src_wr_ptr_dst_d2;
            src_wr_ptr_dst_d2 <= src_wr_ptr_dst;

            if (dst_rd_en) begin
                dst_data_reg <= mem[dst_wr_ptr_dst[LOG_DEPTH-1:0]];
                dst_wr_ptr_dst <= dst_wr_ptr_dst + 1'b1;
                dst_valid_reg <= 1'b1;
            end else if (dst_valid_reg) begin
                dst_valid_reg <= 1'b0;
            end
        end
    end

endmodule
