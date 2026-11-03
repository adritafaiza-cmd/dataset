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
    reg [LOG_DEPTH-1:0] head;
    reg [LOG_DEPTH-1:0] tail;
    reg [LOG_DEPTH:0] count;
    reg [WIDTH-1:0] mem [0:2**LOG_DEPTH-1];
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg src_ready_reg;

    // Synchronization registers
    reg src_valid_sync;
    reg src_ready_sync;
    reg dst_valid_sync;
    reg dst_ready_sync;

    // CDC synchronization logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_sync <= 0;
            src_ready_sync <= 0;
        end else begin
            src_valid_sync <= src_valid_i;
            src_ready_sync <= src_ready_o;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_sync <= 0;
            dst_ready_sync <= 0;
        end else begin
            dst_valid_sync <= dst_valid_i;
            dst_ready_sync <= dst_ready_o;
        end
    end

    // FIFO core logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            head <= 0;
            tail <= 0;
            count <= 0;
            src_ready_reg <= 1;
        end else begin
            if (src_valid_sync && src_ready_sync && count < 2**LOG_DEPTH) begin
                mem[head] <= src_data_i;
                head <= head + 1;
                count <= count + 1;
                src_ready_reg <= count < 2**LOG_DEPTH;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
        end else begin
            if (dst_valid_sync && dst_ready_sync && count > 0) begin
                dst_data_reg <= mem[tail];
                tail <= tail + 1;
                count <= count - 1;
                dst_valid_reg <= count > 0;
            end
        end
    end

    // Output logic
    assign src_ready_o = src_ready_reg;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
