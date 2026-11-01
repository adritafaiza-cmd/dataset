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
    reg [PTR_WIDTH-1:0] src_rd_ptr_sync;

    // Destination domain pointers
    reg [PTR_WIDTH-1:0] dst_wr_ptr;
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [PTR_WIDTH-1:0] dst_wr_ptr_sync;

    // Synchronizer registers
    reg [PTR_WIDTH-1:0] src_wr_ptr_sync1, src_wr_ptr_sync2;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_sync1, dst_rd_ptr_sync2;

    // Derived signals
    wire src_full;
    wire dst_empty;
    wire src_ready;
    wire dst_valid;

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

    // Source domain: read pointer from destination (synchronized)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rd_ptr_sync <= {PTR_WIDTH{1'b0}};
        end else begin
            src_rd_ptr_sync <= dst_rd_ptr_sync2;
        end
    end

    // Destination domain: write pointer from source (synchronized)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr_sync <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_wr_ptr_sync <= src_wr_ptr_sync2;
        end
    end

    // Full/empty detection
    // FIFO is full when write pointer has lapped read pointer by DEPTH
    assign src_full = (src_wr_ptr[PTR_WIDTH-1] != src_rd_ptr_sync[PTR_WIDTH-1]) &&
                      (src_wr_ptr[PTR_WIDTH-2:0] == src_rd_ptr_sync[PTR_WIDTH-2:0]);

    // FIFO is empty when write pointer equals read pointer
    assign dst_empty = (dst_wr_ptr_sync == dst_rd_ptr);

    // Ready and valid
    assign src_ready = ~src_full;
    assign dst_valid = ~dst_empty;

    // Source domain: write operation
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (src_valid_i && src_ready) begin
            mem[src_wr_ptr[PTR_WIDTH-2:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    // Destination domain: read operation
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else if (dst_valid && dst_ready_i) begin
            dst_rd_ptr <= dst_rd_ptr + 1'b1;
        end
    end

    // Output
    assign dst_data_o = mem[dst_rd_ptr[PTR_WIDTH-2:0]];
    assign dst_valid_o = dst_valid;
    assign src_ready_o = src_ready;

endmodule
