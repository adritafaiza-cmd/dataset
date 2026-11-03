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
    wire [LOG_DEPTH:0] src_gray_count;
    wire [LOG_DEPTH:0] dst_gray_count;
    wire [LOG_DEPTH:0] sync_src_gray_count;
    wire [LOG_DEPTH:0] sync_dst_gray_count;
    wire [WIDTH-1:0] fifo_data_out;

    // Gray counter for source domain
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_src (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .enable(src_valid_i & src_ready_o),
        .gray_count(src_gray_count)
    );

    // Gray counter for destination domain
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_dst (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .enable(dst_ready_i & dst_valid_o),
        .gray_count(dst_gray_count)
    );

    // Synchronize source gray count to destination domain
    sync_register #(.LOG_DEPTH(LOG_DEPTH)) sync_src_gray_count_reg (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_in(src_gray_count),
        .data_out(sync_src_gray_count)
    );

    // Synchronize destination gray count to source domain
    sync_register #(.LOG_DEPTH(LOG_DEPTH)) sync_dst_gray_count_reg (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_in(dst_gray_count),
        .data_out(sync_dst_gray_count)
    );

    // Dual-port FIFO memory
    fifo_memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_memory_inst (
        .src_clk(src_clk_i),
        .src_rst_ni(src_rst_ni),
        .src_wr_en(src_valid_i & src_ready_o),
        .src_wr_addr(src_gray_count),
        .src_din(src_data_i),
        .dst_clk(dst_clk_i),
        .dst_rst_ni(dst_rst_ni),
        .dst_rd_en(dst_ready_i & dst_valid_o),
        .dst_rd_addr(dst_gray_count),
        .dst_dout(fifo_data_out)
    );

    // Calculate full and empty conditions
    wire [LOG_DEPTH:0] src_gray_plus_one;
    wire [LOG_DEPTH:0] dst_gray_plus_one;
    wire full;
    wire empty;

    assign src_gray_plus_one = src_gray_count + 1;
    assign dst_gray_plus_one = dst_gray_count + 1;

    assign full = (sync_src_gray_count == sync_dst_gray_count_gray2bin(dst_gray_plus_one));
    assign empty = (sync_src_gray_count == sync_dst_gray_count);

    // Output assignments
    assign src_ready_o = ~full;
    assign dst_data_o = fifo_data_out;
    assign dst_valid_o = ~empty;

    // Gray to binary conversion
    function [LOG_DEPTH:0] gray2bin;
        input [LOG_DEPTH:0] gray;
        integer i;
        begin
            gray2bin = gray[LOG_DEPTH];
            for (i = LOG_DEPTH - 1; i >= 0; i = i - 1) begin
                gray2bin[i] = gray2bin[i + 1] ^ gray[i];
            end
        end
    endfunction

endmodule

// Gray counter with enable
module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input                  enable,
    output [LOG_DEPTH:0] gray_count
);

    reg [LOG_DEPTH:0] bin_count;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_count <= 0;
        end else if (enable) begin
            bin_count <= bin_count + 1;
        end
    end

    assign gray_count = (bin_count >> 1) ^ bin_count;

endmodule

// Two-stage synchronizer register
module sync_register #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input  [LOG_DEPTH:0] data_in,
    output [LOG_DEPTH:0] data_out
);

    reg [LOG_DEPTH:0] sync_stage1;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stage1 <= 0;
            data_out <= 0;
        end else begin
            sync_stage1 <= data_in;
            data_out <= sync_stage1;
        end
    end

endmodule

// Dual-port FIFO memory
module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_clk,
    input                  src_rst_ni,
    input                  src_wr_en,
    input  [LOG_DEPTH:0] src_wr_addr,
    input  [WIDTH-1:0]   src_din,
    input                  dst_clk,
    input                  dst_rst_ni,
    input                  dst_rd_en,
    input  [LOG_DEPTH:0] dst_rd_addr,
    output [WIDTH-1:0]   dst_dout
);

    reg [WIDTH-1:0] mem [0:(2**LOG_DEPTH)-1];
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    always @(posedge src_clk or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            mem <= '{default: 0};
        end else if (src_wr_en) begin
            mem[src_wr_addr] <= src_din;
        end
    end

    always @(posedge dst_clk or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
        end else begin
            if (dst_rd_en) begin
                dst_data_reg <= mem[dst_rd_addr];
                dst_valid_reg <= 1;
            end else if (dst_valid_reg) begin
                dst_valid_reg <= 0;
            end
        end
    end

    assign dst_dout = dst_data_reg;

endmodule
