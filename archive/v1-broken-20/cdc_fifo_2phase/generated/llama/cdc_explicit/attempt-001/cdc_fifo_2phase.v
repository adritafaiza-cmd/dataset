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

    // Gray code counters
    reg [LOG_DEPTH:0] src_gray_counter;
    reg [LOG_DEPTH:0] dst_gray_counter;
    reg [LOG_DEPTH:0] src_bin_counter;
    reg [LOG_DEPTH:0] dst_bin_counter;

    // FIFO memory
    reg [WIDTH-1:0] fifo_mem [2**LOG_DEPTH-1:0];

    // FIFO control signals
    reg src_full;
    reg dst_empty;
    reg src_almost_full;
    reg dst_almost_empty;

    // CDC handshake signals
    reg src_handshake;
    reg dst_handshake;

    // Registered source and destination data
    reg [WIDTH-1:0] src_data_reg;
    reg [WIDTH-1:0] dst_data_reg;

    // Registered source and destination valid signals
    reg src_valid_reg;
    reg dst_valid_reg;

    // Registered source and destination ready signals
    reg src_ready_reg;
    reg dst_ready_reg;

    // Reset logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_counter <= 0;
            src_bin_counter <= 0;
            src_full <= 0;
            src_almost_full <= 0;
            src_handshake <= 0;
            src_data_reg <= 0;
            src_valid_reg <= 0;
            src_ready_reg <= 1;
        end else begin
            // Update source gray counter
            if (src_valid_i && src_ready_reg) begin
                src_gray_counter <= src_gray_counter + 1;
            end

            // Update source binary counter
            if (src_valid_i && src_ready_reg) begin
                src_bin_counter <= src_bin_counter + 1;
            end

            // Update source full and almost full signals
            if (src_bin_counter == (2**LOG_DEPTH - 1)) begin
                src_full <= 1;
            end else begin
                src_full <= 0;
            end

            if (src_bin_counter == (2**LOG_DEPTH - 2)) begin
                src_almost_full <= 1;
            end else begin
                src_almost_full <= 0;
            end

            // Update source handshake signal
            if (src_valid_i && src_ready_reg) begin
                src_handshake <= 1;
            end else begin
                src_handshake <= 0;
            end

            // Update source registered data
            if (src_valid_i && src_ready_reg) begin
                src_data_reg <= src_data_i;
            end

            // Update source registered valid signal
            if (src_valid_i && src_ready_reg) begin
                src_valid_reg <= 1;
            end else begin
                src_valid_reg <= 0;
            end

            // Update source registered ready signal
            if (src_full) begin
                src_ready_reg <= 0;
            end else begin
                src_ready_reg <= 1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_counter <= 0;
            dst_bin_counter <= 0;
            dst_empty <= 1;
            dst_almost_empty <= 1;
            dst_handshake <= 0;
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
            dst_ready_reg <= 1;
        end else begin
            // Update destination gray counter
            if (dst_valid_reg && dst_ready_i) begin
                dst_gray_counter <= dst_gray_counter + 1;
            end

            // Update destination binary counter
            if (dst_valid_reg && dst_ready_i) begin
                dst_bin_counter <= dst_bin_counter + 1;
            end

            // Update destination empty and almost empty signals
            if (dst_bin_counter == 0) begin
                dst_empty <= 1;
            end else begin
                dst_empty <= 0;
            end

            if (dst_bin_counter == 1) begin
                dst_almost_empty <= 1;
            end else begin
                dst_almost_empty <= 0;
            end

            // Update destination handshake signal
            if (dst_valid_reg && dst_ready_i) begin
                dst_handshake <= 1;
            end else begin
                dst_handshake <= 0;
            end

            // Update destination registered data
            if (dst_valid_reg && dst_ready_i) begin
                dst_data_reg <= fifo_mem[dst_bin_counter - 1];
            end

            // Update destination registered valid signal
            if (dst_valid_reg && dst_ready_i) begin
                dst_valid_reg <= 0;
            end else if (!dst_empty) begin
                dst_valid_reg <= 1;
            end else begin
                dst_valid_reg <= 0;
            end

            // Update destination registered ready signal
            if (dst_almost_empty) begin
                dst_ready_reg <= 0;
            end else begin
                dst_ready_reg <= 1;
            end
        end
    end

    // CDC synchronization logic
    reg src_sync1;
    reg src_sync2;
    reg dst_sync1;
    reg dst_sync2;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_sync1 <= 0;
            src_sync2 <= 0;
        end else begin
            src_sync1 <= dst_valid_reg;
            src_sync2 <= src_sync1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_sync1 <= 0;
            dst_sync2 <= 0;
        end else begin
            dst_sync1 <= src_valid_reg;
            dst_sync2 <= dst_sync1;
        end
    end

    // FIFO write logic
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_reg) begin
            fifo_mem[src_bin_counter] <= src_data_i;
        end
    end

    // FIFO read logic
    always @(posedge dst_clk_i) begin
        if (dst_valid_reg && dst_ready_i) begin
            dst_data_o <= fifo_mem[dst_bin_counter - 1];
        end
    end

    // Output assignments
    assign src_ready_o = src_ready_reg;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
