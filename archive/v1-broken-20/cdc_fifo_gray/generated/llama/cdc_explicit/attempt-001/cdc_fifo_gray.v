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

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [WIDTH-1:0] fifo [DEPTH-1:0];
    reg [LOG_DEPTH-1:0] src_ptr;
    reg [LOG_DEPTH-1:0] dst_ptr;
    reg [LOG_DEPTH-1:0] src_ptr_gray;
    reg [LOG_DEPTH-1:0] dst_ptr_gray;
    reg [LOG_DEPTH-1:0] src_ptr_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0] dst_ptr_sync [SYNC_STAGES-1:0];
    reg [WIDTH-1:0] data_sync [SYNC_STAGES-1:0];
    reg src_empty;
    reg src_full;
    reg dst_empty;
    reg dst_full;
    reg src_ready;
    reg dst_valid;

    // Gray encoding
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr_gray <= 0;
        end else begin
            src_ptr_gray <= src_ptr_gray ^ (src_ptr + 1);
        end
    end

    // Synchronize src_ptr_gray to dst_clk_i
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ptr_sync[0] <= 0;
        end else begin
            src_ptr_sync[0] <= src_ptr_gray;
        end
    end

    generate
        for (genvar i = 1; i < SYNC_STAGES; i++) begin
            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    src_ptr_sync[i] <= 0;
                end else begin
                    src_ptr_sync[i] <= src_ptr_sync[i-1];
                end
            end
        end
    endgenerate

    // Synchronize data to dst_clk_i
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            data_sync[0] <= 0;
        end else if (src_valid_i && src_ready) begin
            data_sync[0] <= src_data_i;
        end
    end

    generate
        for (genvar i = 1; i < SYNC_STAGES; i++) begin
            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    data_sync[i] <= 0;
                end else begin
                    data_sync[i] <= data_sync[i-1];
                end
            end
        end
    endgenerate

    // FIFO control
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= 0;
            src_empty <= 1;
            src_full <= 0;
            src_ready <= 1;
        end else begin
            if (src_valid_i && src_ready) begin
                fifo[src_ptr] <= src_data_i;
                src_ptr <= src_ptr + 1;
                if (src_ptr == DEPTH - 1) begin
                    src_ptr <= 0;
                end
                src_empty <= 0;
                if (src_ptr == dst_ptr) begin
                    src_full <= 1;
                    src_ready <= 0;
                end
            end else if (src_ptr == dst_ptr) begin
                src_empty <= 1;
            end
            if (dst_ptr != src_ptr) begin
                src_full <= 0;
                src_ready <= 1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= 0;
            dst_empty <= 1;
            dst_full <= 0;
            dst_valid <= 0;
        end else begin
            if (dst_ready_i && !dst_empty) begin
                dst_data_o <= fifo[dst_ptr];
                dst_ptr <= dst_ptr + 1;
                if (dst_ptr == DEPTH - 1) begin
                    dst_ptr <= 0;
                end
                dst_empty <= 0;
                if (dst_ptr == src_ptr) begin
                    dst_full <= 1;
                    dst_valid <= 0;
                end
            end else if (dst_ptr == src_ptr) begin
                dst_empty <= 1;
            end
            if (src_ptr != dst_ptr) begin
                dst_full <= 0;
                dst_valid <= 1;
            end
        end
    end

    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;

    // Gray decoding
    always @(posedge dst_clk_i) begin
        dst_ptr_gray <= src_ptr_sync[SYNC_STAGES-1] ^ dst_ptr;
    end

endmodule
