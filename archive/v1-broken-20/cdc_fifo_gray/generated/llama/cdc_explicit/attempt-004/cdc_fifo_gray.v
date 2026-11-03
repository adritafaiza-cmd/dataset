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

    // FIFO depth
    localparam DEPTH = 1 << LOG_DEPTH;

    // Gray counter width
    localparam CTR_WIDTH = LOG_DEPTH + 1;

    // Source domain signals
    reg [WIDTH-1:0] src_data[DEPTH-1:0];
    reg [CTR_WIDTH-1:0] src_wr_ptr;
    reg [CTR_WIDTH-1:0] src_rd_ptr;
    reg [WIDTH-1:0] src_data_out;
    reg src_empty;
    reg src_full;
    reg src_ready;

    // Destination domain signals
    reg [WIDTH-1:0] dst_data_out;
    reg dst_valid;
    reg [CTR_WIDTH-1:0] dst_wr_ptr;
    reg [CTR_WIDTH-1:0] dst_rd_ptr;

    // Synchronization signals
    reg [SYNC_STAGES-1:0] src_valid_sync;
    reg [SYNC_STAGES-1:0] dst_ready_sync;
    reg [SYNC_STAGES-1:0] src_empty_sync;
    reg [SYNC_STAGES-1:0] src_full_sync;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            src_wr_ptr <= 0;
            src_rd_ptr <= 0;
            src_empty <= 1;
            src_full <= 0;
            src_ready <= 1;
            src_data_out <= 0;
        end else begin
            if (src_valid_i && src_ready) begin
                src_data[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1;
                if (src_wr_ptr == DEPTH - 1) begin
                    src_full <= 1;
                end else begin
                    src_full <= 0;
                end
            end
            if (src_empty_sync[SYNC_STAGES-1] && dst_ready_sync[SYNC_STAGES-1]) begin
                src_data_out <= src_data[src_rd_ptr[LOG_DEPTH-1:0]];
                src_rd_ptr <= src_rd_ptr + 1;
                if (src_rd_ptr == DEPTH - 1) begin
                    src_empty <= 1;
                end else begin
                    src_empty <= 0;
                end
            end
            src_ready <= ~src_full;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            dst_wr_ptr <= 0;
            dst_rd_ptr <= 0;
            dst_valid <= 0;
            dst_data_out <= 0;
        end else begin
            if (src_valid_sync[SYNC_STAGES-1] && dst_ready_i) begin
                dst_data_out <= src_data_out;
                dst_wr_ptr <= dst_wr_ptr + 1;
                dst_valid <= 1;
            end
            if (dst_ready_i && dst_valid) begin
                dst_valid <= 0;
                dst_rd_ptr <= dst_rd_ptr + 1;
            end
        end
    end

    // Synchronization logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            src_valid_sync <= 0;
            src_empty_sync <= 0;
            src_full_sync <= 0;
        end else begin
            src_valid_sync[0] <= src_valid_i;
            src_empty_sync[0] <= src_empty;
            src_full_sync[0] <= src_full;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                src_valid_sync[i] <= src_valid_sync[i-1];
                src_empty_sync[i] <= src_empty_sync[i-1];
                src_full_sync[i] <= src_full_sync[i-1];
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            dst_ready_sync <= 0;
        end else begin
            dst_ready_sync[0] <= dst_ready_i;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                dst_ready_sync[i] <= dst_ready_sync[i-1];
            end
        end
    end

    assign src_ready_o = src_ready;
    assign dst_data_o = dst_data_out;
    assign dst_valid_o = dst_valid;

endmodule
