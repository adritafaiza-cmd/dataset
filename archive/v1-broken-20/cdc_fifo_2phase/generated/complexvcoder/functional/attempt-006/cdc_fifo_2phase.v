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

    localparam FIFO_DEPTH = 1 << LOG_DEPTH;

    reg [WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
    reg [LOG_DEPTH:0] wr_ptr, rd_ptr;
    reg [LOG_DEPTH:0] wr_en, rd_en;
    reg [LOG_DEPTH:0] full, empty;

    // Synchronous FIFO logic in src_clk_i domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (src_valid_i && src_ready_o && !full) begin
                fifo[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == FIFO_DEPTH) begin
                    wr_ptr <= 0;
                end
                full <= (wr_ptr == rd_ptr);
                empty <= 0;
            end else if (dst_valid_o && dst_ready_i && !empty) begin
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == FIFO_DEPTH) begin
                    rd_ptr <= 0;
                end
                full <= 0;
                empty <= (wr_ptr == rd_ptr);
            end
        end
    end

    // Synchronous FIFO ready signal
    assign src_ready_o = !full;

    // Cross-Clk Domain Synchronization logic
    reg src_ready_o_sync;
    reg dst_ready_i_sync;
    reg dst_valid_o_sync;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o_sync <= 0;
        end else begin
            src_ready_o_sync <= src_ready_o;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ready_i_sync <= 0;
        end else begin
            dst_ready_i_sync <= dst_ready_i;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o_sync <= 0;
        end else begin
            if (dst_ready_i_sync && !empty) begin
                dst_valid_o_sync <= 1;
            end else begin
                dst_valid_o_sync <= 0;
            end
        end
    end

    // Destination data output
    assign dst_data_o = fifo[rd_ptr];

    // Destination valid output
    assign dst_valid_o = dst_valid_o_sync;

endmodule
