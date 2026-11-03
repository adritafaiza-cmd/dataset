module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Local parameters
    parameter FIFO_DEPTH = 1 << LOG_DEPTH;
    parameter FIFO_SIZE = FIFO_DEPTH + 1;

    // FIFO for source clock domain
    fifo_gray_clearable #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_src (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .clear_i(src_clear_i),
        .clear_pending_o(src_clear_pending_o),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_o)
    );

    // FIFO for destination clock domain
    fifo_gray_clearable #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_dst (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .clear_i(dst_clear_i),
        .clear_pending_o(dst_clear_pending_o),
        .data_i(fifo_src.data_o),
        .valid_i(fifo_src.valid_o),
        .ready_o(fifo_src.ready_i)
    );

    // Destination data output and valid signal
    assign dst_data_o = fifo_dst.data_o;
    assign dst_valid_o = fifo_dst.valid_o;

endmodule

module fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  clear_i,
    output                 clear_pending_o,
    input  [WIDTH-1:0]     data_i,
    input                  valid_i,
    output                 ready_o
);

    // Internal signals
    reg [WIDTH-1:0]         mem [0:FIFO_SIZE-1];
    reg [LOG_DEPTH:0]       wr_ptr;
    reg [LOG_DEPTH:0]       rd_ptr;
    reg                     full;
    reg                     empty;

    // Clear signal handling
    reg                     clear_reg;
    assign clear_pending_o = clear_reg;

    // Clock domain crossing for clear signal
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            clear_reg <= 1'b0;
        end else begin
            clear_reg <= clear_i;
        end
    end

    // FIFO logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 1'b0;
            empty <= 1'b1;
        end else begin
            if (clear_reg) begin
                wr_ptr <= 0;
                rd_ptr <= 0;
                full <= 1'b0;
                empty <= 1'b1;
            end else begin
                if (valid_i && !full) begin
                    mem[wr_ptr] <= data_i;
                    wr_ptr <= wr_ptr + 1;
                    if (wr_ptr == FIFO_SIZE - 1) begin
                        wr_ptr <= 0;
                    end
                    if (wr_ptr == rd_ptr) begin
                        full <= 1'b1;
                    end
                    empty <= 1'b0;
                end
                if (ready_o && !empty) begin
                    rd_ptr <= rd_ptr + 1;
                    if (rd_ptr == FIFO_SIZE - 1) begin
                        rd_ptr <= 0;
                    end
                    if (rd_ptr == wr_ptr) begin
                        empty <= 1'b1;
                    end
                    full <= 1'b0;
                end
            end
        end
    end

    // Ready signal logic
    assign ready_o = !full;

endmodule
