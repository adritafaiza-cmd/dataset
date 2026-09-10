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

    reg [WIDTH-1:0] fifo [DEPTH-1:0];
    reg [LOG_DEPTH-1:0] wr_ptr, rd_ptr;
    reg [LOG_DEPTH-1:0] wr_ptr_gray, rd_ptr_gray;
    reg [LOG_DEPTH-1:0] wr_ptr_sync, rd_ptr_sync;
    reg [WIDTH-1:0] data_sync;
    reg src_valid_sync, dst_valid_sync;
    reg src_ready_sync, dst_ready_sync;
    reg full, empty;

    // Source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            src_ready_o <= 1'b1;
            full <= 1'b0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                fifo[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                wr_ptr_gray <= wr_ptr_gray + 1;
                if (wr_ptr == DEPTH - 1) begin
                    full <= 1'b1;
                end else begin
                    full <= 1'b0;
                end
            end
            if (full) begin
                src_ready_o <= 1'b0;
            end else begin
                src_ready_o <= 1'b1;
            end
        end
    end

    // Gray code conversion
    always @(posedge src_clk_i) begin
        wr_ptr_gray <= {wr_ptr[LOG_DEPTH-1], wr_ptr[LOG_DEPTH-2:0]};
    end

    // Synchronization to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_sync <= 0;
            data_sync <= 0;
            src_valid_sync <= 1'b0;
        end else begin
            wr_ptr_sync <= wr_ptr_gray;
            data_sync <= fifo[wr_ptr_sync];
            src_valid_sync <= src_valid_i;
        end
    end

    // Destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            dst_valid_o <= 1'b0;
            empty <= 1'b1;
        end else begin
            if (dst_ready_i && dst_valid_o) begin
                rd_ptr <= rd_ptr + 1;
                rd_ptr_gray <= rd_ptr_gray + 1;
                if (rd_ptr == DEPTH - 1) begin
                    empty <= 1'b1;
                end else begin
                    empty <= 1'b0;
                end
            end
            if (src_valid_sync && !empty) begin
                dst_data_o <= data_sync;
                dst_valid_o <= 1'b1;
            end else begin
                dst_valid_o <= 1'b0;
            end
        end
    end

    // Gray code conversion
    always @(posedge dst_clk_i) begin
        rd_ptr_gray <= {rd_ptr[LOG_DEPTH-1], rd_ptr[LOG_DEPTH-2:0]};
    end

    // Synchronization to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr_sync <= 0;
            dst_valid_sync <= 1'b0;
            dst_ready_sync <= 1'b0;
        end else begin
            rd_ptr_sync <= rd_ptr_gray;
            dst_valid_sync <= dst_valid_o;
            dst_ready_sync <= dst_ready_i;
        end
    end

endmodule
