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

    // Source domain: write pointer and FIFO memory
    reg [PTR_W-1:0] wr_ptr;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] rd_ptr_src; // synchronized read pointer in src domain

    // Destination domain: read pointer
    reg [PTR_W-1:0] rd_ptr;
    reg [WIDTH-1:0] dst_reg;
    reg dst_valid_reg;
    reg [PTR_W-1:0] wr_ptr_dst; // synchronized write pointer in dst domain

    // Synchronization registers for write pointer (src -> dst)
    reg [PTR_W-1:0] wr_ptr_sync1;
    reg [PTR_W-1:0] wr_ptr_sync2;

    // Synchronization registers for read pointer (dst -> src)
    reg [PTR_W-1:0] rd_ptr_sync1;
    reg [PTR_W-1:0] rd_ptr_sync2;

    // Source domain logic
    wire src_wr_en = src_valid_i & src_ready_o;
    wire src_full = (wr_ptr - rd_ptr_src) == DEPTH;
    assign src_ready_o = ~src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= {PTR_W{1'b0}};
        end else if (src_wr_en) begin
            wr_ptr <= wr_ptr + 1'b1;
            mem[wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Synchronize read pointer from dst to src
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr_sync1 <= {PTR_W{1'b0}};
            rd_ptr_sync2 <= {PTR_W{1'b0}};
        end else begin
            rd_ptr_sync1 <= rd_ptr;
            rd_ptr_sync2 <= rd_ptr_sync1;
        end
    end
    assign rd_ptr_src = rd_ptr_sync2;

    // Synchronize write pointer from src to dst
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_sync1 <= {PTR_W{1'b0}};
            wr_ptr_sync2 <= {PTR_W{1'b0}};
        end else begin
            wr_ptr_sync1 <= wr_ptr;
            wr_ptr_sync2 <= wr_ptr_sync1;
        end
    end
    assign wr_ptr_dst = wr_ptr_sync2;

    // Destination domain logic
    wire dst_empty = (rd_ptr == wr_ptr_dst);
    wire dst_rd_en = dst_valid_o & dst_ready_i;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= {PTR_W{1'b0}};
            dst_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_rd_en) begin
                // Transfer current word, advance read pointer
                rd_ptr <= rd_ptr + 1'b1;
                dst_valid_reg <= 1'b0;
            end else if (!dst_valid_reg && !dst_empty) begin
                // Load next word from FIFO
                dst_reg <= mem[rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1'b1;
            end
        end
    end

    assign dst_data_o = dst_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
