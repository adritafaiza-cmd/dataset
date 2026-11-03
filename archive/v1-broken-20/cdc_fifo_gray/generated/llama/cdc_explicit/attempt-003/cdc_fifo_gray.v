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

    reg [WIDTH-1:0] mem [DEPTH-1:0];
    reg [LOG_DEPTH-1:0] src_ptr, dst_ptr;
    reg [LOG_DEPTH-1:0] src_ptr_gray, dst_ptr_gray;
    reg [LOG_DEPTH-1:0] src_ptr_sync, dst_ptr_sync;
    reg [WIDTH-1:0] dst_data_sync;
    reg dst_valid_sync;
    reg src_ready;
    reg dst_valid;

    assign src_ready_o = src_ready;
    assign dst_data_o = dst_data_sync;
    assign dst_valid_o = dst_valid_sync;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            src_ptr <= 0;
            src_ptr_gray <= 0;
            src_ready <= 1'b1;
        end else begin
            if (src_valid_i && src_ready) begin
                mem[src_ptr] <= src_data_i;
                src_ptr <= src_ptr + 1;
                src_ptr_gray <= gray_encode(src_ptr);
                src_ready <= (src_ptr != (DEPTH - 1));
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            dst_ptr <= 0;
            dst_ptr_gray <= 0;
            dst_ptr_sync <= 0;
            dst_data_sync <= 0;
            dst_valid_sync <= 1'b0;
            dst_valid <= 1'b0;
        end else begin
            if (dst_ready_i && dst_valid) begin
                dst_ptr <= dst_ptr + 1;
                dst_ptr_gray <= gray_encode(dst_ptr);
                dst_valid <= (dst_ptr != src_ptr_sync);
            end
            if (dst_ptr != src_ptr_sync) begin
                dst_data_sync <= mem[dst_ptr];
                dst_valid_sync <= 1'b1;
            end else begin
                dst_valid_sync <= 1'b0;
            end
        end
    end

    always @(posedge src_clk_i) begin
        src_ptr_sync <= src_ptr_gray;
    end

    always @(posedge dst_clk_i) begin
        dst_ptr_sync <= dst_ptr_gray;
    end

    function [LOG_DEPTH-1:0] gray_encode;
        input [LOG_DEPTH-1:0] bin;
        begin
            gray_encode = bin ^ (bin >> 1);
        end
    endfunction

    // Synchronization of src_ptr_gray
    reg [SYNC_STAGES-1:0] src_ptr_sync_reg;
    always @(posedge dst_clk_i) begin
        src_ptr_sync_reg[0] <= src_ptr_gray;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            src_ptr_sync_reg[i] <= src_ptr_sync_reg[i-1];
        end
        src_ptr_sync <= src_ptr_sync_reg[SYNC_STAGES-1];
    end

    // Synchronization of dst_valid
    reg [SYNC_STAGES-1:0] dst_valid_sync_reg;
    always @(posedge src_clk_i) begin
        dst_valid_sync_reg[0] <= dst_valid;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            dst_valid_sync_reg[i] <= dst_valid_sync_reg[i-1];
        end
        src_ready <= dst_valid_sync_reg[SYNC_STAGES-1];
    end

endmodule
