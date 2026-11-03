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
reg [LOG_DEPTH-1:0]         src_ptr;
reg [LOG_DEPTH-1:0]         dst_ptr;
reg [LOG_DEPTH-1:0]         src_ptr_gray;
reg [LOG_DEPTH-1:0]         dst_ptr_gray;
reg [LOG_DEPTH-1:0]         src_ptr_sync [SYNC_STAGES-1:0];
reg [LOG_DEPTH-1:0]         dst_ptr_sync [SYNC_STAGES-1:0];
reg [WIDTH-1:0]             data_out;
reg                       dst_valid;
reg                       src_ready;
reg                       full;
reg                       empty;

assign src_ready_o = src_ready;
assign dst_data_o = data_out;
assign dst_valid_o = dst_valid;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
        full <= 0;
        src_ready <= 1;
    end else begin
        if (src_valid_i && src_ready) begin
            mem[src_ptr] <= src_data_i;
            src_ptr <= src_ptr + 1;
            if (src_ptr == 2**LOG_DEPTH-1) begin
                src_ptr <= 0;
            end
            src_ptr_gray <= src_ptr_gray + 1;
            if (src_ptr_gray == 2**LOG_DEPTH-1) begin
                src_ptr_gray <= 0;
            end
            if (src_ptr == dst_ptr_sync[SYNC_STAGES-1]) begin
                full <= 1;
                src_ready <= 0;
            end else begin
                full <= 0;
                src_ready <= 1;
            end
        end
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
        empty <= 1;
        dst_valid <= 0;
    end else begin
        if (dst_valid && dst_ready_i) begin
            dst_ptr <= dst_ptr + 1;
            if (dst_ptr == 2**LOG_DEPTH-1) begin
                dst_ptr <= 0;
            end
            dst_ptr_gray <= dst_ptr_gray + 1;
            if (dst_ptr_gray == 2**LOG_DEPTH-1) begin
                dst_ptr_gray <= 0;
            end
            empty <= 1;
            dst_valid <= 0;
        end
        if (!empty && !dst_valid) begin
            data_out <= mem[dst_ptr];
            dst_valid <= 1;
            if (dst_ptr == src_ptr_sync[SYNC_STAGES-1]) begin
                empty <= 1;
            end else begin
                empty <= 0;
            end
        end
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr_sync[0] <= 0;
    end else begin
        src_ptr_sync[0] <= src_ptr_gray;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ptr_sync[0] <= 0;
    end else begin
        dst_ptr_sync[0] <= dst_ptr_gray;
    end
end

genvar i;
generate
    for (i = 1; i < SYNC_STAGES; i = i + 1) begin
        always @(posedge src_clk_i or negedge src_rst_ni) begin
            if (!src_rst_ni) begin
                src_ptr_sync[i] <= 0;
            end else begin
                src_ptr_sync[i] <= src_ptr_sync[i-1];
            end
        end
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
            if (!dst_rst_ni) begin
                dst_ptr_sync[i] <= 0;
            end else begin
                dst_ptr_sync[i] <= dst_ptr_sync[i-1];
            end
        end
    end
endgenerate

endmodule
