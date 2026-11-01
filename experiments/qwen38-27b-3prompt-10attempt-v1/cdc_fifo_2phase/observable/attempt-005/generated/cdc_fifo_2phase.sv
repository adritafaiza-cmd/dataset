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
    reg [PTR_WIDTH-1:0] src_rd_ptr;

    // Destination domain pointers
    reg [PTR_WIDTH-1:0] dst_wr_ptr;
    reg [PTR_WIDTH-1:0] dst_rd_ptr;

    // Synchronizers for write pointer (src -> dst)
    reg [PTR_WIDTH-1:0] src_wr_ptr_sync1;
    reg [PTR_WIDTH-1:0] src_wr_ptr_sync2;

    // Synchronizers for read pointer (dst -> src)
    reg [PTR_WIDTH-1:0] dst_rd_ptr_sync1;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_sync2;

    // Synchronizers for write pointer (dst -> src) - for dst_wr_ptr
    reg [PTR_WIDTH-1:0] dst_wr_ptr_sync1;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_sync2;

    // Synchronizers for read pointer (src -> dst) - for src_rd_ptr
    reg [PTR_WIDTH-1:0] src_rd_ptr_sync1;
    reg [PTR_WIDTH-1:0] src_rd_ptr_sync2;

    // Source domain: write pointer synchronization to destination
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            src_wr_ptr_sync1 <= src_wr_ptr;
            src_wr_ptr_sync2 <= src_wr_ptr_sync1;
        end
    end

    // Destination domain: read pointer synchronization to source
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_rd_ptr_sync1 <= dst_rd_ptr;
            dst_rd_ptr_sync2 <= dst_rd_ptr_sync1;
        end
    end

    // Destination domain: write pointer synchronization to source
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            dst_wr_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_wr_ptr_sync1 <= dst_wr_ptr;
            dst_wr_ptr_sync2 <= dst_wr_ptr_sync1;
        end
    end

    // Source domain: read pointer synchronization to destination
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_sync1 <= {PTR_WIDTH{1'b0}};
            src_rd_ptr_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            src_rd_ptr_sync1 <= src_rd_ptr;
            src_rd_ptr_sync2 <= src_rd_ptr_sync1;
        end
    end

    // Source domain: compute full condition
    // Full when src_wr_ptr == dst_rd_ptr_sync2 (with MSB different)
    wire src_full = (src_wr_ptr[PTR_WIDTH-1] != dst_rd_ptr_sync2[PTR_WIDTH-1]) &&
                    (src_wr_ptr[PTR_WIDTH-2:0] == dst_rd_ptr_sync2[PTR_WIDTH-2:0]);

    // Destination domain: compute empty condition
    // Empty when dst_wr_ptr == src_rd_ptr_sync2
    wire dst_empty = (dst_wr_ptr == src_rd_ptr_sync2);

    // Source ready
    assign src_ready_o = ~src_full;

    // Source write
    wire src_write = src_valid_i & src_ready_o;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
            src_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else begin
            if (src_write) begin
                mem[src_wr_ptr[PTR_WIDTH-2:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1'b1;
            end
            if (dst_ready_i & ~dst_empty) begin
                src_rd_ptr <= src_rd_ptr + 1'b1;
            end
        end
    end

    // Destination read
    wire dst_read = dst_ready_i & ~dst_empty;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else begin
            if (dst_read) begin
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
            end
        end
    end

    // Destination output
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_read) begin
                dst_data_reg <= mem[dst_rd_ptr[PTR_WIDTH-2:0]];
                dst_valid_reg <= 1'b1;
            end else begin
                dst_valid_reg <= 1'b0;
            end
        end
    end

    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
