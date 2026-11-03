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

reg [WIDTH-1:0] fifo [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] src_ptr, dst_ptr;
reg [LOG_DEPTH-1:0] src_ptr_gray, dst_ptr_gray;
reg [LOG_DEPTH-1:0] src_ptr_gray_sync, dst_ptr_gray_sync;
reg [LOG_DEPTH-1:0] src_ptr_sync, dst_ptr_sync;
reg src_empty, src_full;
reg dst_empty, dst_full;
reg src_ready, dst_valid;

always @(posedge src_clk_i or negedge src_rst_ni)
begin
    if (!src_rst_ni)
    begin
        src_ptr <= 0;
        src_ptr_gray <= 0;
    end
    else
    begin
        if (src_valid_i && src_ready)
        begin
            fifo[src_ptr] <= src_data_i;
            src_ptr <= src_ptr + 1;
            src_ptr_gray <= src_ptr_gray + 1;
        end
    end
end

always @(posedge src_clk_i)
begin
    src_ptr_gray[0] <= src_ptr_gray[0] ^ src_ptr[0];
    for (int i = 1; i < LOG_DEPTH; i++)
    begin
        src_ptr_gray[i] <= src_ptr_gray[i-1] ^ src_ptr[i];
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni)
begin
    if (!dst_rst_ni)
    begin
        dst_ptr <= 0;
        dst_ptr_gray <= 0;
    end
    else
    begin
        if (dst_valid && dst_ready_i)
        begin
            dst_ptr <= dst_ptr + 1;
            dst_ptr_gray <= dst_ptr_gray + 1;
        end
    end
end

always @(posedge dst_clk_i)
begin
    dst_ptr_gray[0] <= dst_ptr_gray[0] ^ dst_ptr[0];
    for (int i = 1; i < LOG_DEPTH; i++)
    begin
        dst_ptr_gray[i] <= dst_ptr_gray[i-1] ^ dst_ptr[i];
    end
end

always @(posedge src_clk_i)
begin
    src_ptr_sync <= src_ptr_gray_sync;
    src_ptr_gray_sync[0] <= src_ptr_gray[0];
    for (int i = 1; i < LOG_DEPTH; i++)
    begin
        src_ptr_gray_sync[i] <= src_ptr_gray_sync[i-1] ^ src_ptr_gray[i];
    end
end

always @(posedge dst_clk_i)
begin
    dst_ptr_sync <= dst_ptr_gray_sync;
    dst_ptr_gray_sync[0] <= dst_ptr_gray[0];
    for (int i = 1; i < LOG_DEPTH; i++)
    begin
        dst_ptr_gray_sync[i] <= dst_ptr_gray_sync[i-1] ^ dst_ptr_gray[i];
    end
end

always @(posedge src_clk_i or negedge src_rst_ni)
begin
    if (!src_rst_ni)
    begin
        src_empty <= 1;
        src_full <= 0;
    end
    else
    begin
        if (src_valid_i && src_ready)
        begin
            src_empty <= 0;
            if (src_ptr == (2**LOG_DEPTH - 1))
            begin
                src_full <= 1;
            end
        end
        else if (!src_valid_i && src_ready)
        begin
            src_full <= 0;
            if (src_ptr == 0)
            begin
                src_empty <= 1;
            end
        end
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni)
begin
    if (!dst_rst_ni)
    begin
        dst_empty <= 1;
        dst_full <= 0;
    end
    else
    begin
        if (dst_valid && dst_ready_i)
        begin
            dst_empty <= 0;
            if (dst_ptr == (2**LOG_DEPTH - 1))
            begin
                dst_full <= 1;
            end
        end
        else if (!dst_valid && dst_ready_i)
        begin
            dst_full <= 0;
            if (dst_ptr == 0)
            begin
                dst_empty <= 1;
            end
        end
    end
end

always @(posedge src_clk_i)
begin
    src_ready <= !src_full;
end

always @(posedge dst_clk_i)
begin
    dst_valid <= !dst_empty;
    dst_data_o <= fifo[dst_ptr_sync];
end

assign src_ready_o = src_ready;
assign dst_valid_o = dst_valid;

endmodule
