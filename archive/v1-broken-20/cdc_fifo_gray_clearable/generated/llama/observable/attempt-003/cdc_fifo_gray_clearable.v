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

    reg [WIDTH-1:0]         fifo[2**LOG_DEPTH-1:0];
    reg [$clog2(2**LOG_DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(2**LOG_DEPTH)-1:0] gray_wr_ptr, gray_rd_ptr;
    reg [SYNC_STAGES-1:0]    sync_clear;
    reg                     src_clear_pending, dst_clear_pending;
    reg                     src_empty, src_full;
    reg                     dst_empty, dst_full;
    reg                     src_valid, dst_valid;

    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            src_clear_pending <= 1'b0;
            src_valid <= 1'b0;
            src_ready_o <= 1'b1;
            src_empty <= 1'b1;
            src_full <= 1'b0;
            wr_ptr <= 'd0;
            gray_wr_ptr <= 'd0;
        end else if (src_clear_i) begin
            src_clear_pending <= 1'b1;
            src_valid <= 1'b0;
            src_ready_o <= 1'b1;
            src_empty <= 1'b1;
            src_full <= 1'b0;
            wr_ptr <= 'd0;
            gray_wr_ptr <= 'd0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                fifo[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                src_valid <= 1'b1;
                src_empty <= 1'b0;
                if (wr_ptr == {LOG_DEPTH{1'b1}} - 1) begin
                    src_full <= 1'b1;
                    src_ready_o <= 1'b0;
                end
            end else if (src_valid && ~src_full) begin
                src_ready_o <= 1'b1;
            end
            if (src_clear_pending) begin
                src_clear_pending <= 1'b0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
            dst_valid_o <= 1'b0;
            dst_empty <= 1'b1;
            dst_full <= 1'b0;
            rd_ptr <= 'd0;
            gray_rd_ptr <= 'd0;
        end else if (dst_clear_i) begin
            dst_clear_pending <= 1'b1;
            dst_valid_o <= 1'b0;
            dst_empty <= 1'b1;
            dst_full <= 1'b0;
            rd_ptr <= 'd0;
            gray_rd_ptr <= 'd0;
        end else begin
            if (dst_valid && dst_ready_i) begin
                dst_valid_o <= 1'b0;
                rd_ptr <= rd_ptr + 1;
                dst_empty <= 1'b1;
                if (rd_ptr == {LOG_DEPTH{1'b1}} - 1) begin
                    dst_full <= 1'b0;
                end
            end else if (~dst_empty && ~dst_full) begin
                dst_valid_o <= 1'b1;
            end
            if (dst_clear_pending) begin
                dst_clear_pending <= 1'b0;
            end
        end
    end

    always @(posedge src_clk_i) begin
        if (~src_rst_ni) begin
            sync_clear <= 'd0;
        end else if (src_clear_i) begin
            sync_clear[0] <= 1'b1;
        end else begin
            sync_clear[0] <= 1'b0;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                sync_clear[i] <= sync_clear[i-1];
            end
        end
    end

    always @(posedge dst_clk_i) begin
        if (~dst_rst_ni) begin
            dst_data_o <= 'd0;
            dst_valid <= 1'b0;
        end else if (dst_clear_i || sync_clear[SYNC_STAGES-1]) begin
            dst_data_o <= 'd0;
            dst_valid <= 1'b0;
        end else if (~dst_empty && dst_ready_i) begin
            dst_data_o <= fifo[gray_rd_ptr];
            dst_valid <= 1'b1;
        end
    end

    always @(posedge src_clk_i) begin
        if (~src_rst_ni) begin
            gray_wr_ptr <= 'd0;
        end else if (src_clear_i) begin
            gray_wr_ptr <= 'd0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                gray_wr_ptr <= gray_wr_ptr + 1;
            end
        end
    end

    always @(posedge dst_clk_i) begin
        if (~dst_rst_ni) begin
            gray_rd_ptr <= 'd0;
        end else if (dst_clear_i) begin
            gray_rd_ptr <= 'd0;
        end else begin
            if (dst_valid && dst_ready_i) begin
                gray_rd_ptr <= gray_rd_ptr + 1;
            end
        end
    end

    assign src_empty = (wr_ptr == 'd0);
    assign src_full = (wr_ptr == {LOG_DEPTH{1'b1}} - 1);
    assign dst_empty = (rd_ptr == 'd0);
    assign dst_full = (rd_ptr == {LOG_DEPTH{1'b1}} - 1);

endmodule
