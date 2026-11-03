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
    logic [WIDTH-1:0] src_data_sync [SYNC_STAGES];
    logic [WIDTH-1:0] dst_data_sync [SYNC_STAGES];
    logic src_valid_sync [SYNC_STAGES];
    logic dst_ready_sync [SYNC_STAGES];
    logic [LOG_DEPTH-1:0] src_count_gray;
    logic [LOG_DEPTH-1:0] dst_count_gray;
    logic [LOG_DEPTH-1:0] src_count_gray_sync [SYNC_STAGES];
    logic [LOG_DEPTH-1:0] dst_count_gray_sync [SYNC_STAGES];
    logic src_ready_gray;
    logic dst_valid_gray;
    logic [LOG_DEPTH-1:0] src_count_gray_reg;
    logic [LOG_DEPTH-1:0] dst_count_gray_reg;
    logic src_full_gray;
    logic dst_empty_gray;
    logic [LOG_DEPTH-1:0] src_count_gray_reg_sync [SYNC_STAGES];
    logic [LOG_DEPTH-1:0] dst_count_gray_reg_sync [SYNC_STAGES];

    // Synchronizer for source signals
    assign src_data_sync[0] = src_data_i;
    assign src_valid_sync[0] = src_valid_i;

    generate
        generate
            integer i;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_src
                sync_crossing #(
                    .WIDTH(WIDTH),
                    .SYNC_STAGES(1)
                ) sync_src_inst (
                    .clk_i(src_clk_i),
                    .rst_ni(src_rst_ni),
                    .data_i(src_data_sync[i-1]),
                    .valid_i(src_valid_sync[i-1]),
                    .data_o(src_data_sync[i]),
                    .valid_o(src_valid_sync[i])
                );
            end
        endgenerate
    endgenerate

    // Synchronizer for destination signals
    assign dst_ready_sync[0] = dst_ready_i;

    generate
        generate
            integer i;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_dst
                sync_crossing #(
                    .WIDTH(1),
                    .SYNC_STAGES(1)
                ) sync_dst_inst (
                    .clk_i(dst_clk_i),
                    .rst_ni(dst_rst_ni),
                    .data_i(dst_ready_sync[i-1]),
                    .valid_i(1'b1),
                    .data_o(dst_ready_sync[i]),
                    .valid_o(1'b1)
                );
            end
        endgenerate
    endgenerate

    // Synchronizer for source count
    assign src_count_gray_sync[0] = src_count_gray;

    generate
        generate
            integer i;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_src_count
                sync_crossing #(
                    .WIDTH(LOG_DEPTH),
                    .SYNC_STAGES(1)
                ) sync_src_count_inst (
                    .clk_i(src_clk_i),
                    .rst_ni(src_rst_ni),
                    .data_i(src_count_gray_sync[i-1]),
                    .valid_i(1'b1),
                    .data_o(src_count_gray_sync[i]),
                    .valid_o(1'b1)
                );
            end
        endgenerate
    endgenerate

    // Synchronizer for destination count
    assign dst_count_gray_sync[0] = dst_count_gray;

    generate
        generate
            integer i;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_dst_count
                sync_crossing #(
                    .WIDTH(LOG_DEPTH),
                    .SYNC_STAGES(1)
                ) sync_dst_count_inst (
                    .clk_i(dst_clk_i),
                    .rst_ni(dst_rst_ni),
                    .data_i(dst_count_gray_sync[i-1]),
                    .valid_i(1'b1),
                    .data_o(dst_count_gray_sync[i]),
                    .valid_o(1'b1)
                );
            end
        endgenerate
    endgenerate

    // Gray encoder/decoder for source count
    assign src_ready_gray = dst_ready_i & (src_count_gray_reg < (2**LOG_DEPTH - 1));
    assign src_full_gray = src_count_gray_reg == (2**LOG_DEPTH - 1);
    assign src_ready_o = src_ready_gray;

    // Gray encoder/decoder for destination count
    assign dst_valid_gray = src_valid_i & (dst_count_gray_reg > 0);
    assign dst_empty_gray = dst_count_gray_reg == 0;
    assign dst_valid_o = dst_valid_gray;

    // FIFO logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_count_gray_reg <= 0;
        end else if (!src_full_gray && src_valid_i && dst_ready_gray) begin
            src_count_gray_reg <= src_count_gray_reg + 1;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_count_gray_reg <= 0;
        end else if (!dst_empty_gray && dst_valid_gray && src_ready_gray) begin
            dst_count_gray_reg <= dst_count_gray_reg - 1;
        end
    end

    // Gray encoder/decoder for source count
    assign src_count_gray = src_count_gray_reg;

    // Gray encoder/decoder for destination count
    assign dst_count_gray = dst_count_gray_reg;

    // Data path
    logic [WIDTH-1:0] mem [2**LOG_DEPTH-1:0];
    logic [LOG_DEPTH-1:0] wr_ptr_gray;
    logic [LOG_DEPTH-1:0] rd_ptr_gray;
    logic [LOG_DEPTH-1:0] wr_ptr_gray_sync [SYNC_STAGES];
    logic [LOG_DEPTH-1:0] rd_ptr_gray_sync [SYNC_STAGES];

    assign wr_ptr_gray = src_count_gray_reg;
    assign rd_ptr_gray = dst_count_gray_reg;

    generate
        generate
            integer i;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_wr_ptr
                sync_crossing #(
                    .WIDTH(LOG_DEPTH),
                    .SYNC_STAGES(1)
                ) sync_wr_ptr_inst (
                    .clk_i(src_clk_i),
                    .rst_ni(src_rst_ni),
                    .data_i(wr_ptr_gray),
                    .valid_i(1'b1),
                    .data_o(wr_ptr_gray_sync[i]),
                    .valid_o(1'b1)
                );
            end
        endgenerate
    endgenerate

    generate
        generate
            integer i;
            for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_rd_ptr
                sync_crossing #(
                    .WIDTH(LOG_DEPTH),
                    .SYNC_STAGES(1)
                ) sync_rd_ptr_inst (
                    .clk_i(dst_clk_i),
                    .rst_ni(dst_rst_ni),
                    .data_i(rd_ptr_gray),
                    .valid_i(1'b1),
                    .data_o(rd_ptr_gray_sync[i]),
                    .valid_o(1'b1)
                );
            end
        endgenerate
    endgenerate

    assign mem[wr_ptr_gray] = src_data_sync[SYNC_STAGES-1];
    assign dst_data_sync[SYNC_STAGES-1] = mem[rd_ptr_gray];

endmodule

module sync_crossing #(
    parameter WIDTH = 1,
    parameter SYNC_STAGES = 2
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     data_i,
    input                  valid_i,
    output reg [WIDTH-1:0] data_o,
    output reg             valid_o
);

    logic [WIDTH-1:0] data_reg [SYNC_STAGES-1:0];
    logic valid_reg [SYNC_STAGES-1:0];

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            valid_reg <= {SYNC_STAGES{1'b0}};
        end else if (valid_i) begin
            valid_reg <= {valid_reg[SYNC_STAGES-2:0], 1'b1};
        end
    end

    assign valid_o = valid_reg[SYNC_STAGES-1];

    generate
        generate
            integer i;
            for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni) begin
                        data_reg[i] <= 0;
                    end else if (valid_reg[i]) begin
                        data_reg[i] <= data_i;
                    end
                end
            end
        endgenerate
    endgenerate

    assign data_o = data_reg[SYNC_STAGES-1];

endmodule
