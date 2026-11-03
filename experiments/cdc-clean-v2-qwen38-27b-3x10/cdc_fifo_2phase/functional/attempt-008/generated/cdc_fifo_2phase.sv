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

    // Source domain: write pointer and FIFO storage
    reg [PTR_W-1:0] wr_ptr;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] rd_ptr_src; // read pointer synchronized to source domain

    // Destination domain: read pointer and output register
    reg [PTR_W-1:0] rd_ptr;
    reg [WIDTH-1:0] dst_reg;
    reg             dst_valid_reg;

    // Synchronization signals
    reg [PTR_W-1:0] wr_ptr_dst_sync1, wr_ptr_dst_sync2;
    reg [PTR_W-1:0] rd_ptr_src_sync1, rd_ptr_src_sync2;

    // Source domain logic
    wire src_wr_en = src_valid_i & src_ready_o;
    wire src_full;
    wire src_empty;

    // Destination domain logic
    wire dst_rd_en = dst_valid_o & dst_ready_i;
    wire dst_empty;

    // Full condition: write pointer has lapped read pointer by DEPTH
    // In Gray code, full when wr_ptr differs from rd_ptr in the top two bits
    // But we use binary pointers with synchronization, so:
    // Full when (wr_ptr - rd_ptr) == DEPTH
    // Since pointers are PTR_W bits (LOG_DEPTH+1), we can check:
    // wr_ptr[LOG_DEPTH] != rd_ptr[LOG_DEPTH] && wr_ptr[LOG_DEPTH-1:0] == rd_ptr[LOG_DEPTH-1:0]
    // Actually, let's use a simpler approach:
    // Full when the upper bit differs and the lower bits are equal
    // This works because the pointers wrap around DEPTH entries.

    assign src_full = (wr_ptr[PTR_W-1] != rd_ptr_src[PTR_W-1]) && 
                      (wr_ptr[PTR_W-2:0] == rd_ptr_src[PTR_W-2:0]);

    assign src_ready_o = ~src_full;

    // Empty condition in destination domain
    assign dst_empty = (rd_ptr == wr_ptr_dst_sync2);

    assign dst_valid_o = ~dst_empty;
    assign dst_data_o  = dst_reg;

    // Source domain: write to memory and increment write pointer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= {PTR_W{1'b0}};
        end else begin
            if (src_wr_en) begin
                mem[wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                wr_ptr <= wr_ptr + 1'b1;
            end
        end
    end

    // Synchronize write pointer to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_dst_sync1 <= {PTR_W{1'b0}};
            wr_ptr_dst_sync2 <= {PTR_W{1'b0}};
        end else begin
            wr_ptr_dst_sync1 <= wr_ptr;
            wr_ptr_dst_sync2 <= wr_ptr_dst_sync1;
        end
    end

    // Synchronize read pointer to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr_src_sync1 <= {PTR_W{1'b0}};
            rd_ptr_src_sync2 <= {PTR_W{1'b0}};
        end else begin
            rd_ptr_src_sync1 <= rd_ptr;
            rd_ptr_src_sync2 <= rd_ptr_src_sync1;
        end
    end

    assign rd_ptr_src = rd_ptr_src_sync2;

    // Destination domain: read from memory and increment read pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr        <= {PTR_W{1'b0}};
            dst_reg       <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_rd_en) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
            if (~dst_empty) begin
                dst_reg <= mem[rd_ptr[LOG_DEPTH-1:0]];
            end
        end
    end

endmodule
