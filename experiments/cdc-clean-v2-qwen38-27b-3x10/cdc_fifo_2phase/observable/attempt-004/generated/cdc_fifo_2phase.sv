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
    reg [PTR_WIDTH-1:0] dst_rd_ptr_src; // synchronized read pointer in src domain

    // Destination domain
    reg [WIDTH-1:0] dst_reg;
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [PTR_WIDTH-1:0] src_wr_ptr_dst; // synchronized write pointer in dst domain

    // Synchronization registers
    reg [PTR_WIDTH-1:0] src_wr_ptr_sync1, src_wr_ptr_sync2;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_sync1, dst_rd_ptr_sync2;

    // Compute full/empty
    wire [PTR_WIDTH-1:0] src_wr_ptr_next = src_wr_ptr + 1'b1;
    wire [PTR_WIDTH-1:0] dst_rd_ptr_next = dst_rd_ptr + 1'b1;

    // In source domain: full when write pointer catches up to read pointer
    wire src_full = (src_wr_ptr == dst_rd_ptr_src);
    wire src_ready = ~src_full;

    // In destination domain: empty when read pointer catches up to write pointer
    wire dst_empty = (dst_rd_ptr == src_wr_ptr_dst);

    // Source clock domain: write to memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else begin
            if (src_valid_i && src_ready) begin
                mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr_next;
            end
        end
    end

    // Synchronize src_wr_ptr to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            src_wr_ptr_sync1 <= src_wr_ptr;
            src_wr_ptr_sync2 <= src_wr_ptr_sync1;
        end
    end
    assign src_wr_ptr_dst = src_wr_ptr_sync2;

    // Synchronize dst_rd_ptr to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_rd_ptr_sync1 <= dst_rd_ptr;
            dst_rd_ptr_sync2 <= dst_rd_ptr_sync1;
        end
    end
    assign dst_rd_ptr_src = dst_rd_ptr_sync2;

    // Destination clock domain: read from memory and output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_reg <= {WIDTH{1'b0}};
            dst_valid_o <= 1'b0;
        end else begin
            if (!dst_empty) begin
                dst_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_rd_ptr <= dst_rd_ptr_next;
                dst_valid_o <= 1'b1;
            end else begin
                dst_valid_o <= 1'b0;
            end
        end
    end

    // Output
    assign dst_data_o = dst_reg;
    assign src_ready_o = src_ready;

endmodule
