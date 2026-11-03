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
    logic [LOG_DEPTH:0] wr_ptr;
    logic [LOG_DEPTH:0] rd_ptr;
    logic [WIDTH-1:0] memory [0:(1<<LOG_DEPTH)-1];
    logic full_flag;
    logic empty_flag;

    // Clock-domain crossing logic
    logic [LOG_DEPTH:0] wr_ptr_sync;
    logic [LOG_DEPTH:0] rd_ptr_sync;
    logic full_flag_sync;
    logic empty_flag_sync;

    // Syncronize write pointer and full flag to destination clock domain
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_sync <= 0;
            full_flag_sync <= 1'b0;
        end else begin
            wr_ptr_sync <= wr_ptr;
            full_flag_sync <= full_flag;
        end
    end

    // Syncronize read pointer and empty flag to source clock domain
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr_sync <= 0;
            empty_flag_sync <= 1'b1;
        end else begin
            rd_ptr_sync <= rd_ptr;
            empty_flag_sync <= empty_flag;
        end
    end

    // Write pointer and full flag logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            full_flag <= 1'b0;
        end else if (src_valid_i && src_ready_o && !full_flag) begin
            memory[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1;
            if (wr_ptr == (1<<LOG_DEPTH)) begin
                wr_ptr <= 0;
            end
            if (wr_ptr == rd_ptr) begin
                full_flag <= 1'b1;
            end
        end
    end

    // Read pointer and empty flag logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            empty_flag <= 1'b1;
        end else if (dst_ready_i && !empty_flag) begin
            rd_ptr <= rd_ptr + 1;
            if (rd_ptr == (1<<LOG_DEPTH)) begin
                rd_ptr <= 0;
            end
            if (rd_ptr == wr_ptr_sync) begin
                empty_flag <= 1'b1;
            end
        end
    end

    // Assign outputs
    assign src_ready_o = !full_flag;
    assign dst_data_o = memory[rd_ptr_sync];
    assign dst_valid_o = !empty_flag_sync;

endmodule
