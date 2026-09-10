module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    reg [WIDTH-1:0]         fifo [2**LOG_DEPTH-1:0];
    reg [LOG_DEPTH-1:0]     wr_ptr;
    reg [LOG_DEPTH-1:0]     rd_ptr;
    reg [LOG_DEPTH:0]       count;
    reg                     src_clear_pending;
    reg                     dst_clear_pending;
    reg                     src_ready;
    reg                     dst_valid;
    reg [WIDTH-1:0]         dst_data;
    reg [SYNC_STAGES-1:0]   src_clear_sync;
    reg [SYNC_STAGES-1:0]   dst_clear_sync;
    reg [SYNC_STAGES-1:0]   src_rst_sync;
    reg [SYNC_STAGES-1:0]   dst_rst_sync;

    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;
    assign src_ready_o = src_ready;
    assign dst_data_o = dst_data;
    assign dst_valid_o = dst_valid;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b1;
            src_ready <= 1'b0;
            wr_ptr <= '0;
            count <= '0;
            src_clear_sync <= '1;
            src_rst_sync <= '1;
        end else if (src_clear_i) begin
            src_clear_pending <= 1'b1;
            src_ready <= 1'b0;
            wr_ptr <= '0;
            count <= '0;
        end else if (src_clear_sync[SYNC_STAGES-1]) begin
            src_clear_pending <= 1'b0;
            if (count == 0) begin
                src_ready <= 1'b1;
            end else begin
                src_ready <= 1'b0;
            end
        end else begin
            src_clear_sync[0] <= src_clear_i;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                src_clear_sync[i] <= src_clear_sync[i-1];
            end
            src_rst_sync[0] <= ~src_rst_ni;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                src_rst_sync[i] <= src_rst_sync[i-1];
            end
            if (src_valid_i && src_ready) begin
                fifo[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
            if (src_rst_sync[SYNC_STAGES-1]) begin
                wr_ptr <= '0;
                count <= '0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b1;
            dst_valid <= 1'b0;
            rd_ptr <= '0;
            dst_data <= '0;
            dst_clear_sync <= '1;
            dst_rst_sync <= '1;
        end else if (dst_clear_i) begin
            dst_clear_pending <= 1'b1;
            dst_valid <= 1'b0;
            rd_ptr <= '0;
        end else if (dst_clear_sync[SYNC_STAGES-1]) begin
            dst_clear_pending <= 1'b0;
            if (count == 0) begin
                dst_valid <= 1'b0;
            end else begin
                dst_valid <= 1'b1;
                dst_data <= fifo[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
        end else begin
            dst_clear_sync[0] <= dst_clear_i;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                dst_clear_sync[i] <= dst_clear_sync[i-1];
            end
            dst_rst_sync[0] <= ~dst_rst_ni;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                dst_rst_sync[i] <= dst_rst_sync[i-1];
            end
            if (dst_valid && dst_ready_i) begin
                dst_valid <= 1'b0;
                count <= count - 1;
            end
            if (dst_rst_sync[SYNC_STAGES-1]) begin
                rd_ptr <= '0;
                count <= '0;
            end
        end
    end

endmodule
