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

    // FIFO core parameters
    parameter DEPTH = 1 << LOG_DEPTH;
    parameter ADDR_WIDTH = LOG_DEPTH;

    // Internal signals
    reg [WIDTH-1:0] fifo [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    reg [ADDR_WIDTH:0] count;

    // FIFO sync signals
    reg [WIDTH-1:0] src_sync_data;
    reg src_sync_valid;
    wire dst_sync_valid;
    wire dst_sync_ready;

    // Synchronizers
    fifo_sync #(.WIDTH(WIDTH)) src_fifo_sync (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .data_i(src_data_i),
        .valid_i(src_valid_i),
        .ready_o(src_ready_o)
    );

    fifo_sync #(.WIDTH(WIDTH)) dst_fifo_sync (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .data_i(fifo[rd_ptr]),
        .valid_i(count > 0),
        .ready_o(dst_sync_ready)
    );

    // FIFO core
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            if (src_valid_i && src_ready_o && count < DEPTH) begin
                fifo[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
            if (dst_sync_ready && count > 0) begin
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
        end
    end

    // Assign outputs
    assign dst_data_o = fifo[rd_ptr];
    assign dst_valid_o = dst_sync_valid && dst_sync_ready;

endmodule

module fifo_sync #(
    parameter WIDTH = 8
)(
    input                  rst_ni,
    input                  clk_i,
    input  [WIDTH-1:0]     data_i,
    input                  valid_i,
    output                 ready_o
);

    reg [WIDTH-1:0] shift_reg;
    reg valid_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            shift_reg <= 0;
            valid_reg <= 0;
            ready_o <= 0;
        end else begin
            shift_reg <= data_i;
            valid_reg <= valid_i;
            ready_o <= valid_reg;
        end
    end

endmodule
