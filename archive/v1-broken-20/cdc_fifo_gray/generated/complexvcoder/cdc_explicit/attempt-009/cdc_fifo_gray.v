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
    logic [WIDTH-1:0]       fifo_data [0:(2**LOG_DEPTH)-1];
    logic [LOG_DEPTH:0]     fifo_wr_ptr;
    logic [LOG_DEPTH:0]     fifo_rd_ptr;
    logic                   fifo_full;
    logic                   fifo_empty;

    // Source clock domain logic
    logic [WIDTH-1:0]       src_data_reg;
    logic                   src_valid_reg;
    logic                   src_ready_reg;

    // Destination clock domain logic
    logic [WIDTH-1:0]       dst_data_reg;
    logic                   dst_valid_reg;
    logic                   dst_ready_reg;

    // FIFO pointers synchronization
    logic [LOG_DEPTH:0]     fifo_wr_ptr_sync [0:SYNC_STAGES-1];
    logic [LOG_DEPTH:0]     fifo_rd_ptr_sync [0:SYNC_STAGES-1];

    // FIFO full and empty flags
    assign fifo_full = (fifo_wr_ptr == fifo_rd_ptr + (1 << LOG_DEPTH));
    assign fifo_empty = (fifo_wr_ptr == fifo_rd_ptr);

    // Source clock domain logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_data_reg <= 0;
            src_valid_reg <= 0;
            src_ready_reg <= 1;
        end else begin
            if (src_valid_i && src_ready_reg && !fifo_full) begin
                fifo_data[fifo_wr_ptr] <= src_data_i;
                fifo_wr_ptr <= fifo_wr_ptr + 1;
            end
            src_ready_reg <= !fifo_full;
        end
    end

    // FIFO pointers synchronization in source clock domain
    generate
        for (genvar i = 0; i < SYNC_STAGES; i++) begin : sync_fifo_wr_ptr
            assign fifo_wr_ptr_sync[i] = fifo_wr_ptr;
        end
    endgenerate

    // Destination clock domain logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
            dst_ready_reg <= 1;
        end else begin
            if (dst_ready_i && !fifo_empty) begin
                dst_data_reg <= fifo_data[fifo_rd_ptr];
                fifo_rd_ptr <= fifo_rd_ptr + 1;
            end
            dst_valid_reg <= !fifo_empty;
        end
    end

    // FIFO pointers synchronization in destination clock domain
    generate
        for (genvar i = 0; i < SYNC_STAGES; i++) begin : sync_fifo_rd_ptr
            assign fifo_rd_ptr_sync[i] = fifo_rd_ptr;
        end
    endgenerate

    // Output logic
    assign src_ready_o = !fifo_full;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
