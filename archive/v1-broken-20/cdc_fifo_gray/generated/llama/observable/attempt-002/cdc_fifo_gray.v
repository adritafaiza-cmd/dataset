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

reg [WIDTH-1:0]             mem [2**LOG_DEPTH-1:0];
reg [$clog2(2**LOG_DEPTH)-1:0] src_ptr, dst_ptr;
reg [$clog2(2**LOG_DEPTH)-1:0] src_ptr_gray, dst_ptr_gray;
reg [$clog2(2**LOG_DEPTH)-1:0] src_ptr_sync [SYNC_STAGES-1:0];
reg [$clog2(2**LOG_DEPTH)-1:0] dst_ptr_sync [SYNC_STAGES-1:0];
reg [WIDTH-1:0]             dst_data_sync;
reg                         dst_valid_sync;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
    end else begin
        if (src_valid_i && src_ready_o) begin
            mem[src_ptr] <= src_data_i;
            src_ptr <= src_ptr + 1;
            src_ptr_gray <= src_ptr_gray + 1;
        end
        src_ptr_gray <= (src_ptr_gray >> 1) | (src_ptr_gray[0] ^ src_ptr_gray[1]);
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_ptr_sync <= '{default: 0};
        dst_data_sync <= 0;
        dst_valid_sync <= 0;
    end else begin
        dst_ptr_sync[0] <= src_ptr_gray;
        for (genvar i = 1; i < SYNC_STAGES; i++) begin
            dst_ptr_sync[i] <= dst_ptr_sync[i-1];
        end
        dst_ptr_gray <= dst_ptr_sync[SYNC_STAGES-1];
        if (dst_valid_sync && dst_ready_i) begin
            dst_ptr <= dst_ptr + 1;
        end
        if (dst_ptr_gray!= dst_ptr) begin
            dst_data_sync <= mem[dst_ptr];
            dst_valid_sync <= 1;
        end else begin
            dst_valid_sync <= 0;
        end
    end
end

assign src_ready_o = (src_ptr_gray!= (dst_ptr_gray + (2**LOG_DEPTH-1)));
assign dst_data_o = dst_data_sync;
assign dst_valid_o = dst_valid_sync;

endmodule
