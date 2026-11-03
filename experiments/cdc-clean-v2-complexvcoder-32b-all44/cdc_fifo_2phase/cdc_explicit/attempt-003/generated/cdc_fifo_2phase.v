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
    wire                   sync_src_valid_o;
    wire                   sync_src_ready_o;
    wire                   sync_dst_ready_o;

    // Instantiate synchronizer stages
    sync_stage sync_src_valid (
        .src_valid_i(src_valid_i),
        .sync_valid_o(sync_src_valid_o),
        .dst_clk(dst_clk_i),
        .dst_rst_ni(dst_rst_ni)
    );

    sync_stage sync_src_ready (
        .src_valid_i(sync_src_ready_o),
        .sync_valid_o(src_ready_o),
        .dst_clk(src_clk_i),
        .dst_rst_ni(src_rst_ni)
    );

    sync_stage sync_dst_ready (
        .src_valid_i(dst_ready_i),
        .sync_valid_o(sync_dst_ready_o),
        .dst_clk(dst_clk_i),
        .dst_rst_ni(dst_rst_ni)
    );

    // Instantiate FIFO core
    fifo_core fifo_core_inst (
        .src_clk_i(src_clk_i),
        .src_rst_ni(src_rst_ni),
        .src_data_i(src_data_i),
        .src_valid_i(sync_src_valid_o),
        .src_ready_o(sync_src_ready_o),
        .dst_clk_i(dst_clk_i),
        .dst_rst_ni(dst_rst_ni),
        .dst_data_o(dst_data_o),
        .dst_valid_o(dst_valid_o),
        .dst_ready_i(sync_dst_ready_o)
    );

endmodule

module sync_stage (
    input  src_valid_i,
    output sync_valid_o,
    input  dst_clk,
    input  dst_rst_ni
);

    reg sync_stage_1;
    reg sync_stage_2;

    always @(posedge dst_clk or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            sync_stage_1 <= 1'b0;
            sync_stage_2 <= 1'b0;
        end else begin
            sync_stage_1 <= src_valid_i;
            sync_stage_2 <= sync_stage_1;
        end
    end

    assign sync_valid_o = sync_stage_2;

endmodule

module fifo_core #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_clk_i,
    input                  src_rst_ni,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_clk_i,
    input                  dst_rst_ni,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    reg [WIDTH-1:0] fifo_mem [0:DEPTH-1];
    reg [LOG_DEPTH-1:0] write_ptr;
    reg [LOG_DEPTH-1:0] read_ptr;
    reg [LOG_DEPTH:0] write_ptr_gray;
    reg [LOG_DEPTH:0] read_ptr_gray;
    reg [LOG_DEPTH:0] sync_read_ptr_gray;
    reg [LOG_DEPTH:0] sync_write_ptr_gray;
    reg fifo_empty;
    reg fifo_full;

    // Gray code conversion functions
    function [LOG_DEPTH:0] bin2gray;
        input [LOG_DEPTH-1:0] bin;
        bin2gray = (bin >> 1) ^ bin;
    endfunction

    // Write pointer logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_ptr <= 0;
            write_ptr_gray <= 0;
        end else if (src_valid_i && src_ready_o) begin
            write_ptr <= write_ptr + 1;
            write_ptr_gray <= bin2gray(write_ptr + 1);
        end
    end

    // Read pointer logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_ptr <= 0;
            read_ptr_gray <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            read_ptr <= read_ptr + 1;
            read_ptr_gray <= bin2gray(read_ptr + 1);
        end
    end

    // Synchronize read pointer to src_clk_i
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_read_ptr_gray <= 0;
        end else begin
            sync_read_ptr_gray <= read_ptr_gray;
        end
    end

    // Synchronize write pointer to dst_clk_i
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            sync_write_ptr_gray <= 0;
        end else begin
            sync_write_ptr_gray <= write_ptr_gray;
        end
    end

    // FIFO full and empty detection
    always @(*) begin
        fifo_full = (write_ptr_gray[LOG_DEPTH-1:0] == sync_read_ptr_gray[LOG_DEPTH-1:0] + 1) &&
                    (write_ptr_gray[LOG_DEPTH] != sync_read_ptr_gray[LOG_DEPTH]);
        fifo_empty = (write_ptr_gray == sync_read_ptr_gray);
    end

    // Source ready signal
    assign src_ready_o = ~fifo_full;

    // Write data to FIFO
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o) begin
            fifo_mem[write_ptr] <= src_data_i;
        end
    end

    // Read data from FIFO
    always @(posedge dst_clk_i) begin
        if (dst_valid_o && dst_ready_i) begin
            dst_data_o <= fifo_mem[read_ptr];
        end
    end

    // Destination valid signal
    reg [1:0] dst_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 0;
        end else if (sync_src_valid_o && !fifo_empty) begin
            dst_valid_reg <= 2'b11;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_valid_reg <= dst_valid_reg[1];
        end
    end

    assign dst_valid_o = dst_valid_reg[1];

endmodule
