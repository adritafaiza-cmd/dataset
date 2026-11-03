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

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [WIDTH-1:0] fifo[DEPTH-1:0];
    reg [LOG_DEPTH-1:0] src_ptr, dst_ptr, src_ptr_gray, dst_ptr_gray;
    reg [LOG_DEPTH-1:0] src_ptr_sync, dst_ptr_sync;
    reg [WIDTH-1:0] data_sync;
    reg src_valid_sync, dst_valid_sync;
    reg src_ready_sync, dst_ready_sync;

    // Gray encoding and decoding
    always @(posedge src_clk_i) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
            src_ptr_gray <= 0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                src_ptr <= src_ptr + 1;
                src_ptr_gray <= src_ptr_gray + 1;
            end
            src_ptr_gray <= {src_ptr[LOG_DEPTH-2:0], src_ptr[LOG_DEPTH-1] ^ src_ptr[LOG_DEPTH-2]};
        end
    end

    always @(posedge dst_clk_i) begin
        if (!dst_rst_ni) begin
            dst_ptr <= 0;
            dst_ptr_gray <= 0;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                dst_ptr <= dst_ptr + 1;
                dst_ptr_gray <= dst_ptr_gray + 1;
            end
            dst_ptr_gray <= {dst_ptr[LOG_DEPTH-2:0], dst_ptr[LOG_DEPTH-1] ^ dst_ptr[LOG_DEPTH-2]};
        end
    end

    // Synchronization of source pointer
    always @(posedge dst_clk_i) begin
        if (!dst_rst_ni) begin
            src_ptr_sync <= 0;
        end else begin
            src_ptr_sync <= src_ptr_gray;
        end
    end

    // Synchronization of destination pointer
    always @(posedge src_clk_i) begin
        if (!src_rst_ni) begin
            dst_ptr_sync <= 0;
        end else begin
            dst_ptr_sync <= dst_ptr_gray;
        end
    end

    // Synchronization of data
    always @(posedge dst_clk_i) begin
        if (!dst_rst_ni) begin
            data_sync <= 0;
        end else begin
            data_sync <= fifo[src_ptr_sync];
        end
    end

    // Synchronization of valid and ready signals
    always @(posedge src_clk_i) begin
        if (!src_rst_ni) begin
            src_valid_sync <= 0;
        end else begin
            src_valid_sync <= src_valid_i;
        end
    end

    always @(posedge dst_clk_i) begin
        if (!dst_rst_ni) begin
            dst_valid_sync <= 0;
        end else begin
            dst_valid_sync <= dst_valid_o;
        end
    end

    always @(posedge src_clk_i) begin
        if (!src_rst_ni) begin
            src_ready_sync <= 0;
        end else begin
            src_ready_sync <= src_ready_o;
        end
    end

    always @(posedge dst_clk_i) begin
        if (!dst_rst_ni) begin
            dst_ready_sync <= 0;
        end else begin
            dst_ready_sync <= dst_ready_i;
        end
    end

    // FIFO write
    always @(posedge src_clk_i) begin
        if (!src_rst_ni) begin
            fifo <= 0;
        end else if (src_valid_i && src_ready_o) begin
            fifo[src_ptr] <= src_data_i;
        end
    end

    // FIFO read
    always @(posedge dst_clk_i) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
            dst_valid_o <= 0;
        end else if (dst_ready_i && dst_valid_o) begin
            dst_data_o <= data_sync;
            dst_valid_o <= (dst_ptr != src_ptr_sync);
        end
    end

    // Ready and valid logic
    always @(posedge src_clk_i) begin
        if (!src_rst_ni) begin
            src_ready_o <= 0;
        end else begin
            src_ready_o <= (dst_ptr_sync != src_ptr + 1);
        end
    end

    always @(posedge dst_clk_i) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 0;
        end else begin
            dst_valid_o <= (dst_ptr != src_ptr_sync);
        end
    end

endmodule
