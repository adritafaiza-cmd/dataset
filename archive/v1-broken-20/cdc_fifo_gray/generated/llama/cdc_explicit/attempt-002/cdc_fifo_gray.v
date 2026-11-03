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

    reg [WIDTH-1:0]         fifo[2**LOG_DEPTH-1:0];
    reg [LOG_DEPTH-1:0]    wr_ptr;
    reg [LOG_DEPTH-1:0]    rd_ptr;
    reg [LOG_DEPTH-1:0]    gray_wr_ptr;
    reg [LOG_DEPTH-1:0]    gray_rd_ptr;
    reg [WIDTH-1:0]        data_out;
    reg                    full;
    reg                    empty;
    reg                    src_ready;
    reg                    dst_valid;
    reg [SYNC_STAGES-1:0]  src_valid_sync;
    reg [SYNC_STAGES-1:0]  dst_ready_sync;

    assign src_ready_o = src_ready;
    assign dst_data_o = data_out;
    assign dst_valid_o = dst_valid;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            gray_wr_ptr <= 0;
            src_valid_sync <= 0;
            src_ready <= 1;
        end else begin
            if (src_valid_i && src_ready) begin
                fifo[wr_ptr] <= src_data_i;
                gray_wr_ptr <= gray_wr_ptr + 1;
                wr_ptr <= wr_ptr + 1;
                if (wr_ptr == 2**LOG_DEPTH - 1) begin
                    wr_ptr <= 0;
                end
                src_ready <= !full;
            end
            if (src_valid_sync[SYNC_STAGES-1]) begin
                src_ready <= 1;
            end
            src_valid_sync <= {src_valid_sync[SYNC_STAGES-2:0], src_valid_i};
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            gray_rd_ptr <= 0;
            dst_ready_sync <= 0;
            dst_valid <= 0;
            data_out <= 0;
        end else begin
            if (dst_ready_i && dst_valid) begin
                dst_valid <= 0;
                rd_ptr <= rd_ptr + 1;
                if (rd_ptr == 2**LOG_DEPTH - 1) begin
                    rd_ptr <= 0;
                end
            end
            if (dst_ready_sync[SYNC_STAGES-1]) begin
                dst_valid <= 0;
            end
            dst_ready_sync <= {dst_ready_sync[SYNC_STAGES-2:0], dst_ready_i};
            if (gray_wr_ptr != gray_rd_ptr) begin
                dst_valid <= 1;
                data_out <= fifo[rd_ptr];
            end
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            full <= 0;
        end else begin
            if (src_valid_i && src_ready) begin
                if (wr_ptr == rd_ptr) begin
                    full <= 1;
                end
            end
            if (dst_ready_i && dst_valid) begin
                if (wr_ptr == rd_ptr) begin
                    full <= 0;
                end
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            empty <= 1;
        end else begin
            if (dst_ready_i && dst_valid) begin
                if (wr_ptr == rd_ptr) begin
                    empty <= 1;
                end
            end
            if (src_valid_i && src_ready) begin
                if (wr_ptr == rd_ptr) begin
                    empty <= 0;
                end
            end
        end
    end

endmodule
