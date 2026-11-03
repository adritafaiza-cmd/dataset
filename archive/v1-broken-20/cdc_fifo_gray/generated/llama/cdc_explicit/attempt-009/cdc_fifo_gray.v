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

    reg [WIDTH-1:0]        fifo [DEPTH-1:0];
    reg [LOG_DEPTH-1:0]    wr_ptr;
    reg [LOG_DEPTH-1:0]    rd_ptr;
    reg [LOG_DEPTH-1:0]    gray_wr_ptr;
    reg [LOG_DEPTH-1:0]    gray_rd_ptr;
    reg [SYNC_STAGES-1:0]  src_rst_sync;
    reg [SYNC_STAGES-1:0]  dst_rst_sync;
    reg                    src_rst_synced;
    reg                    dst_rst_synced;
    reg                    src_ready;
    reg                    dst_valid;
    reg [WIDTH-1:0]        dst_data;

    assign src_ready_o = src_ready;
    assign dst_data_o = dst_data;
    assign dst_valid_o = dst_valid;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rst_sync <= {SYNC_STAGES{1'b0}};
            src_rst_synced <= 1'b0;
        end else begin
            src_rst_sync <= {src_rst_sync[SYNC_STAGES-2:0], 1'b0};
            src_rst_synced <= src_rst_sync[SYNC_STAGES-1];
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rst_sync <= {SYNC_STAGES{1'b0}};
            dst_rst_synced <= 1'b0;
        end else begin
            dst_rst_sync <= {dst_rst_sync[SYNC_STAGES-2:0], 1'b0};
            dst_rst_synced <= dst_rst_sync[SYNC_STAGES-1];
        end
    end

    always @(posedge src_clk_i) begin
        if (!src_rst_synced) begin
            wr_ptr <= {LOG_DEPTH{1'b0}};
            gray_wr_ptr <= {LOG_DEPTH{1'b0}};
            src_ready <= 1'b1;
        end else if (src_valid_i && src_ready) begin
            fifo[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1;
            gray_wr_ptr <= (wr_ptr >> 1) ^ wr_ptr;
            if (wr_ptr == (DEPTH - 1)) begin
                src_ready <= 1'b0;
            end
        end
    end

    always @(posedge dst_clk_i) begin
        if (!dst_rst_synced) begin
            rd_ptr <= {LOG_DEPTH{1'b0}};
            gray_rd_ptr <= {LOG_DEPTH{1'b0}};
            dst_valid <= 1'b0;
            dst_data <= {WIDTH{1'b0}};
        end else if (dst_ready_i && dst_valid) begin
            dst_valid <= 1'b0;
            if (rd_ptr != wr_ptr) begin
                dst_data <= fifo[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                gray_rd_ptr <= (rd_ptr >> 1) ^ rd_ptr;
            end
        end else if (dst_ready_i && (gray_rd_ptr != gray_wr_ptr)) begin
            dst_valid <= 1'b1;
            dst_data <= fifo[rd_ptr];
            rd_ptr <= rd_ptr + 1;
            gray_rd_ptr <= (rd_ptr >> 1) ^ rd_ptr;
        end
    end

    always @(posedge src_clk_i) begin
        if (src_rst_synced && !src_ready && (gray_wr_ptr != gray_rd_ptr)) begin
            src_ready <= 1'b1;
        end
    end

endmodule
