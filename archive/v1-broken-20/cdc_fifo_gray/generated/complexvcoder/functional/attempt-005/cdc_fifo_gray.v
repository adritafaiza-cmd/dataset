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

    localparam FIFO_DEPTH = 1 << LOG_DEPTH;
    localparam ADDRESS_WIDTH = $clog2(FIFO_DEPTH);

    logic [ADDRESS_WIDTH-1:0] wr_ptr;
    logic [ADDRESS_WIDTH-1:0] rd_ptr;
    logic [WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    logic full;
    logic empty;

    // Source domain logic
    logic src_ready_o_reg;
    logic src_valid_i_reg;
    logic src_data_i_reg;

    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            full <= 0;
            src_ready_o_reg <= 1;
        end else begin
            if (src_valid_i_reg && src_ready_o_reg && !full) begin
                mem[wr_ptr] <= src_data_i_reg;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == FIFO_DEPTH - 1) begin
                    full <= 1;
                end
            end
            src_ready_o_reg <= ~full;
        end
    end

    assign src_valid_i_reg = src_valid_i;
    assign src_data_i_reg = src_data_i;

    // Destination domain logic
    logic dst_valid_o_reg;
    logic dst_ready_i_reg;

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            empty <= 1;
            dst_valid_o_reg <= 0;
        end else begin
            if (dst_ready_i_reg && !empty) begin
                dst_data_o <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == FIFO_DEPTH - 1) begin
                    empty <= 1;
                end
            end
            dst_valid_o_reg <= ~empty;
        end
    end

    assign dst_ready_i_reg = dst_ready_i;
    assign dst_valid_o = dst_valid_o_reg;

endmodule
