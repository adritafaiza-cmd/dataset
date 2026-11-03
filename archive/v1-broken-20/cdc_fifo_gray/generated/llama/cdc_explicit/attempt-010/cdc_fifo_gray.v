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

    reg [WIDTH-1:0]         mem [DEPTH-1:0];
    reg [LOG_DEPTH-1:0]     src_ptr;
    reg [LOG_DEPTH-1:0]     dst_ptr;
    reg [LOG_DEPTH-1:0]     src_ptr_gray;
    reg [LOG_DEPTH-1:0]     dst_ptr_gray;
    reg [SYNC_STAGES-1:0]   src_rst_sync;
    reg [SYNC_STAGES-1:0]   dst_rst_sync;
    reg                     src_empty;
    reg                     dst_full;
    reg                     src_ready;
    reg                     dst_valid;

    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
            src_ptr_gray <= 0;
            src_rst_sync <= {SYNC_STAGES{1'b0}};
            src_empty <= 1'b1;
            src_ready <= 1'b1;
        end else begin
            if (src_rst_sync[SYNC_STAGES-1]) begin
                if (src_valid_i && src_ready) begin
                    mem[src_ptr] <= src_data_i;
                    src_ptr <= src_ptr + 1;
                    src_ptr_gray <= gray_encode(src_ptr);
                    src_empty <= 1'b0;
                    if (src_ptr == DEPTH - 1) begin
                        src_ready <= 1'b0;
                    end
                end
                if (dst_ptr_gray == gray_decode(src_ptr_gray) && dst_valid) begin
                    src_ready <= 1'b1;
                end
            end
            src_rst_sync[0] <= ~src_rst_ni;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                src_rst_sync[i] <= src_rst_sync[i-1];
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= 0;
            dst_ptr_gray <= 0;
            dst_rst_sync <= {SYNC_STAGES{1'b0}};
            dst_full <= 1'b0;
            dst_valid <= 1'b0;
            dst_data_o <= {WIDTH{1'b0}};
        end else begin
            if (dst_rst_sync[SYNC_STAGES-1]) begin
                if (dst_ready_i && dst_valid) begin
                    dst_ptr <= dst_ptr + 1;
                    dst_ptr_gray <= gray_encode(dst_ptr);
                    dst_full <= 1'b0;
                    if (dst_ptr == DEPTH - 1) begin
                        dst_valid <= 1'b0;
                    end
                end
                if (src_ptr_gray == gray_decode(dst_ptr_gray) && src_valid_i && src_ready) begin
                    dst_valid <= 1'b1;
                    dst_data_o <= mem[dst_ptr];
                end
            end
            dst_rst_sync[0] <= ~dst_rst_ni;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                dst_rst_sync[i] <= dst_rst_sync[i-1];
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

    function [LOG_DEPTH-1:0] gray_decode;
        input [LOG_DEPTH-1:0] gray;
        reg [LOG_DEPTH-1:0] bin;
        begin
            bin = gray;
            for (int i = 1; i < LOG_DEPTH; i++) begin
                bin = bin ^ (bin >> i);
            end
            gray_decode = bin;
        end
    endfunction

endmodule
