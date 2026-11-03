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
    reg [WIDTH-1:0]        dst_data_reg;
    reg                    dst_valid_reg;
    reg                    src_clear_pending_reg;
    reg                    dst_clear_pending_reg;
    reg                    src_ready_reg;
    reg                    dst_valid_reg_sync;

    assign src_clear_pending_o = src_clear_pending_reg;
    assign dst_clear_pending_o = dst_clear_pending_reg;
    assign src_ready_o = src_ready_reg;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
            src_ptr_gray <= 0;
            src_clear_sync <= 0;
            src_rst_sync <= 0;
            src_clear_pending_reg <= 0;
            src_ready_reg <= 0;
        end else if (src_clear_i) begin
            src_ptr <= 0;
            src_ptr_gray <= 0;
            src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
            src_rst_sync <= {src_rst_sync[SYNC_STAGES-2:0], 1'b0};
            src_clear_pending_reg <= 1'b1;
            src_ready_reg <= 1'b0;
        end else begin
            if (src_valid_i && src_ready_reg) begin
                fifo_data[src_ptr] <= src_data_i;
                src_ptr <= src_ptr + 1;
                src_ptr_gray <= gray_encode(src_ptr);
            end
            src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
            src_rst_sync <= {src_rst_sync[SYNC_STAGES-2:0], 1'b0};
            if (src_clear_sync[SYNC_STAGES-1]) begin
                src_clear_pending_reg <= 1'b1;
                src_ready_reg <= 1'b0;
            end else if (src_rst_sync[SYNC_STAGES-1]) begin
                src_clear_pending_reg <= 1'b0;
                src_ready_reg <= 1'b1;
            end else begin
                src_clear_pending_reg <= 1'b0;
                src_ready_reg <= (src_ptr != 2**LOG_DEPTH-1);
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= 0;
            dst_ptr_gray <= 0;
            dst_clear_sync <= 0;
            dst_rst_sync <= 0;
            dst_clear_pending_reg <= 0;
            dst_valid_reg <= 0;
            dst_data_reg <= 0;
            dst_valid_reg_sync <= 0;
        end else if (dst_clear_i) begin
            dst_ptr <= 0;
            dst_ptr_gray <= 0;
            dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
            dst_rst_sync <= {dst_rst_sync[SYNC_STAGES-2:0], 1'b0};
            dst_clear_pending_reg <= 1'b1;
            dst_valid_reg <= 0;
            dst_data_reg <= 0;
            dst_valid_reg_sync <= 0;
        end else begin
            if (dst_valid_reg && dst_ready_i) begin
                dst_ptr <= dst_ptr + 1;
                dst_ptr_gray <= gray_encode(dst_ptr);
                dst_valid_reg <= 0;
            end
            dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
            dst_rst_sync <= {dst_rst_sync[SYNC_STAGES-2:0], 1'b0};
            if (dst_clear_sync[SYNC_STAGES-1]) begin
                dst_clear_pending_reg <= 1'b1;
                dst_valid_reg <= 0;
                dst_data_reg <= 0;
                dst_valid_reg_sync <= 0;
            end else if (dst_rst_sync[SYNC_STAGES-1]) begin
                dst_clear_pending_reg <= 1'b0;
                dst_valid_reg <= 0;
                dst_data_reg <= 0;
                dst_valid_reg_sync <= 0;
            end else begin
                dst_clear_pending_reg <= 1'b0;
                if (dst_valid_reg_sync) begin
                    dst_valid_reg <= 1'b1;
                    dst_data_reg <= fifo_data[dst_ptr_gray];
                end
                dst_valid_reg_sync <= (dst_ptr != 0);
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
