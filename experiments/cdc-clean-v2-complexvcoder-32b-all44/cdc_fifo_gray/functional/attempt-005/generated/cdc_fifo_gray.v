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

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Internal signals
    reg [PTR_WIDTH-1:0] src_ptr, src_gray_ptr, sync_dst_gray_ptr;
    reg [PTR_WIDTH-1:0] dst_ptr, dst_gray_ptr, sync_src_gray_ptr;
    reg [WIDTH-1:0] fifo_memory [0:DEPTH-1];
    reg src_empty, src_full, dst_empty, dst_full;

    // Gray code conversion functions
    function [PTR_WIDTH-1:0] bin_to_gray;
        input [PTR_WIDTH-1:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    function [PTR_WIDTH-1:0] gray_to_bin;
        input [PTR_WIDTH-1:0] gray;
        integer i;
        reg [PTR_WIDTH-1:0] bin;
        bin = gray;
        for (i = PTR_WIDTH-2; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        gray_to_bin = bin;
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
            src_gray_ptr <= 0;
        end else if (src_valid_i && src_ready_o) begin
            fifo_memory[src_ptr[PTR_WIDTH-2:0]] <= src_data_i;
            src_ptr <= src_ptr + 1;
            src_gray_ptr <= bin_to_gray(src_ptr + 1);
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= 0;
            dst_gray_ptr <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_ptr <= dst_ptr + 1;
            dst_gray_ptr <= bin_to_gray(dst_ptr + 1);
        end
    end

    // Synchronizers for pointers
    sync_register #(.WIDTH(PTR_WIDTH), .STAGES(SYNC_STAGES)) src_gray_sync (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_i(src_gray_ptr),
        .data_o(sync_src_gray_ptr)
    );

    sync_register #(.WIDTH(PTR_WIDTH), .STAGES(SYNC_STAGES)) dst_gray_sync (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_i(dst_gray_ptr),
        .data_o(sync_dst_gray_ptr)
    );

    // Calculate empty and full flags
    assign src_empty = (src_ptr == gray_to_bin(sync_dst_gray_ptr));
    assign src_full = (gray_to_bin(sync_src_gray_ptr) == src_ptr + 1);
    assign dst_empty = (dst_ptr == gray_to_bin(sync_src_gray_ptr));
    assign dst_full = (gray_to_bin(sync_dst_gray_ptr) == dst_ptr + 1);

    // Ready and valid signals
    assign src_ready_o = !src_full;
    assign dst_data_o = fifo_memory[dst_ptr[PTR_WIDTH-2:0]];
    assign dst_valid_o = !dst_empty;

endmodule

module sync_register #(
    parameter WIDTH = 8,
    parameter STAGES = 2
)(
    input clk_i,
    input rst_ni,
    input [WIDTH-1:0] data_i,
    output reg [WIDTH-1:0] data_o
);

    reg [WIDTH-1:0] sync_chain [0:STAGES-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_o <= 0;
            sync_chain <= {STAGES{WIDTH{1'b0}}};
        end else begin
            sync_chain[0] <= data_i;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_chain[i] <= sync_chain[i-1];
            end
            data_o <= sync_chain[STAGES-1];
        end
    end

endmodule
