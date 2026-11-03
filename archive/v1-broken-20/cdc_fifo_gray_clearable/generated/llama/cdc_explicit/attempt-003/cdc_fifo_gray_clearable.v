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

    reg [WIDTH-1:0]         fifo_data [2**LOG_DEPTH-1:0];
    reg [LOG_DEPTH-1:0]    src_ptr;
    reg [LOG_DEPTH-1:0]    dst_ptr;
    reg [LOG_DEPTH-1:0]    src_ptr_gray;
    reg [LOG_DEPTH-1:0]    dst_ptr_gray;
    reg [SYNC_STAGES-1:0]  src_clear_sync;
    reg [SYNC_STAGES-1:0]  dst_clear_sync;
    reg [SYNC_STAGES-1:0]  src_rst_sync;
    reg [SYNC_STAGES-1:0]  dst_rst_sync;
    reg                    src_clear_pending;
    reg                    dst_clear_pending;
    reg                    src_empty;
    reg                    dst_empty;
    reg                    src_full;
    reg                    dst_valid;

    assign src_ready_o = ~src_full & ~src_clear_pending;
    assign dst_valid_o = dst_valid & ~dst_clear_pending;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            src_ptr <= 0;
            src_ptr_gray <= 0;
            src_clear_pending <= 0;
            src_empty <= 1;
            src_full <= 0;
        end else if (src_clear_i) begin
            src_ptr <= 0;
            src_ptr_gray <= 0;
            src_clear_pending <= 1;
            src_empty <= 1;
            src_full <= 0;
        end else if (src_valid_i & ~src_full) begin
            fifo_data[src_ptr] <= src_data_i;
            src_ptr <= src_ptr + 1;
            src_ptr_gray <= gray_encode(src_ptr);
            if (src_ptr == (2**LOG_DEPTH-1)) begin
                src_full <= 1;
            end
            src_empty <= 0;
        end else if (~src_valid_i & src_empty) begin
            src_empty <= 1;
            src_full <= 0;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            dst_ptr <= 0;
            dst_ptr_gray <= 0;
            dst_clear_pending <= 0;
            dst_empty <= 1;
            dst_valid <= 0;
        end else if (dst_clear_i) begin
            dst_ptr <= 0;
            dst_ptr_gray <= 0;
            dst_clear_pending <= 1;
            dst_empty <= 1;
            dst_valid <= 0;
        end else if (dst_ready_i & ~dst_empty) begin
            dst_data_o <= fifo_data[dst_ptr];
            dst_ptr <= dst_ptr + 1;
            dst_ptr_gray <= gray_encode(dst_ptr);
            if (dst_ptr == (2**LOG_DEPTH-1)) begin
                dst_empty <= 1;
            end
            dst_valid <= 1;
        end else if (~dst_ready_i & dst_empty) begin
            dst_empty <= 1;
            dst_valid <= 0;
        end
    end

    always @(posedge src_clk_i) begin
        if (~src_rst_ni) begin
            src_clear_sync <= 0;
            src_rst_sync <= 0;
        end else begin
            src_clear_sync[0] <= src_clear_i;
            src_rst_sync[0] <= ~src_rst_ni;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                src_clear_sync[i] <= src_clear_sync[i-1];
                src_rst_sync[i] <= src_rst_sync[i-1];
            end
        end
    end

    always @(posedge dst_clk_i) begin
        if (~dst_rst_ni) begin
            dst_clear_sync <= 0;
            dst_rst_sync <= 0;
        end else begin
            dst_clear_sync[0] <= dst_clear_i;
            dst_rst_sync[0] <= ~dst_rst_ni;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                dst_clear_sync[i] <= dst_clear_sync[i-1];
                dst_rst_sync[i] <= dst_rst_sync[i-1];
            end
        end
    end

    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

    function [LOG_DEPTH-1:0] gray_encode;
        input [LOG_DEPTH-1:0] bin;
        reg [LOG_DEPTH-1:0] gray;
        begin
            gray = bin ^ (bin >> 1);
            gray_encode = gray;
        end
    endfunction

endmodule
