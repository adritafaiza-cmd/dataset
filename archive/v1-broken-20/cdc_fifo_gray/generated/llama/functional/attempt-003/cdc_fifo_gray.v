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

    reg [WIDTH-1:0]         mem [2**LOG_DEPTH-1:0];
    reg [LOG_DEPTH-1:0]     src_ptr;
    reg [LOG_DEPTH-1:0]     dst_ptr;
    reg [LOG_DEPTH-1:0]     src_ptr_gray;
    reg [LOG_DEPTH-1:0]     dst_ptr_gray;
    reg [SYNC_STAGES-1:0]   src_rst_sync;
    reg [SYNC_STAGES-1:0]   dst_rst_sync;
    reg [WIDTH-1:0]         dst_data_reg;
    reg                     dst_valid_reg;
    reg                     src_ready_reg;
    reg                     src_valid_sync;

    assign src_ready_o = src_ready_reg;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            src_ptr <= 0;
            src_ptr_gray <= 0;
            src_ready_reg <= 1'b1;
            src_rst_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            src_rst_sync <= {src_rst_sync[SYNC_STAGES-2:0], src_rst_ni};
            if (src_valid_i && src_ready_reg) begin
                mem[src_ptr] <= src_data_i;
                src_ptr <= src_ptr + 1;
                src_ptr_gray <= gray_encode(src_ptr);
            end
            if (src_valid_i && ~src_ready_reg) begin
                src_ready_reg <= 1'b0;
            end else if (~src_valid_i && src_ready_reg) begin
                src_ready_reg <= 1'b1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            dst_ptr <= 0;
            dst_ptr_gray <= 0;
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
            dst_rst_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dst_rst_sync <= {dst_rst_sync[SYNC_STAGES-2:0], dst_rst_ni};
            if (dst_ready_i && dst_valid_reg) begin
                dst_ptr <= dst_ptr + 1;
                dst_ptr_gray <= gray_encode(dst_ptr);
                dst_valid_reg <= 1'b0;
            end else if (~dst_ready_i && dst_valid_reg) begin
                dst_valid_reg <= 1'b1;
            end else if (dst_ptr_gray!= src_ptr_gray) begin
                dst_data_reg <= mem[dst_ptr];
                dst_valid_reg <= 1'b1;
            end
        end
    end

    function [LOG_DEPTH-1:0] gray_encode;
        input [LOG_DEPTH-1:0] bin;
        reg [LOG_DEPTH-1:0] gray;
        begin
            gray = bin ^ (bin >> 1);
            gray_encode = gray;
        end
    endfunction

endmodule
