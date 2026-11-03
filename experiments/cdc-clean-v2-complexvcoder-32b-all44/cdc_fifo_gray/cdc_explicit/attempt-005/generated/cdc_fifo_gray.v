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

    // Internal signals
    reg [LOG_DEPTH:0] src_wr_ptr_gray, src_wr_ptr_bin;
    reg [LOG_DEPTH:0] src_wr_ptr_gray_sync, src_wr_ptr_bin_sync;
    reg [LOG_DEPTH:0] dst_rd_ptr_gray, dst_rd_ptr_bin;
    reg [LOG_DEPTH:0] dst_rd_ptr_gray_sync, dst_rd_ptr_bin_sync;
    reg [WIDTH-1:0] fifo_mem [2**LOG_DEPTH-1:0];
    reg               src_ready, dst_valid;
    reg [WIDTH-1:0] dst_data, dst_data_reg1, dst_data_reg2;

    // Source-domain Gray counter
    gray_counter src_gray_counter (
        .clk  (src_clk_i),
        .rst_ni (src_rst_ni),
        .gray (src_wr_ptr_gray),
        .bin  (src_wr_ptr_bin)
    );

    // Source-domain Gray counter synchronization
    gray_counter src_gray_counter_gray_sync (
        .clk  (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .gray (src_wr_ptr_gray_sync),
        .bin  (src_wr_ptr_bin_sync)
    );

    // Destination-domain Gray counter
    gray_counter dst_gray_counter (
        .clk  (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .gray (dst_rd_ptr_gray),
        .bin  (dst_rd_ptr_bin)
    );

    // Destination-domain Gray counter synchronization
    gray_counter dst_gray_counter_gray_sync (
        .clk  (src_clk_i),
        .rst_ni (src_rst_ni),
        .gray (dst_rd_ptr_gray_sync),
        .bin  (dst_rd_ptr_bin_sync)
    );

    // Write pointer synchronization
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_sync <= 0;
        end else begin
            src_wr_ptr_gray_sync <= src_wr_ptr_gray;
        end
    end

    // Read pointer synchronization
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_sync <= 0;
        end else begin
            dst_rd_ptr_gray_sync <= dst_rd_ptr_gray;
        end
    end

    // FIFO write logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr_gray <= 0;
        end else if (src_valid_i && src_ready) begin
            fifo_mem[src_wr_ptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
            src_wr_ptr_gray <= src_wr_ptr_gray + 1;
        end
    end

    // FIFO read logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr_gray <= 0;
            dst_data_reg1 <= 0;
            dst_data_reg2 <= 0;
        end else if (dst_valid && dst_ready_i) begin
            dst_rd_ptr_gray <= dst_rd_ptr_gray + 1;
            dst_data_reg1 <= fifo_mem[dst_rd_ptr_bin[LOG_DEPTH-1:0]];
            dst_data_reg2 <= dst_data_reg1;
        end
    end

    // Source ready signal
    assign src_ready = (src_wr_ptr_bin_sync != {src_wr_ptr_bin[LOG_DEPTH], ~src_wr_ptr_bin[LOG_DEPTH-1:0]});

    // Destination valid signal
    assign dst_valid = (dst_rd_ptr_bin_sync != {dst_rd_ptr_bin[LOG_DEPTH], ~dst_rd_ptr_bin[LOG_DEPTH-1:0]});

    // Destination data output
    assign dst_data_o = dst_data_reg2;

    // Destination valid output
    assign dst_valid_o = dst_valid;

    // Source ready output
    assign src_ready_o = src_ready;

endmodule

module gray_counter (
    input clk,
    input rst_ni,
    output reg [LOG_DEPTH:0] gray,
    output reg [LOG_DEPTH:0] bin
);

    // Internal signals
    reg [LOG_DEPTH:0] counter;

    // Binary counter
    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

    // Gray code conversion
    assign gray = (counter >> 1) ^ counter;

    // Binary output
    assign bin = counter;

endmodule
