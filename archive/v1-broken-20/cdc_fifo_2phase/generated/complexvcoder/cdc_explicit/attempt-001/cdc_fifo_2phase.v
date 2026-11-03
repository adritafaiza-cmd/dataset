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

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [LOG_DEPTH-1:0] wr_ptr, rd_ptr;
    reg full, empty;
    reg [LOG_DEPTH-1:0] wr_ptr_sync, rd_ptr_sync;
    reg full_sync, empty_sync;
    reg [WIDTH-1:0] data_out_sync;

    // FIFO core logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (src_valid_i && src_ready_o && !full) begin
                mem[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == DEPTH - 1) begin
                    wr_ptr <= 0;
                end
                if (wr_ptr == rd_ptr) begin
                    full <= 1;
                end
            end
            if (!dst_valid_o || dst_ready_i) begin
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == DEPTH - 1) begin
                    rd_ptr <= 0;
                end
                if (rd_ptr == wr_ptr) begin
                    empty <= 1;
                end
            end
            if (wr_ptr == rd_ptr) begin
                full <= 0;
                empty <= 1;
            end
        end
    end

    // Source-domain synchronization
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_sync <= 0;
            full_sync <= 0;
        end else begin
            wr_ptr_sync <= wr_ptr;
            full_sync <= full;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ready_o <= 1;
        end else begin
            if (full_sync) begin
                src_ready_o <= 0;
            end else begin
                src_ready_o <= 1;
            end
        end
    end

    // Destination-domain synchronization
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr_sync <= 0;
            data_out_sync <= 0;
            empty_sync <= 1;
        end else begin
            rd_ptr_sync <= rd_ptr;
            data_out_sync <= mem[rd_ptr];
            empty_sync <= empty;
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_data_o <= 0;
            dst_valid_o <= 0;
        end else begin
            if (!empty_sync) begin
                dst_data_o <= data_out_sync;
                dst_valid_o <= 1;
            end else begin
                dst_data_o <= 0;
                dst_valid_o <= 0;
            end
        end
    end

endmodule
