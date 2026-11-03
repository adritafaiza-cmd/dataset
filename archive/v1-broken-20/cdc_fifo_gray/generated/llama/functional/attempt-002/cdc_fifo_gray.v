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

    // FIFO parameters
    localparam DEPTH = 1 << LOG_DEPTH;

    // Gray counters
    reg [LOG_DEPTH-1:0] src_gray_counter;
    reg [LOG_DEPTH-1:0] dst_gray_counter;
    reg [LOG_DEPTH-1:0] src_gray_counter_sync;
    reg [LOG_DEPTH-1:0] dst_gray_counter_sync;

    // FIFO data
    reg [WIDTH-1:0] fifo_data [DEPTH-1:0];

    // FIFO control
    reg src_empty;
    reg src_full;
    reg dst_empty;
    reg dst_full;

    // Synchronization signals
    reg [SYNC_STAGES-1:0] src_valid_sync;
    reg [SYNC_STAGES-1:0] dst_ready_sync;

    // Output registers
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // Source clock domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_counter <= 0;
            src_valid_sync <= 0;
            src_empty <= 1;
            src_full <= 0;
        end else begin
            // Update source gray counter
            if (src_valid_i && src_ready_o) begin
                src_gray_counter <= src_gray_counter + 1;
            end

            // Update source valid synchronization
            src_valid_sync[0] <= src_valid_i;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                src_valid_sync[i] <= src_valid_sync[i-1];
            end

            // Update source empty and full flags
            if (src_valid_i && src_ready_o) begin
                if (src_gray_counter == DEPTH - 1) begin
                    src_full <= 1;
                end else begin
                    src_full <= 0;
                end
            end
            if (!src_valid_i || !src_ready_o) begin
                if (src_gray_counter == 0) begin
                    src_empty <= 1;
                end else begin
                    src_empty <= 0;
                end
            end
        end
    end

    // Destination clock domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_counter <= 0;
            dst_ready_sync <= 0;
            dst_empty <= 1;
            dst_full <= 0;
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
        end else begin
            // Update destination gray counter
            if (dst_ready_i && dst_valid_o) begin
                dst_gray_counter <= dst_gray_counter + 1;
            end

            // Update destination ready synchronization
            dst_ready_sync[0] <= dst_ready_i;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                dst_ready_sync[i] <= dst_ready_sync[i-1];
            end

            // Update destination empty and full flags
            if (dst_ready_i && dst_valid_o) begin
                if (dst_gray_counter == DEPTH - 1) begin
                    dst_full <= 1;
                end else begin
                    dst_full <= 0;
                end
            end
            if (!dst_ready_i || !dst_valid_o) begin
                if (dst_gray_counter == 0) begin
                    dst_empty <= 1;
                end else begin
                    dst_empty <= 0;
                end
            end

            // Update output registers
            if (dst_ready_i && dst_valid_o) begin
                dst_data_reg <= fifo_data[dst_gray_counter];
                dst_valid_reg <= 1;
            end else begin
                dst_valid_reg <= 0;
            end
        end
    end

    // Synchronize gray counters
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_counter_sync <= 0;
        end else begin
            src_gray_counter_sync <= src_gray_counter;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_counter_sync <= 0;
        end else begin
            dst_gray_counter_sync <= dst_gray_counter;
        end
    end

    // FIFO data write
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o) begin
            fifo_data[src_gray_counter] <= src_data_i;
        end
    end

    // Assign output signals
    assign src_ready_o = !src_full && dst_empty;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
