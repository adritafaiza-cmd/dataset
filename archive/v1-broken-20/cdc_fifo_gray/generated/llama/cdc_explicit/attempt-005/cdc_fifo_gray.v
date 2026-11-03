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

    reg [WIDTH-1:0]                  mem [DEPTH-1:0];
    reg [LOG_DEPTH-1:0]              src_ptr;
    reg [LOG_DEPTH-1:0]              dst_ptr;
    reg [LOG_DEPTH-1:0]              src_ptr_gray;
    reg [LOG_DEPTH-1:0]              dst_ptr_gray;
    reg [LOG_DEPTH-1:0]              src_ptr_sync [SYNC_STAGES-1:0];
    reg [LOG_DEPTH-1:0]              dst_ptr_sync [SYNC_STAGES-1:0];
    reg [WIDTH-1:0]                  data_sync [SYNC_STAGES-1:0];
    reg                              src_empty;
    reg                              dst_full;
    reg                              src_ready;
    reg                              dst_valid;

    // Gray encoding
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr_gray <= '0;
        end else begin
            src_ptr_gray <= src_ptr_gray ^ (src_ptr + 1);
        end
    end

    // Synchronize src_ptr_gray to dst_clk_i
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ptr_sync <= '{default: '0};
        end else begin
            src_ptr_sync[0] <= src_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                src_ptr_sync[i] <= src_ptr_sync[i-1];
            end
        end
    end

    // Decode synchronized src_ptr
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= '0;
        end else begin
            dst_ptr <= src_ptr_sync[SYNC_STAGES-1] ^ (dst_ptr + 1);
        end
    end

    // Gray decoding
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr_gray <= '0;
        end else begin
            dst_ptr_gray <= dst_ptr_gray ^ (dst_ptr + 1);
        end
    end

    // Synchronize dst_ptr_gray to src_clk_i
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ptr_sync <= '{default: '0};
        end else begin
            dst_ptr_sync[0] <= dst_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                dst_ptr_sync[i] <= dst_ptr_sync[i-1];
            end
        end
    end

    // Decode synchronized dst_ptr
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= '0;
        end else begin
            src_ptr <= dst_ptr_sync[SYNC_STAGES-1] ^ (src_ptr + 1);
        end
    end

    // Write data
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            mem <= '{default: '0};
        end else if (src_valid_i && src_ready) begin
            mem[src_ptr] <= src_data_i;
        end
    end

    // Synchronize data
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            data_sync <= '{default: '0};
        end else begin
            data_sync[0] <= mem[dst_ptr];
            for (int i = 1; i < SYNC_STAGES; i++) begin
                data_sync[i] <= data_sync[i-1];
            end
        end
    end

    // Read data
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= '0;
        end else if (dst_valid) begin
            dst_data_o <= data_sync[SYNC_STAGES-1];
        end
    end

    // Empty and full flags
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_empty <= 1'b1;
        end else if (src_valid_i && src_ready) begin
            src_empty <= 1'b0;
        end else if (dst_valid && !dst_ready_i) begin
            src_empty <= 1'b1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_full <= 1'b0;
        end else if (dst_valid && !dst_ready_i) begin
            dst_full <= 1'b1;
        end else if (src_valid_i && src_ready) begin
            dst_full <= 1'b0;
        end
    end

    // Ready and valid signals
    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready <= 1'b0;
        end else if (src_empty) begin
            src_ready <= 1'b1;
        end else if (dst_full) begin
            src_ready <= 1'b0;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid <= 1'b0;
        end else if (dst_ready_i && !src_empty) begin
            dst_valid <= 1'b1;
        end else if (!dst_ready_i) begin
            dst_valid <= 1'b0;
        end
    end

endmodule
