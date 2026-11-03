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

reg [WIDTH-1:0] mem [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] src_ptr, dst_ptr;
reg [LOG_DEPTH-1:0] src_ptr_gray, dst_ptr_gray;
reg [LOG_DEPTH-1:0] src_ptr_sync, dst_ptr_sync;
reg [WIDTH-1:0] data_out;
reg src_valid_sync, dst_valid_sync;
reg src_ready, dst_ready;

assign src_ready_o = src_ready;
assign dst_data_o = data_out;
assign dst_valid_o = dst_valid_sync;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
    end else begin
        if (src_valid_i && src_ready) begin
            src_ptr <= src_ptr + 1;
            mem[src_ptr] <= src_data_i;
        end
        src_ptr_gray <= {src_ptr[LOG_DEPTH-2:0], 1'b0} ^ {src_ptr[LOG_DEPTH-1], src_ptr[LOG_DEPTH-2:1]};
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_ptr_sync <= 0;
    end else begin
        if (dst_valid_sync && dst_ready_i) begin
            dst_ptr <= dst_ptr + 1;
        end
        dst_ptr_gray <= {dst_ptr[LOG_DEPTH-2:0], 1'b0} ^ {dst_ptr[LOG_DEPTH-1], dst_ptr[LOG_DEPTH-2:1]};
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr_sync <= 0;
    end else begin
        src_ptr_sync <= src_ptr_gray;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_valid_sync <= 0;
        data_out <= 0;
    end else begin
        if (dst_ready_i) begin
            if (dst_ptr_sync != src_ptr_sync) begin
                dst_valid_sync <= 1;
                data_out <= mem[dst_ptr_sync];
            end else begin
                dst_valid_sync <= 0;
            end
        end
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ready <= 0;
    end else begin
        src_ready <= (src_ptr + 1) != dst_ptr_sync;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ready <= 0;
    end else begin
        dst_ready <= dst_valid_sync && dst_ready_i;
    end
end

endmodule
