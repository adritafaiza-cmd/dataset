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

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [WIDTH-1:0]             mem [DEPTH-1:0];
    reg [$clog2(DEPTH)-1:0]     wptr, rptr;
    reg [$clog2(DEPTH)-1:0]     wptr_gray, rptr_gray;
    reg [$clog2(DEPTH)-1:0]     wptr_gray_dst, rptr_gray_src;
    reg                         full, empty;
    reg                         src_valid_d, dst_ready_d;
    reg [WIDTH-1:0]             dst_data_d;

    assign src_ready_o = ~full;
    assign dst_valid_o = ~empty;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            wptr <= 0;
            wptr_gray <= 0;
            full <= 0;
            src_valid_d <= 0;
        end else begin
            if (src_valid_i && ~full) begin
                mem[wptr] <= src_data_i;
                wptr <= wptr + 1;
                wptr_gray <= wptr_gray + 1;
                if (wptr == DEPTH - 1) begin
                    full <= 1;
                end
            end
            src_valid_d <= src_valid_i;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            rptr <= 0;
            rptr_gray <= 0;
            empty <= 1;
            dst_ready_d <= 0;
            dst_data_d <= 0;
        end else begin
            if (dst_ready_i && ~empty) begin
                dst_data_d <= mem[rptr];
                rptr <= rptr + 1;
                rptr_gray <= rptr_gray + 1;
                if (rptr == DEPTH - 1) begin
                    empty <= 1;
                end
            end
            dst_ready_d <= dst_ready_i;
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            wptr_gray_dst <= 0;
        end else begin
            wptr_gray_dst <= wptr_gray;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            rptr_gray_src <= 0;
        end else begin
            rptr_gray_src <= rptr_gray;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            empty <= 1;
        end else if (dst_ready_i && ~empty) begin
            if (rptr_gray_src == wptr_gray_dst) begin
                empty <= 1;
            end
        end else if (src_valid_d && ~full) begin
            if (rptr_gray_src == wptr_gray_dst) begin
                empty <= 0;
            end
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            full <= 0;
        end else if (src_valid_i && ~full) begin
            if (rptr_gray_src == wptr_gray_dst) begin
                full <= 0;
            end
        end else if (dst_ready_d && ~empty) begin
            if (rptr_gray_src == wptr_gray_dst) begin
                full <= 0;
            end
        end
    end

    always @(posedge dst_clk_i) begin
        dst_data_o <= dst_data_d;
    end

endmodule
