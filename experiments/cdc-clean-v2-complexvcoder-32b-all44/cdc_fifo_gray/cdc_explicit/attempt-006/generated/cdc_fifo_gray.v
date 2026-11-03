module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
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
    wire [LOG_DEPTH:0]     src_gray_code;
    wire [LOG_DEPTH:0]     dst_gray_code;
    wire [LOG_DEPTH:0]     sync_src2dst;
    wire [LOG_DEPTH:0]     sync_dst2src;

    // FIFO memory
    reg [WIDTH-1:0]        fifo_mem [0:(1<<LOG_DEPTH)-1];

    // Source Gray counter
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) src_gray_counter (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .wr_en_i(src_valid_i & src_ready_o),
        .rd_en_i(1'b0),
        .wr_ptr_i(sync_dst2src),
        .rd_ptr_i(1'b0),
        .gray_code_o(src_gray_code)
    );

    // Destination Gray counter
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) dst_gray_counter (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .wr_en_i(1'b0),
        .rd_en_i(dst_ready_i & dst_valid_o),
        .wr_ptr_i(sync_src2dst),
        .rd_ptr_i(1'b0),
        .gray_code_o(dst_gray_code)
    );

    // Source to Destination synchronization
    sync_reg #(.WIDTH(LOG_DEPTH+1), .SYNC_STAGES(SYNC_STAGES)) sync_reg_src2dst (
        .rst_ni(dst_rst_ni),
        .src_clk_i(src_clk_i),
        .dst_clk_i(dst_clk_i),
        .src_data_i(src_gray_code),
        .dst_data_o(sync_src2dst)
    );

    // Destination to Source synchronization
    sync_reg #(.WIDTH(LOG_DEPTH+1), .SYNC_STAGES(SYNC_STAGES)) sync_reg_dst2src (
        .rst_ni(src_rst_ni),
        .src_clk_i(dst_clk_i),
        .dst_clk_i(src_clk_i),
        .src_data_i(dst_gray_code),
        .dst_data_o(sync_dst2src)
    );

    // Source ready logic
    assign src_ready_o = (src_gray_code != sync_dst2src);

    // Destination valid logic
    assign dst_valid_o = (sync_src2dst != dst_gray_code);

    // FIFO write logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_mem <= '{default: 0};
        end else if (src_valid_i & src_ready_o) begin
            fifo_mem[src_gray_code[LOG_DEPTH:0]] <= src_data_i;
        end
    end

    // FIFO read logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else if (dst_valid_o & dst_ready_i) begin
            dst_data_o <= fifo_mem[dst_gray_code[LOG_DEPTH:0]];
        end
    end

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  wr_en_i,
    input                  rd_en_i,
    input  [LOG_DEPTH:0]   wr_ptr_i,
    input  [LOG_DEPTH:0]   rd_ptr_i,
    output [LOG_DEPTH:0]   gray_code_o
);

    reg [LOG_DEPTH:0]      bin_counter;
    reg [LOG_DEPTH:0]      next_bin_counter;

    // Binary counter logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_counter <= 0;
        end else if (wr_en_i & ~rd_en_i) begin
            bin_counter <= bin_counter + 1;
        end else if (~wr_en_i & rd_en_i) begin
            bin_counter <= wr_ptr_i;
        end
    end

    // Gray code conversion
    assign gray_code_o = (bin_counter >> 1) ^ bin_counter;

endmodule

module sync_reg #(
    parameter WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input                  rst_ni,
    input                  src_clk_i,
    input                  dst_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    output [WIDTH-1:0]     dst_data_o
);

    reg [WIDTH-1:0]        sync_stages [0:SYNC_STAGES-1];

    // Source synchronization
    always @(posedge src_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stages[0] <= 0;
        end else begin
            sync_stages[0] <= src_data_i;
        end
    end

    // Destination synchronization
    generate
        if (SYNC_STAGES > 1) begin
            genvar i;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin
                always @(posedge dst_clk_i or negedge rst_ni) begin
                    if (!rst_ni) begin
                        sync_stages[i] <= 0;
                    end else begin
                        sync_stages[i] <= sync_stages[i-1];
                    end
                end
            end
        end
    endgenerate

    assign dst_data_o = sync_stages[SYNC_STAGES-1];

endmodule
