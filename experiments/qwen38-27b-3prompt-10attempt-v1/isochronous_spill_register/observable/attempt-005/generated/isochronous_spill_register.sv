module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

    // Source domain: 2-deep FIFO
    reg [WIDTH-1:0] src_fifo [0:1];
    reg [1:0]       src_wr_ptr;
    reg [1:0]       src_rd_ptr;

    // Destination domain: 2-deep FIFO
    reg [WIDTH-1:0] dst_fifo [0:1];
    reg [1:0]       dst_wr_ptr;
    reg [1:0]       dst_rd_ptr;

    // Synchronization of source write pointer to destination domain
    reg [1:0] src_wr_ptr_sync1;
    reg [1:0] src_wr_ptr_sync2;

    // Synchronization of destination read pointer to source domain
    reg [1:0] dst_rd_ptr_sync1;
    reg [1:0] dst_rd_ptr_sync2;

    // Source domain: write to src_fifo
    wire src_wr_en = src_valid_i & src_ready_o;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 2'd0;
            src_rd_ptr <= 2'd0;
        end else begin
            if (src_wr_en)
                src_wr_ptr <= src_wr_ptr + 2'd1;
            if (dst_rd_ptr_sync2 != src_rd_ptr)
                src_rd_ptr <= src_rd_ptr + 2'd1;
        end
    end

    always @(posedge src_clk_i) begin
        if (src_wr_en)
            src_fifo[src_wr_ptr[0]] <= src_data_i;
    end

    // Source domain: read from src_fifo (when dst domain is ready to accept)
    wire src_rd_en = (dst_rd_ptr_sync2 != src_rd_ptr);

    always @(posedge src_clk_i) begin
        if (src_rd_en)
            dst_fifo[src_rd_ptr[0]] <= src_fifo[src_rd_ptr[0]];
    end

    // Source ready: FIFO not full
    assign src_ready_o = (src_wr_ptr != src_rd_ptr);

    // Destination domain: write to dst_fifo
    wire dst_wr_en = (dst_rd_ptr_sync2 != src_rd_ptr);

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr <= 2'd0;
            dst_rd_ptr <= 2'd0;
        end else begin
            if (dst_wr_en)
                dst_wr_ptr <= dst_wr_ptr + 2'd1;
            if (dst_valid_o & dst_ready_i)
                dst_rd_ptr <= dst_rd_ptr + 2'd1;
        end
    end

    // Destination domain: read from dst_fifo
    wire dst_rd_en = dst_valid_o & dst_ready_i;

    always @(posedge dst_clk_i) begin
        if (dst_rd_en)
            dst_data_o <= dst_fifo[dst_rd_ptr[0]];
    end

    // Destination valid: FIFO not empty
    assign dst_valid_o = (dst_wr_ptr != dst_rd_ptr);

    // Synchronize src_wr_ptr to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_sync1 <= 2'd0;
            src_wr_ptr_sync2 <= 2'd0;
        end else begin
            src_wr_ptr_sync1 <= src_wr_ptr;
            src_wr_ptr_sync2 <= src_wr_ptr_sync1;
        end
    end

    // Synchronize dst_rd_ptr to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_sync1 <= 2'd0;
            dst_rd_ptr_sync2 <= 2'd0;
        end else begin
            dst_rd_ptr_sync1 <= dst_rd_ptr;
            dst_rd_ptr_sync2 <= dst_rd_ptr_sync1;
        end
    end

endmodule
