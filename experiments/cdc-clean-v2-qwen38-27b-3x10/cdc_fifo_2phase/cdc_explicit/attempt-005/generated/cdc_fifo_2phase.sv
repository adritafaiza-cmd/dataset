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
    localparam PTR_W = LOG_DEPTH;

    // Source domain: FIFO storage and write pointer
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W:0]   wr_ptr;
    reg [PTR_W:0]   rd_ptr_src; // synchronized read pointer in src domain

    // Destination domain: read pointer and output register
    reg [PTR_W:0]   rd_ptr_dst;
    reg [WIDTH-1:0] dst_reg;
    reg             dst_valid_reg;

    // Synchronization signals
    // Write pointer synchronized to dst domain
    reg [PTR_W:0]   wr_ptr_dst_sync1;
    reg [PTR_W:0]   wr_ptr_dst_sync2;

    // Read pointer synchronized to src domain
    reg [PTR_W:0]   rd_ptr_src_sync1;
    reg [PTR_W:0]   rd_ptr_src_sync2;

    // Control signals for destination
    wire dst_can_read = (rd_ptr_dst != wr_ptr_dst_sync2);
    wire dst_pop = dst_valid_reg & dst_ready_i;

    // Source ready: FIFO not full
    wire src_full = (wr_ptr == rd_ptr_src);
    assign src_ready_o = ~src_full;

    // Source write
    wire src_push = src_valid_i & src_ready_o;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= {PTR_W+1{1'b0}};
        end else if (src_push) begin
            mem[wr_ptr[PTR_W-1:0]] <= src_data_i;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // Synchronize write pointer to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_dst_sync1 <= {PTR_W+1{1'b0}};
            wr_ptr_dst_sync2 <= {PTR_W+1{1'b0}};
        end else begin
            wr_ptr_dst_sync1 <= wr_ptr;
            wr_ptr_dst_sync2 <= wr_ptr_dst_sync1;
        end
    end

    // Synchronize read pointer to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr_src_sync1 <= {PTR_W+1{1'b0}};
            rd_ptr_src_sync2 <= {PTR_W+1{1'b0}};
        end else begin
            rd_ptr_src_sync1 <= rd_ptr_dst;
            rd_ptr_src_sync2 <= rd_ptr_src_sync1;
        end
    end

    assign rd_ptr_src = rd_ptr_src_sync2;

    // Destination domain: read and output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr_dst    <= {PTR_W+1{1'b0}};
            dst_reg       <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_pop) begin
                // Pop current, and if there's more, load next
                if (dst_can_read) begin
                    dst_reg       <= mem[rd_ptr_dst[PTR_W-1:0]];
                    dst_valid_reg <= 1'b1;
                    rd_ptr_dst    <= rd_ptr_dst + 1'b1;
                end else begin
                    dst_valid_reg <= 1'b0;
                end
            end else if (dst_can_read && !dst_valid_reg) begin
                // Load first available word
                dst_reg       <= mem[rd_ptr_dst[PTR_W-1:0]];
                dst_valid_reg <= 1'b1;
                rd_ptr_dst    <= rd_ptr_dst + 1'b1;
            end
        end
    end

    assign dst_data_o  = dst_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
