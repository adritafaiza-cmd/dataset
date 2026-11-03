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

    localparam FIFO_DEPTH = 2**LOG_DEPTH;

    logic [LOG_DEPTH-1:0] wr_ptr;
    logic [LOG_DEPTH-1:0] rd_ptr;
    logic [WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    logic full;
    logic empty;

    // Write logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            full <= 0;
        end else begin
            if (src_valid_i && src_ready_o && !full) begin
                mem[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == FIFO_DEPTH - 1)
                    full <= 1;
            end
        end
    end

    // Read logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            empty <= 1;
        end else begin
            if (dst_valid_o && dst_ready_i && !empty) begin
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == FIFO_DEPTH - 1)
                    empty <= 0;
            end
        end
    end

    // Full and empty flags
    assign full = (wr_ptr == rd_ptr) && !empty;
    assign empty = (wr_ptr == rd_ptr) && full;

    // Output logic
    assign src_ready_o = !full;
    assign dst_valid_o = !empty;
    assign dst_data_o = mem[rd_ptr];

endmodule
