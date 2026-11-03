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
    logic [LOG_DEPTH-1:0] src_ptr;
    logic [LOG_DEPTH-1:0] dst_ptr;
    logic [LOG_DEPTH-1:0] wr_ptr;
    logic [LOG_DEPTH-1:0] rd_ptr;
    logic [WIDTH-1:0] fifo [0:(2**LOG_DEPTH)-1];
    logic [LOG_DEPTH-1:0] cnt;
    logic full, empty;

    // Source clock domain
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
            wr_ptr <= 0;
        end else begin
            if (src_valid_i && src_ready_o && !full) begin
                fifo[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
            end
        end
    end

    // Destination clock domain
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    // Synchronization of pointers and data
    logic [LOG_DEPTH-1:0] wr_ptr_sync [0:SYNC_STAGES-1];
    logic [LOG_DEPTH-1:0] rd_ptr_sync [0:SYNC_STAGES-1];
    logic [WIDTH-1:0] data_sync [0:SYNC_STAGES-1];

    generate
        for (genvar i = 0; i < SYNC_STAGES; i++) begin : sync_stages
            always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    wr_ptr_sync[i] <= 0;
                end else begin
                    wr_ptr_sync[i] <= wr_ptr;
                end
            end

            always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    rd_ptr_sync[i] <= 0;
                    data_sync[i] <= 0;
                end else begin
                    if (dst_valid_o && dst_ready_i) begin
                        rd_ptr_sync[i] <= rd_ptr;
                        data_sync[i] <= fifo[rd_ptr];
                    end
                end
            end
        end
    endgenerate

    // Output logic
    assign src_ready_o = ~full;
    assign dst_data_o = data_sync[SYNC_STAGES-1];
    assign dst_valid_o = ~empty;

    // Full and empty flags
    assign full = (wr_ptr_sync[SYNC_STAGES-1] == rd_ptr_sync[SYNC_STAGES-1] + (1 << LOG_DEPTH)) || (wr_ptr_sync[SYNC_STAGES-1] == 0 && rd_ptr_sync[SYNC_STAGES-1] == (1 << LOG_DEPTH) - 1);
    assign empty = (wr_ptr_sync[SYNC_STAGES-1] == rd_ptr_sync[SYNC_STAGES-1]);

endmodule
