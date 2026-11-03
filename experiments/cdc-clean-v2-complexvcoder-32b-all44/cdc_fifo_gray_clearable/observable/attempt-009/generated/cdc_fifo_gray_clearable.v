module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    wire [LOG_DEPTH:0] wr_ptr_gray;
    wire [LOG_DEPTH:0] rd_ptr_gray;

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_src (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .clear_i(src_clear_i),
        .gray_count(wr_ptr_gray)
    );

    sync_gray #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES)) sync_gray_src_to_dst (
        .rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_gray_i(wr_ptr_gray),
        .dst_clk_i(dst_clk_i),
        .dst_gray_o(wr_ptr_gray)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_dst (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .clear_i(dst_clear_i),
        .gray_count(rd_ptr_gray)
    );

    sync_gray #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES)) sync_gray_dst_to_src (
        .rst_ni(dst_rst_ni),
        .src_clk_i(dst_clk_i),
        .src_gray_i(rd_ptr_gray),
        .dst_clk_i(src_clk_i),
        .dst_gray_o(rd_ptr_gray)
    );

    fifo_memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_memory_inst (
        .rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .dst_clk_i(dst_clk_i),
        .wr_ptr_gray(wr_ptr_gray),
        .rd_ptr_gray(rd_ptr_gray),
        .wr_data(src_data_i),
        .wr_en(src_valid_i),
        .rd_en(dst_ready_i),
        .src_clear_i(src_clear_i),
        .dst_clear_i(dst_clear_i),
        .src_clear_pending(src_clear_pending_o),
        .dst_clear_pending(dst_clear_pending_o),
        .rd_data(dst_data_o),
        .valid(dst_valid_o),
        .full(src_ready_o)
    );

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  clear_i,
    output [LOG_DEPTH:0] gray_count
);

    reg [LOG_DEPTH:0] bin_count;
    reg [LOG_DEPTH:0] gray_count_next;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_count <= 0;
        end else if (clear_i) begin
            bin_count <= 0;
        end else begin
            bin_count <= bin_count + 1;
        end
    end

    assign gray_count_next = (bin_count >> 1) ^ bin_count;
    assign gray_count = gray_count_next;

endmodule

module sync_gray #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  rst_ni,
    input                  src_clk_i,
    input  [LOG_DEPTH:0] src_gray_i,
    input                  dst_clk_i,
    output [LOG_DEPTH:0] dst_gray_o
);

    reg [LOG_DEPTH:0] sync_stages [SYNC_STAGES-1:0];

    always @(posedge src_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stages[0] <= 0;
        end else begin
            sync_stages[0] <= src_gray_i;
        end
    end

    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : gen_sync_stages
            always @(posedge src_clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    sync_stages[i] <= 0;
                end else begin
                    sync_stages[i] <= sync_stages[i-1];
                end
            end
        end
    endgenerate

    always @(posedge dst_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            dst_gray_o <= 0;
        end else begin
            dst_gray_o <= sync_stages[SYNC_STAGES-1];
        end
    end

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  src_clk_i,
    input                  dst_clk_i,
    input  [LOG_DEPTH:0] wr_ptr_gray,
    input  [LOG_DEPTH:0] rd_ptr_gray,
    input  [WIDTH-1:0]     wr_data,
    input                  wr_en,
    input                  rd_en,
    input                  src_clear_i,
    input                  dst_clear_i,
    output                 src_clear_pending,
    output                 dst_clear_pending,
    output [WIDTH-1:0]     rd_data,
    output                 valid,
    output                 full
);

    reg [WIDTH-1:0] mem [0:(1<<LOG_DEPTH)-1];
    reg [LOG_DEPTH:0] wr_ptr_bin;
    reg [LOG_DEPTH:0] rd_ptr_bin;
    reg [LOG_DEPTH:0] wr_ptr_bin_next;
    reg [LOG_DEPTH:0] rd_ptr_bin_next;
    reg                 full_flag;
    reg                 empty_flag;
    reg                 src_clear_flag;
    reg                 dst_clear_flag;

    wire [LOG_DEPTH:0] wr_ptr_bin_gray;
    wire [LOG_DEPTH:0] rd_ptr_bin_gray;

    function [LOG_DEPTH:0] gray_to_bin;
        input [LOG_DEPTH:0] gray;
        reg [LOG_DEPTH:0] bin;
        integer i;
        begin
            bin = gray[LOG_DEPTH];
            for (i = LOG_DEPTH-1; i >= 0; i = i - 1) begin
                bin[i] = bin[i+1] ^ gray[i];
            end
            gray_to_bin = bin;
        end
    endfunction

    assign wr_ptr_bin_gray = wr_ptr_gray;
    assign rd_ptr_bin_gray = rd_ptr_gray;

    always @(posedge src_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr_bin <= 0;
            full_flag <= 0;
            src_clear_flag <= 0;
        end else begin
            wr_ptr_bin <= wr_ptr_bin_next;
            if (wr_en && !full_flag) begin
                mem[wr_ptr_bin_next] <= wr_data;
            end
            if (src_clear_i) begin
                src_clear_flag <= 1;
            end else if (src_clear_flag && (wr_ptr_bin_next == rd_ptr_bin_gray)) begin
                src_clear_flag <= 0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rd_ptr_bin <= 0;
            empty_flag <= 1;
            dst_clear_flag <= 0;
        end else begin
            rd_ptr_bin <= rd_ptr_bin_next;
            if (dst_clear_i) begin
                dst_clear_flag <= 1;
            end else if (dst_clear_flag && (rd_ptr_bin_next == wr_ptr_bin_gray)) begin
                dst_clear_flag <= 0;
            end
        end
    end

    always @(*) begin
        wr_ptr_bin_next = gray_to_bin(wr_ptr_gray);
        rd_ptr_bin_next = gray_to_bin(rd_ptr_gray);
        full_flag = (wr_ptr_bin_next == {rd_ptr_bin_gray[LOG_DEPTH-1:0], ~rd_ptr_gray[LOG_DEPTH]});
        empty_flag = (wr_ptr_bin == rd_ptr_bin);
    end

    always @(posedge dst_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rd_data <= 0;
            valid <= 0;
        end else if (rd_en && !empty_flag) begin
            rd_data <= mem[rd_ptr_bin];
            valid <= 1;
        end else begin
            valid <= 0;
        end
    end

    assign full = full_flag;
    assign src_clear_pending = src_clear_flag;
    assign dst_clear_pending = dst_clear_flag;

endmodule
