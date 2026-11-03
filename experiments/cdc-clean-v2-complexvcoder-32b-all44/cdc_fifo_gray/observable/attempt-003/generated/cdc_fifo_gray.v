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

    wire [LOG_DEPTH:0] src_gray_cnt;
    wire [LOG_DEPTH:0] dst_gray_cnt;
    wire [LOG_DEPTH:0] synced_dst_gray_cnt;
    wire [LOG_DEPTH:0] synced_src_gray_cnt;

    // Source Gray Counter
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) src_gray_counter (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .inc(src_valid_i & src_ready_o),
        .gray_cnt(src_gray_cnt)
    );

    // Destination Gray Counter
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_gray_counter (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .inc(dst_valid_o & dst_ready_i),
        .gray_cnt(dst_gray_cnt)
    );

    // Synchronize Destination Gray Counter to Source Clock Domain
    sync_register #(
        .SYNC_STAGES(SYNC_STAGES),
        .WIDTH(LOG_DEPTH+1)
    ) sync_dst_gray_cnt (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .async_in(dst_gray_cnt),
        .synced_gray_cnt(synced_dst_gray_cnt)
    );

    // Synchronize Source Gray Counter to Destination Clock Domain
    sync_register #(
        .SYNC_STAGES(SYNC_STAGES),
        .WIDTH(LOG_DEPTH+1)
    ) sync_src_gray_cnt (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .async_in(src_gray_cnt),
        .synced_gray_cnt(synced_src_gray_cnt)
    );

    // FIFO RAM
    ram #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_ram (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .wr_addr(src_gray_cnt),
        .rd_addr(synced_dst_gray_cnt),
        .wr_en(src_valid_i & src_ready_o),
        .rd_en(dst_valid_o & dst_ready_i),
        .wr_data(src_data_i),
        .data_out(dst_data_o)
    );

    // Determine src_ready_o and dst_valid_o
    assign src_ready_o = ~(synced_src_gray_cnt == src_gray_cnt);
    assign dst_valid_o = ~(synced_dst_gray_cnt == dst_gray_cnt);

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input                  inc,
    output [LOG_DEPTH:0] gray_cnt
);

    reg [LOG_DEPTH:0] bin_cnt;
    reg [LOG_DEPTH:0] gray_cnt_reg;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_cnt <= 0;
            gray_cnt_reg <= 0;
        end else begin
            if (inc) begin
                bin_cnt <= bin_cnt + 1;
            end
            gray_cnt_reg <= bin_cnt ^ (bin_cnt >> 1);
        end
    end

    assign gray_cnt = gray_cnt_reg;

endmodule

module sync_register #(
    parameter SYNC_STAGES = 2,
    parameter WIDTH = 4
)(
    input                  clk,
    input                  rst_ni,
    input  [WIDTH-1:0]     async_in,
    output [WIDTH-1:0]     synced_gray_cnt
);

    reg [WIDTH-1:0] sync_stages [0:SYNC_STAGES-1];

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_stages[i] <= 0;
            end
        end else begin
            sync_stages[0] <= async_in;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stages[i] <= sync_stages[i-1];
            end
        end
    end

    assign synced_gray_cnt = sync_stages[SYNC_STAGES-1];

endmodule

module ram #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input  [LOG_DEPTH:0] wr_addr,
    input  [LOG_DEPTH:0] rd_addr,
    input                  wr_en,
    input                  rd_en,
    input  [WIDTH-1:0]     wr_data,
    output [WIDTH-1:0]     data_out
);

    reg [WIDTH-1:0] mem [0:(1<<LOG_DEPTH)-1];

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < (1<<LOG_DEPTH); i = i + 1) begin
                mem[i] <= 0;
            end
        end else if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    assign data_out = rd_en ? mem[rd_addr] : 0;

endmodule
