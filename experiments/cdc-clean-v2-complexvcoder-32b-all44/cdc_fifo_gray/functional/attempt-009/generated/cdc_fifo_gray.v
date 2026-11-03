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

    wire [LOG_DEPTH:0] src_gray_count;
    wire [LOG_DEPTH:0] dst_gray_count;

    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) src_gray_counter (
        .clk_i    (src_clk_i),
        .rst_ni   (src_rst_ni),
        .en_i     (src_valid_i & src_ready_o),
        .gray_count(src_gray_count)
    );

    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_gray_counter (
        .clk_i    (dst_clk_i),
        .rst_ni   (dst_rst_ni),
        .en_i     (dst_ready_i & dst_valid_o),
        .gray_count(dst_gray_count)
    );

    sync_fifo #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_fifo_inst (
        .src_clk_i    (src_clk_i),
        .src_rst_ni   (src_rst_ni),
        .src_valid_i  (src_valid_i),
        .src_ready_o  (src_ready_o),
        .src_data_i   (src_data_i),
        .src_gray_count(src_gray_count),
        .dst_clk_i    (dst_clk_i),
        .dst_rst_ni   (dst_rst_ni),
        .dst_ready_i  (dst_ready_i),
        .dst_valid_o  (dst_valid_o),
        .dst_data_o   (dst_data_o),
        .dst_gray_count(dst_gray_count)
    );

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  en_i,
    output [LOG_DEPTH:0] gray_count
);

    reg [LOG_DEPTH:0] bin_count;
    reg [LOG_DEPTH:0] gray_count_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_count <= {LOG_DEPTH+1{1'b0}};
        end else if (en_i) begin
            bin_count <= bin_count + 1;
        end
    end

    assign gray_count = (bin_count >> 1) ^ bin_count;

endmodule

module sync_fifo #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_clk_i,
    input                  src_rst_ni,
    input                  src_valid_i,
    output                 src_ready_o,
    input  [WIDTH-1:0]     src_data_i,
    input  [LOG_DEPTH:0]   src_gray_count,
    input                  dst_clk_i,
    input                  dst_rst_ni,
    input                  dst_ready_i,
    output                 dst_valid_o,
    output [WIDTH-1:0]     dst_data_o,
    output [LOG_DEPTH:0]   dst_gray_count
);

    wire [LOG_DEPTH:0] sync_gray_count;

    sync_stage #(
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_stage_inst (
        .src_clk_i    (src_clk_i),
        .src_rst_ni   (src_rst_ni),
        .src_gray_count(src_gray_count),
        .dst_clk_i    (dst_clk_i),
        .dst_rst_ni   (dst_rst_ni),
        .dst_gray_count(sync_gray_count)
    );

    reg [LOG_DEPTH:0] src_ptr;
    reg [LOG_DEPTH:0] dst_ptr;
    reg [WIDTH-1:0] fifo_mem [0:(2**LOG_DEPTH)-1];
    reg src_full;
    reg dst_empty;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= {LOG_DEPTH+1{1'b0}};
            src_full <= 1'b0;
        end else if (src_valid_i & src_ready_o) begin
            fifo_mem[src_ptr[LOG_DEPTH-1:0]] <= src_data_i;
            src_ptr <= src_ptr + 1;
            src_full <= (src_ptr[LOG_DEPTH:0] == sync_gray_count);
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= {LOG_DEPTH+1{1'b0}};
            dst_empty <= 1'b1;
        end else if (dst_ready_i & dst_valid_o) begin
            dst_ptr <= dst_ptr + 1;
            dst_empty <= (dst_ptr[LOG_DEPTH:0] == sync_gray_count);
        end
    end

    assign src_ready_o = ~src_full;
    assign dst_valid_o = ~dst_empty;
    assign dst_data_o = fifo_mem[dst_ptr[LOG_DEPTH-1:0]];
    assign dst_gray_count = src_gray_count;

endmodule

module sync_stage #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_clk_i,
    input                  src_rst_ni,
    input  [LOG_DEPTH:0]   src_gray_count,
    input                  dst_clk_i,
    input                  dst_rst_ni,
    output [LOG_DEPTH:0]   dst_gray_count
);

    reg [LOG_DEPTH:0] sync_reg [0:SYNC_STAGES-1];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_reg[0] <= {LOG_DEPTH+1{1'b0}};
        end else begin
            sync_reg[0] <= src_gray_count;
        end
    end

    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : gen_sync_stages
            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    sync_reg[i] <= {LOG_DEPTH+1{1'b0}};
                end else begin
                    sync_reg[i] <= sync_reg[i-1];
                end
            end
        end
    endgenerate

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_count <= {LOG_DEPTH+1{1'b0}};
        end else begin
            dst_gray_count <= sync_reg[SYNC_STAGES-1];
        end
    end

endmodule
