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

    // Storage
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Source domain pointers
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] src_rd_ptr_sync;

    // Destination domain pointers
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_sync;

    // Synchronizers
    reg [PTR_WIDTH-1:0] src_wr_ptr_sync1, src_wr_ptr_sync2;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_sync1, dst_rd_ptr_sync2;

    // Destination output register
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Source ready
    wire src_full;
    wire src_can_write;

    // Destination read enable
    wire dst_can_read;

    // Compute full condition in source domain
    // Full when (src_wr_ptr - src_rd_ptr_sync) == DEPTH
    wire [PTR_WIDTH-1:0] src_diff = src_wr_ptr - src_rd_ptr_sync;
    assign src_full = (src_diff == DEPTH);
    assign src_ready_o = ~src_full;

    // Compute empty condition in destination domain
    // Empty when (dst_wr_ptr_sync - dst_rd_ptr) == 0
    wire [PTR_WIDTH-1:0] dst_diff = dst_wr_ptr_sync - dst_rd_ptr;
    assign dst_can_read = (dst_diff != 0);

    // Source clock domain: write to memory
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (src_valid_i && src_ready_o) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    // Synchronize src_wr_ptr to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            src_wr_ptr_sync1 <= src_wr_ptr;
            src_wr_ptr_sync2 <= src_wr_ptr_sync1;
        end
    end
    assign dst_wr_ptr_sync = src_wr_ptr_sync2;

    // Synchronize dst_rd_ptr to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_rd_ptr_sync1 <= dst_rd_ptr;
            dst_rd_ptr_sync2 <= dst_rd_ptr_sync1;
        end
    end
    assign src_rd_ptr_sync = dst_rd_ptr_sync2;

    // Destination clock domain: read from memory and update output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_can_read && dst_ready_i) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
                dst_valid_reg <= 1'b1;
            end else if (dst_valid_reg && dst_ready_i) begin
                dst_valid_reg <= 1'b0;
            end
        end
    end

    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
