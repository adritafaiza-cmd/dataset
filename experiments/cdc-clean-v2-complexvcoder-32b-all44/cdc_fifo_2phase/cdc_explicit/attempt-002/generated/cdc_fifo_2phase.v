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

    // Internal signals
    reg [LOG_DEPTH:0] src_wr_ptr;
    reg [LOG_DEPTH:0] src_wr_ptr_gray;
    reg [LOG_DEPTH:0] dst_rd_ptr;
    reg [LOG_DEPTH:0] dst_rd_ptr_gray;
    reg [LOG_DEPTH:0] dst_rd_ptr_gray_sync1;
    reg [LOG_DEPTH:0] dst_rd_ptr_gray_sync2;
    reg [WIDTH-1:0] fifo_mem [0:(1<<LOG_DEPTH)-1];
    reg src_full;
    reg dst_empty;
    reg src_wr_en;
    reg dst_rd_en;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_wr_ptr_gray <= 0;
            src_full <= 0;
        end else begin
            src_wr_en <= src_valid_i & ~src_full;
            if (src_wr_en) begin
                fifo_mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1;
                src_wr_ptr_gray <= src_wr_ptr ^ (src_wr_ptr >> 1);
            end
            src_full <= (src_wr_ptr_gray == {src_wr_ptr[LOG_DEPTH], ~dst_rd_ptr_gray_sync2[LOG_DEPTH-1:0]});
        end
    end

    // Gray code to binary conversion for write pointer
    wire [LOG_DEPTH:0] src_wr_ptr_bin;
    gray_to_bin #(.LOG_DEPTH(LOG_DEPTH)) u_gray_to_bin_src (
        .gray_in(src_wr_ptr_gray),
        .bin_out(src_wr_ptr_bin)
    );

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_rd_ptr_gray <= 0;
            dst_empty <= 1;
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
        end else begin
            dst_rd_en <= dst_valid_reg & dst_ready_i;
            if (dst_rd_en) begin
                dst_rd_ptr <= dst_rd_ptr + 1;
                dst_rd_ptr_gray <= dst_rd_ptr ^ (dst_rd_ptr >> 1);
            end
            dst_empty <= (dst_rd_ptr_gray == src_wr_ptr_gray_sync2);
            if (dst_valid_reg & dst_ready_i) begin
                dst_valid_reg <= 0;
            end else if (~dst_empty & ~dst_valid_reg) begin
                dst_data_reg <= fifo_mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1;
            end
        end
    end

    // Synchronize read pointer to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_sync1 <= 0;
            dst_rd_ptr_gray_sync2 <= 0;
        end else begin
            dst_rd_ptr_gray_sync1 <= dst_rd_ptr_gray;
            dst_rd_ptr_gray_sync2 <= dst_rd_ptr_gray_sync1;
        end
    end

    // Gray code to binary conversion for read pointer
    wire [LOG_DEPTH:0] dst_rd_ptr_bin;
    gray_to_bin #(.LOG_DEPTH(LOG_DEPTH)) u_gray_to_bin_dst (
        .gray_in(dst_rd_ptr_gray_sync2),
        .bin_out(dst_rd_ptr_bin)
    );

    // Ready signals
    assign src_ready_o = ~src_full;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule

module gray_to_bin #(
    parameter LOG_DEPTH = 3
)(
    input  [LOG_DEPTH:0] gray_in,
    output [LOG_DEPTH:0] bin_out
);

    always @(*) begin
        bin_out[LOG_DEPTH] = gray_in[LOG_DEPTH];
        for (integer i = LOG_DEPTH-1; i >= 0; i = i - 1) begin
            bin_out[i] = bin_out[i+1] ^ gray_in[i];
        end
    end

endmodule
