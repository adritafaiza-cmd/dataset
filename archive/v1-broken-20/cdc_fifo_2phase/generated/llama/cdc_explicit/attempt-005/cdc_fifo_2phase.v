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

    reg [WIDTH-1:0]         fifo [2**LOG_DEPTH-1:0];
    reg [LOG_DEPTH-1:0]    wr_ptr;
    reg [LOG_DEPTH-1:0]    rd_ptr;
    reg [LOG_DEPTH-1:0]    wr_ptr_gray;
    reg [LOG_DEPTH-1:0]    rd_ptr_gray;
    reg [LOG_DEPTH:0]      occupancy;
    reg [LOG_DEPTH:0]      occupancy_gray;
    reg [WIDTH-1:0]        dst_data_reg;
    reg                    dst_valid_reg;
    reg                    src_ready_reg;
    reg                    dst_valid_reg_d1;

    assign src_ready_o = src_ready_reg;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            src_ready_reg <= 1'b1;
        end else begin
            if (src_valid_i && src_ready_reg) begin
                fifo[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                wr_ptr_gray <= gray_encode(wr_ptr + 1);
            end
            if (occupancy == 2**LOG_DEPTH - 1) begin
                src_ready_reg <= 1'b0;
            end else begin
                src_ready_reg <= 1'b1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            occupancy <= 0;
            occupancy_gray <= 0;
            dst_data_reg <= 0;
            dst_valid_reg <= 1'b0;
            dst_valid_reg_d1 <= 1'b0;
        end else begin
            if (dst_valid_reg && dst_ready_i) begin
                dst_valid_reg <= 1'b0;
                dst_valid_reg_d1 <= 1'b0;
            end
            if (dst_valid_reg_d1 && !dst_ready_i) begin
                dst_valid_reg <= 1'b1;
            end
            if (occupancy > 0) begin
                if (dst_ready_i && dst_valid_reg) begin
                    dst_data_reg <= fifo[rd_ptr];
                    rd_ptr <= rd_ptr + 1;
                    rd_ptr_gray <= gray_encode(rd_ptr + 1);
                    occupancy <= occupancy - 1;
                    occupancy_gray <= gray_encode(occupancy - 1);
                    dst_valid_reg_d1 <= 1'b1;
                end
            end
            if (occupancy == 0) begin
                dst_valid_reg <= 1'b0;
                dst_valid_reg_d1 <= 1'b0;
            end
        end
    end

    always @(posedge src_clk_i) begin
        occupancy <= occupancy + (src_valid_i && src_ready_reg) - (dst_valid_reg && dst_ready_i);
        occupancy_gray <= gray_encode(occupancy + (src_valid_i && src_ready_reg) - (dst_valid_reg && dst_ready_i));
    end

    function [LOG_DEPTH:0] gray_encode;
        input [LOG_DEPTH:0] bin;
        reg [LOG_DEPTH:0] gray;
        begin
            gray = bin ^ (bin >> 1);
            gray_encode = gray;
        end
    endfunction

endmodule
