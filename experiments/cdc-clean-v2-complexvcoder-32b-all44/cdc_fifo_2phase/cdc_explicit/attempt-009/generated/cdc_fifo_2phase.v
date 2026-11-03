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

    // Internal signals
    reg [WIDTH-1:0]        fifo [0:(2**LOG_DEPTH)-1];
    reg [$clog2(2**LOG_DEPTH):0] src_wr_ptr, src_wr_ptr_gray, src_wr_ptr_gray_sync;
    reg [$clog2(2**LOG_DEPTH):0] dst_rd_ptr, dst_rd_ptr_gray, dst_rd_ptr_gray_sync;
    reg [$clog2(2**LOG_DEPTH):0] dst_wr_ptr_gray_sync;
    reg [$clog2(2**LOG_DEPTH):0] dst_wr_ptr_gray_sync2;
    reg [WIDTH-1:0]        dst_data_sync1;
    reg [WIDTH-1:0]        dst_data_sync2;
    reg                    fifo_full, fifo_empty;
    reg                    src_ready;
    reg                    dst_valid;

    // Gray code conversion functions
    function [$clog2(2**LOG_DEPTH):0] bin_to_gray;
        input [$clog2(2**LOG_DEPTH):0] bin;
        bin_to_gray = (bin >> 1) ^ bin;
    endfunction

    function [$clog2(2**LOG_DEPTH):0] gray_to_bin;
        input [$clog2(2**LOG_DEPTH):0] gray;
        integer i;
        reg [$clog2(2**LOG_DEPTH):0] bin;
        bin = gray;
        for (i = $clog2(2**LOG_DEPTH) - 1; i >= 0; i = i - 1) begin
            bin[i] = bin[i + 1] ^ gray[i];
        end
        gray_to_bin = bin;
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_wr_ptr_gray <= 0;
        end else if (src_valid_i && src_ready) begin
            fifo[src_wr_ptr] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1;
            src_wr_ptr_gray <= bin_to_gray(src_wr_ptr + 1);
        end
    end

    // Synchronize write pointer to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_sync <= 0;
        end else begin
            src_wr_ptr_gray_sync <= src_wr_ptr_gray;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_rd_ptr_gray <= 0;
            dst_wr_ptr_gray_sync <= 0;
            dst_wr_ptr_gray_sync2 <= 0;
            fifo_empty <= 1;
            fifo_full <= 0;
        end else begin
            // Update write pointer synchronizations
            dst_wr_ptr_gray_sync <= src_wr_ptr_gray_sync;
            dst_wr_ptr_gray_sync2 <= dst_wr_ptr_gray_sync;

            // Update read pointer
            if (dst_valid && dst_ready_i) begin
                dst_rd_ptr <= dst_rd_ptr + 1;
                dst_rd_ptr_gray <= bin_to_gray(dst_rd_ptr + 1);
            end

            // Update FIFO status
            fifo_empty <= (dst_wr_ptr_gray_sync2 == dst_rd_ptr_gray);
            fifo_full <= (bin_to_gray(dst_rd_ptr + (2**LOG_DEPTH)) == dst_wr_ptr_gray_sync2);

            // Data synchronization
            if (dst_valid) begin
                dst_data_sync1 <= fifo[gray_to_bin(dst_rd_ptr_gray)];
                dst_data_sync2 <= dst_data_sync1;
            end
        end
    end

    // Output assignments
    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;
    assign dst_data_o = dst_data_sync2;

    // FIFO control logic
    always @(*) begin
        src_ready = ~fifo_full;
        dst_valid = ~fifo_empty;
    end

endmodule
