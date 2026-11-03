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
    reg [LOG_DEPTH-1:0]    wr_ptr_gray_sync;
    reg [LOG_DEPTH-1:0]    rd_ptr_gray_sync;
    reg [WIDTH-1:0]        dst_data_reg;
    reg                    dst_valid_reg;
    reg                    src_ready_reg;
    reg                    full;
    reg                    empty;

    assign src_ready_o = src_ready_reg;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            wr_ptr <= 0;
            src_ready_reg <= 1'b1;
            full <= 1'b0;
        end else begin
            if (src_valid_i && src_ready_reg) begin
                fifo[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == (2**LOG_DEPTH - 1)) begin
                    full <= 1'b1;
                end else begin
                    full <= 1'b0;
                end
            end
            if (full) begin
                src_ready_reg <= 1'b0;
            end else begin
                src_ready_reg <= 1'b1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            rd_ptr <= 0;
            dst_valid_reg <= 1'b0;
            empty <= 1'b1;
            dst_data_reg <= 0;
        end else begin
            if (dst_valid_reg && dst_ready_i) begin
                dst_valid_reg <= 1'b0;
                if (empty) begin
                    dst_valid_reg <= 1'b0;
                end else begin
                    dst_data_reg <= fifo[rd_ptr];
                    rd_ptr <= rd_ptr + 1;
                    if (rd_ptr == (2**LOG_DEPTH - 1)) begin
                        empty <= 1'b1;
                    end else begin
                        empty <= 1'b0;
                    end
                end
            end
            if (~empty) begin
                dst_valid_reg <= 1'b1;
            end
        end
    end

    // Gray encoding
    always @(posedge src_clk_i) begin
        wr_ptr_gray <= {wr_ptr[LOG_DEPTH-1], wr_ptr[LOG_DEPTH-2:0]};
    end

    // Synchronize wr_ptr_gray to destination clock domain
    always @(posedge dst_clk_i) begin
        wr_ptr_gray_sync <= wr_ptr_gray;
    end

    // Gray decoding
    always @(posedge dst_clk_i) begin
        rd_ptr <= {wr_ptr_gray_sync[LOG_DEPTH-2:0], 1'b0};
    end

    // Empty detection
    always @(posedge dst_clk_i) begin
        if (rd_ptr == wr_ptr_gray_sync) begin
            empty <= 1'b1;
        end else begin
            empty <= 1'b0;
        end
    end

endmodule
