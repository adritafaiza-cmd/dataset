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

    wire [LOG_DEPTH:0] gray_src_cnt;
    wire [LOG_DEPTH:0] gray_dst_cnt;
    wire [LOG_DEPTH:0] wr_addr;
    wire [LOG_DEPTH:0] rd_addr;
    wire               full_flag;
    wire               empty_flag;

    // Gray-coded counters for source and destination domains
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_src_counter (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .wr_en_i(src_valid_i),
        .rd_en_i(1'b0),
        .gray_cnt_o(gray_src_cnt),
        .wr_gray_cnt_i(1'b0),
        .rd_gray_cnt_i(gray_dst_cnt)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_dst_counter (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .wr_en_i(1'b0),
        .rd_en_i(dst_ready_i),
        .gray_cnt_o(gray_dst_cnt),
        .wr_gray_cnt_i(gray_src_cnt),
        .rd_gray_cnt_i(1'b0)
    );

    // FIFO buffer for data storage
    async_fifo_buffer #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_buffer (
        .wr_clk_i(src_clk_i),
        .wr_addr_i(gray_src_cnt),
        .wr_data_i(src_data_i),
        .wr_en_i(src_valid_i),
        .full_o(full_flag),
        .rd_clk_i(dst_clk_i),
        .rd_addr_i(gray_dst_cnt),
        .rd_data_o(dst_data_o),
        .empty_o(empty_flag)
    );

    // Synchronization chains for safe crossing of Gray-coded pointers
    sync_chain #(.WIDTH(LOG_DEPTH+1), .SYNC_STAGES(SYNC_STAGES)) sync_chain_src2dst (
        .clk_i(src_clk_i),
        .clk_o(dst_clk_i),
        .data_i(gray_src_cnt),
        .data_o(gray_src_cnt_synced)
    );

    sync_chain #(.WIDTH(LOG_DEPTH+1), .SYNC_STAGES(SYNC_STAGES)) sync_chain_dst2src (
        .clk_i(dst_clk_i),
        .clk_o(src_clk_i),
        .data_i(gray_dst_cnt),
        .data_o(gray_dst_cnt_synced)
    );

    // Assign synchronized Gray-coded counters
    wire [LOG_DEPTH:0] gray_src_cnt_synced;
    wire [LOG_DEPTH:0] gray_dst_cnt_synced;

    // Assign outputs
    assign src_ready_o = ~full_flag;
    assign dst_valid_o = ~empty_flag;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  wr_en_i,
    input                  rd_en_i,
    output [LOG_DEPTH:0] gray_cnt_o,
    input  [LOG_DEPTH:0] wr_gray_cnt_i,
    input  [LOG_DEPTH:0] rd_gray_cnt_i
);

    reg [LOG_DEPTH:0] bin_cnt;
    reg [LOG_DEPTH:0] gray_cnt;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_cnt <= 0;
            gray_cnt <= 0;
        end else begin
            if (wr_en_i && !rd_en_i)
                bin_cnt <= bin_cnt + 1;
            else if (!wr_en_i && rd_en_i)
                bin_cnt <= bin_cnt - 1;
        end
    end

    assign gray_cnt = (bin_cnt >> 1) ^ bin_cnt;
    assign gray_cnt_o = gray_cnt;

endmodule

module async_fifo_buffer #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  wr_clk_i,
    input  [LOG_DEPTH:0] wr_addr_i,
    input  [WIDTH-1:0]     wr_data_i,
    input                  wr_en_i,
    output                 full_o,
    input                  rd_clk_i,
    input  [LOG_DEPTH:0] rd_addr_i,
    output [WIDTH-1:0]     rd_data_o,
    output                 empty_o
);

    reg [WIDTH-1:0] mem [0:(2**(LOG_DEPTH+1)-1)];
    reg [LOG_DEPTH:0] wr_ptr;
    reg [LOG_DEPTH:0] rd_ptr;
    reg [LOG_DEPTH:0] wr_ptr_gray;
    reg [LOG_DEPTH:0] rd_ptr_gray;

    always @(posedge wr_clk_i) begin
        if (wr_en_i && !full_o)
            mem[wr_addr_i] <= wr_data_i;
    end

    always @(posedge wr_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en_i && !full_o) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    always @(posedge rd_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_ready_i && !empty_o) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    assign rd_data_o = mem[rd_addr_i];

    assign wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;
    assign rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;

    sync_chain #(.WIDTH(LOG_DEPTH+1), .SYNC_STAGES(2)) sync_chain_wr2rd (
        .clk_i(wr_clk_i),
        .clk_o(rd_clk_i),
        .data_i(wr_ptr_gray),
        .data_o(wr_ptr_gray_synced)
    );

    sync_chain #(.WIDTH(LOG_DEPTH+1), .SYNC_STAGES(2)) sync_chain_rd2wr (
        .clk_i(rd_clk_i),
        .clk_o(wr_clk_i),
        .data_i(rd_ptr_gray),
        .data_o(rd_ptr_gray_synced)
    );

    wire [LOG_DEPTH:0] wr_ptr_gray_synced;
    wire [LOG_DEPTH:0] rd_ptr_gray_synced;

    assign full_o = (wr_ptr_gray_synced == {~rd_ptr_gray[LOG_DEPTH], rd_ptr_gray[LOG_DEPTH-1:0]});
    assign empty_o = (wr_ptr_gray == rd_ptr_gray_synced);

endmodule

module sync_chain #(
    parameter WIDTH = 1,
    parameter SYNC_STAGES = 2
)(
    input                  clk_i,
    input                  clk_o,
    input  [WIDTH-1:0]     data_i,
    output [WIDTH-1:0]     data_o
);

    reg [WIDTH-1:0] sync_stages [0:SYNC_STAGES-1];

    always @(posedge clk_i) begin
        sync_stages[0] <= data_i;
        for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
            sync_stages[i] <= sync_stages[i-1];
        end
    end

    always @(posedge clk_o) begin
        data_o <= sync_stages[SYNC_STAGES-1];
    end

endmodule
