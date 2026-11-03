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
    wire [LOG_DEPTH:0] gray_src_cnt;
    wire [LOG_DEPTH:0] gray_dst_cnt;
    wire [LOG_DEPTH:0] gray_src_cnt_sync;
    wire [LOG_DEPTH:0] gray_dst_cnt_sync;

    // Instantiate gray counters
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_src_counter (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .en(src_valid_i & src_ready_o),
        .gray_cnt(gray_src_cnt)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_dst_counter (
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .en(dst_ready_i & dst_valid_o),
        .gray_cnt(gray_dst_cnt)
    );

    // Instantiate sync_gray for gray counters
    sync_gray #(.LOG_DEPTH(LOG_DEPTH)) sync_src_gray (
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .async_in(gray_src_cnt),
        .sync_out(gray_src_cnt_sync)
    );

    sync_gray #(.LOG_DEPTH(LOG_DEPTH)) sync_dst_gray (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .async_in(gray_dst_cnt),
        .sync_out(gray_dst_cnt_sync)
    );

    // Instantiate dual-port RAM
    dual_port_ram #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_ram (
        .clk_a(src_clk_i),
        .rst_n_a(src_rst_ni),
        .we_a(src_valid_i & src_ready_o),
        .addr_a(gray_src_cnt),
        .din_a(src_data_i),
        .clk_b(dst_clk_i),
        .rst_n_b(dst_rst_ni),
        .we_b(1'b0),
        .addr_b(gray_dst_cnt),
        .dout_b(dst_data_o)
    );

    // Control signals
    assign src_ready_o = !(gray_src_cnt_sync == (gray_src_cnt + 1'b1));
    assign dst_valid_o = !(gray_dst_cnt_sync == gray_dst_cnt);

endmodule

// Gray code counter module
module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_n,
    input                  en,
    output [LOG_DEPTH:0] gray_cnt
);

    reg [LOG_DEPTH:0] bin_cnt;
    reg [LOG_DEPTH:0] bin_cnt_next;

    // Binary counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_cnt <= 0;
        else if (en)
            bin_cnt <= bin_cnt_next;
    end

    // Next state logic
    always @(*) begin
        bin_cnt_next = bin_cnt + 1'b1;
    end

    // Convert binary to gray code
    assign gray_cnt = (bin_cnt >> 1) ^ bin_cnt;

endmodule

// Gray code synchronizer module
module sync_gray #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_n,
    input  [LOG_DEPTH:0] async_in,
    output [LOG_DEPTH:0] sync_out
);

    reg [LOG_DEPTH:0] sync_stage1;
    reg [LOG_DEPTH:0] sync_stage2;

    // Two-stage synchronization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1 <= 0;
            sync_stage2 <= 0;
        end else begin
            sync_stage1 <= async_in;
            sync_stage2 <= sync_stage1;
        end
    end

    assign sync_out = sync_stage2;

endmodule

// Dual-port RAM module
module dual_port_ram #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_a,
    input                  rst_n_a,
    input                  we_a,
    input  [LOG_DEPTH:0] addr_a,
    input  [WIDTH-1:0]   din_a,
    input                  clk_b,
    input                  rst_n_b,
    input                  we_b,
    input  [LOG_DEPTH:0] addr_b,
    output [WIDTH-1:0]   dout_b
);

    reg [WIDTH-1:0] mem [0:(2**(LOG_DEPTH+1)-1)];

    // Write operation on port A
    always @(posedge clk_a or negedge rst_n_a) begin
        if (!rst_n_a && we_a)
            mem[addr_a] <= din_a;
    end

    // Read operation on port B
    always @(posedge clk_b or negedge rst_n_b) begin
        if (!rst_n_b)
            dout_b <= 0;
        else
            dout_b <= mem[addr_b];
    end

endmodule
