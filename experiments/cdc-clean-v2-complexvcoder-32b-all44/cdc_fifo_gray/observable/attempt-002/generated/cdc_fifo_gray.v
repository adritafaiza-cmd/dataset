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
    reg [LOG_DEPTH-1:0] src_gray_counter_data_in;
    reg [LOG_DEPTH-1:0] src_gray_counter_data_out;
    reg [LOG_DEPTH-1:0] dst_gray_counter_data_in;
    reg [LOG_DEPTH-1:0] dst_gray_counter_data_out;
    reg [LOG_DEPTH-1:0] src_gray_counter_synced_to_dst;
    reg [LOG_DEPTH-1:0] dst_gray_counter_synced_to_src;
    reg [WIDTH-1:0] fifo_memory [0:(2**LOG_DEPTH)-1];
    reg [LOG_DEPTH-1:0] src_ptr_gray;
    reg [LOG_DEPTH-1:0] src_ptr_bin;
    reg [LOG_DEPTH-1:0] dst_ptr_gray;
    reg [LOG_DEPTH-1:0] dst_ptr_bin;
    reg full_flag;
    reg empty_flag;

    // Gray code conversion function
    function [LOG_DEPTH-1:0] binary_to_gray;
        input [LOG_DEPTH-1:0] binary;
        binary_to_gray = binary ^ (binary >> 1);
    endfunction

    // Binary conversion function
    function [LOG_DEPTH-1:0] gray_to_binary;
        input [LOG_DEPTH-1:0] gray;
        integer i;
        reg [LOG_DEPTH-1:0] binary;
        binary = gray;
        for (i = LOG_DEPTH-2; i >= 0; i = i - 1) begin
            binary[i] = binary[i+1] ^ gray[i];
        end
        gray_to_binary = binary;
    endfunction

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_counter_data_in <= 0;
            src_ptr_gray <= 0;
            src_ptr_bin <= 0;
            full_flag <= 0;
        end else begin
            src_ptr_bin <= gray_to_binary(src_gray_counter_data_out);
            full_flag <= (src_ptr_bin + 1) == gray_to_binary(dst_gray_counter_synced_to_src);
            if (src_valid_i && !full_flag) begin
                fifo_memory[src_ptr_bin] <= src_data_i;
                src_gray_counter_data_in <= src_gray_counter_data_out + 1;
            end
        end
    end

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_counter_data_in <= 0;
            dst_ptr_gray <= 0;
            dst_ptr_bin <= 0;
            empty_flag <= 1;
        end else begin
            dst_ptr_bin <= gray_to_binary(dst_gray_counter_data_out);
            empty_flag <= gray_to_binary(src_gray_counter_synced_to_dst) == dst_ptr_bin;
            if (dst_ready_i && !empty_flag) begin
                dst_gray_counter_data_in <= dst_gray_counter_data_out + 1;
            end
        end
    end

    // Source ready output
    assign src_ready_o = !full_flag;

    // Destination valid output and data output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
            dst_valid_o <= 0;
        end else begin
            dst_data_o <= fifo_memory[dst_ptr_bin];
            dst_valid_o <= !empty_flag && dst_ready_i;
        end
    end

    // Gray counters and synchronizers
    gray_counter src_gray_counter (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .data_in(src_gray_counter_data_in),
        .data_out(src_gray_counter_data_out)
    );

    gray_counter dst_gray_counter (
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .data_in(dst_gray_counter_data_in),
        .data_out(dst_gray_counter_data_out)
    );

    sync_register src_to_dst_sync (
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .data_in(src_gray_counter_data_out),
        .data_out(src_gray_counter_synced_to_dst)
    );

    sync_register dst_to_src_sync (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .data_in(dst_gray_counter_data_out),
        .data_out(dst_gray_counter_synced_to_src)
    );

endmodule

module gray_counter (
    input clk,
    input rst_n,
    input [LOG_DEPTH-1:0] data_in,
    output reg [LOG_DEPTH-1:0] data_out
);

    reg [LOG_DEPTH-1:0] gray_code;
    reg [LOG_DEPTH-1:0] next_gray_code;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_code <= 0;
        end else begin
            gray_code <= next_gray_code;
        end
    end

    always @(*) begin
        next_gray_code = binary_to_gray(data_in);
        data_out = gray_code;
    end

    function [LOG_DEPTH-1:0] binary_to_gray;
        input [LOG_DEPTH-1:0] binary;
        binary_to_gray = binary ^ (binary >> 1);
    endfunction

endmodule

module sync_register (
    input clk,
    input rst_n,
    input [LOG_DEPTH-1:0] data_in,
    output reg [LOG_DEPTH-1:0] data_out
);

    reg [LOG_DEPTH-1:0] sync_stage_1;
    reg [LOG_DEPTH-1:0] sync_stage_2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage_1 <= 0;
            sync_stage_2 <= 0;
            data_out <= 0;
        end else begin
            sync_stage_1 <= data_in;
            sync_stage_2 <= sync_stage_1;
            data_out <= sync_stage_2;
        end
    end

endmodule
