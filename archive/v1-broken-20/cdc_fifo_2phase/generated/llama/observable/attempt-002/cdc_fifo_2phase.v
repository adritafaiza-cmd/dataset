module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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
reg [LOG_DEPTH-1:0] src_ptr_gray_sync, dst_ptr_gray_sync;
reg [LOG_DEPTH-1:0] src_ptr_sync, dst_ptr_sync;
reg src_empty, src_full;
reg dst_empty, dst_full;
reg src_valid_sync, dst_valid_sync;
reg [WIDTH-1:0] dst_data_sync;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
    end else begin
        if (src_valid_i && src_ready_o) begin
            src_ptr <= src_ptr + 1;
            src_ptr_gray <= src_ptr_gray + 1;
        end
    end
end

always @(posedge src_clk_i) begin
    src_ptr_gray <= {src_ptr_gray[LOG_DEPTH-2:0], src_ptr[0]};
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
    end else begin
        if (dst_valid_o && dst_ready_i) begin
            dst_ptr <= dst_ptr + 1;
            dst_ptr_gray <= dst_ptr_gray + 1;
        end
    end
end

always @(posedge dst_clk_i) begin
    dst_ptr_gray <= {dst_ptr_gray[LOG_DEPTH-2:0], dst_ptr[0]};
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
        dst_ptr_sync <= 0;
    end else begin
        dst_ptr_sync <= dst_ptr_gray;
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ptr_gray_sync <= 0;
    end else begin
        src_ptr_gray_sync <= src_ptr_gray;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_ptr_gray_sync <= 0;
    end else begin
        dst_ptr_gray_sync <= dst_ptr_gray;
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_empty <= 1;
        src_full <= 0;
    end else begin
        if (src_valid_i && src_ready_o) begin
            if (src_ptr == (2**LOG_DEPTH-1)) begin
                src_full <= 1;
            end
        end else if (src_ptr == 0) begin
            src_empty <= 1;
        end
        if (!src_valid_i ||!src_ready_o) begin
            if (src_ptr == (2**LOG_DEPTH-1)) begin
                src_full <= 0;
            end
        end
        if (src_ptr == 0) begin
            src_empty <= 0;
        end
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_empty <= 1;
        dst_full <= 0;
    end else begin
        if (dst_valid_o && dst_ready_i) begin
            if (dst_ptr == (2**LOG_DEPTH-1)) begin
                dst_full <= 1;
            end
        end else if (dst_ptr == 0) begin
            dst_empty <= 1;
        end
        if (!dst_valid_o ||!dst_ready_i) begin
            if (dst_ptr == (2**LOG_DEPTH-1)) begin
                dst_full <= 0;
            end
        end
        if (dst_ptr == 0) begin
            dst_empty <= 0;
        end
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_ready_o <= 1;
    end else begin
        if (src_valid_i && src_ready_o) begin
            if (src_ptr == (2**LOG_DEPTH-1)) begin
                src_ready_o <= 0;
            end
        end else if (src_ptr!= (2**LOG_DEPTH-1)) begin
            src_ready_o <= 1;
        end
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_valid_o <= 0;
    end else begin
        if (dst_valid_o && dst_ready_i) begin
            if (dst_ptr == 0) begin
                dst_valid_o <= 0;
            end
        end else if (dst_ptr!= 0) begin
            dst_valid_o <= 1;
        end
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_valid_sync <= 0;
    end else if (src_valid_i && src_ready_o) begin
        src_valid_sync <= 1;
    end else begin
        src_valid_sync <= 0;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_valid_sync <= 0;
    end else if (dst_valid_o && dst_ready_i) begin
        dst_valid_sync <= 1;
    end else begin
        dst_valid_sync <= 0;
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        mem[0] <= 0;
    end else if (src_valid_i && src_ready_o) begin
        mem[src_ptr] <= src_data_i;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_data_sync <= 0;
    end else if (dst_valid_o && dst_ready_i) begin
        dst_data_sync <= mem[dst_ptr];
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_data_o <= 0;
    end else begin
        dst_data_o <= dst_data_sync;
    end
end

endmodule
