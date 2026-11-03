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
reg [LOG_DEPTH-1:0] src_ptr;
reg [LOG_DEPTH-1:0] dst_ptr;
reg [LOG_DEPTH-1:0] src_ptr_gray;
reg [LOG_DEPTH-1:0] dst_ptr_gray;
reg [LOG_DEPTH-1:0] src_ptr_sync [SYNC_STAGES-1:0];
reg [LOG_DEPTH-1:0] dst_ptr_sync [SYNC_STAGES-1:0];
reg [WIDTH-1:0] data_sync [SYNC_STAGES-1:0];
reg src_valid_sync [SYNC_STAGES-1:0];
reg dst_valid_sync;
reg src_ready_sync;
reg dst_ready_sync;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
        src_valid_sync[0] <= 0;
        src_ready_sync <= 0;
    end else begin
        if (src_valid_i && src_ready_o) begin
            mem[src_ptr] <= src_data_i;
            src_ptr <= src_ptr + 1;
            src_ptr_gray <= src_ptr_gray + 1;
        end
        src_valid_sync[0] <= src_valid_i;
        src_ready_sync <= !((src_ptr_gray ^ (src_ptr_gray >> 1)) == (1 << (LOG_DEPTH-1)));
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        dst_valid_sync <= 0;
        dst_ready_sync <= 0;
    end else begin
        if (dst_valid_o && dst_ready_i) begin
            dst_ptr <= dst_ptr + 1;
            dst_ptr_gray <= dst_ptr_gray + 1;
        end
        dst_valid_sync <= (dst_ptr_gray != src_ptr_sync[SYNC_STAGES-1]);
        dst_ready_sync <= !((dst_ptr_gray ^ (dst_ptr_gray >> 1)) == (1 << (LOG_DEPTH-1)));
    end
end

always @(posedge src_clk_i) begin
    src_ptr_sync[0] <= src_ptr_gray;
    for (int i = 1; i < SYNC_STAGES; i++) begin
        src_ptr_sync[i] <= src_ptr_sync[i-1];
    end
    data_sync[0] <= src_data_i;
    for (int i = 1; i < SYNC_STAGES; i++) begin
        data_sync[i] <= data_sync[i-1];
    end
    src_valid_sync[0] <= src_valid_i;
    for (int i = 1; i < SYNC_STAGES; i++) begin
        src_valid_sync[i] <= src_valid_sync[i-1];
    end
end

always @(posedge dst_clk_i) begin
    dst_ptr_sync[0] <= dst_ptr_gray;
    for (int i = 1; i < SYNC_STAGES; i++) begin
        dst_ptr_sync[i] <= dst_ptr_sync[i-1];
    end
end

assign src_ready_o = src_ready_sync;
assign dst_data_o = mem[dst_ptr];
assign dst_valid_o = dst_valid_sync;
assign src_ready_sync = !((src_ptr_gray ^ (src_ptr_gray >> 1)) == (1 << (LOG_DEPTH-1)));

endmodule
