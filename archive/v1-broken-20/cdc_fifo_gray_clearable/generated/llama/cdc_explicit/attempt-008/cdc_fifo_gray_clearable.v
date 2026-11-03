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
    reg [LOG_DEPTH-1:0]    wr_ptr;
    reg [LOG_DEPTH-1:0]    rd_ptr;
    reg [LOG_DEPTH-1:0]    gray_wr_ptr;
    reg [LOG_DEPTH-1:0]    gray_rd_ptr;
    reg [LOG_DEPTH:0]      cnt;
    reg [SYNC_STAGES-1:0]  src_clear_sync;
    reg [SYNC_STAGES-1:0]  dst_clear_sync;
    reg                    src_clear_pending;
    reg                    dst_clear_pending;
    reg                    src_ready;
    reg                    dst_valid;

    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;
    assign src_ready_o = src_ready;
    assign dst_data_o = fifo[rd_ptr];
    assign dst_valid_o = dst_valid;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b0;
            src_clear_sync <= {SYNC_STAGES{1'b0}};
            wr_ptr <= {LOG_DEPTH{1'b0}};
            gray_wr_ptr <= {LOG_DEPTH{1'b0}};
            cnt <= {LOG_DEPTH+1{1'b0}};
            src_ready <= 1'b1;
        end else if (src_clear_i) begin
            src_clear_pending <= 1'b1;
            src_clear_sync <= {SYNC_STAGES{1'b1}};
            wr_ptr <= {LOG_DEPTH{1'b0}};
            gray_wr_ptr <= {LOG_DEPTH{1'b0}};
            cnt <= {LOG_DEPTH+1{1'b0}};
            src_ready <= 1'b0;
        end else if (src_clear_sync[SYNC_STAGES-1]) begin
            src_clear_pending <= 1'b0;
            src_clear_sync <= {SYNC_STAGES{1'b0}};
        end else if (src_valid_i && src_ready) begin
            fifo[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1'b1;
            gray_wr_ptr <= gray_wr_ptr + 1'b1;
            cnt <= cnt + 1'b1;
            if (cnt == 2**LOG_DEPTH - 1) begin
                src_ready <= 1'b0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
            dst_clear_sync <= {SYNC_STAGES{1'b0}};
            rd_ptr <= {LOG_DEPTH{1'b0}};
            gray_rd_ptr <= {LOG_DEPTH{1'b0}};
            dst_valid <= 1'b0;
        end else if (dst_clear_i) begin
            dst_clear_pending <= 1'b1;
            dst_clear_sync <= {SYNC_STAGES{1'b1}};
            rd_ptr <= {LOG_DEPTH{1'b0}};
            gray_rd_ptr <= {LOG_DEPTH{1'b0}};
            dst_valid <= 1'b0;
        end else if (dst_clear_sync[SYNC_STAGES-1]) begin
            dst_clear_pending <= 1'b0;
            dst_clear_sync <= {SYNC_STAGES{1'b0}};
        end else if (dst_ready_i && dst_valid) begin
            rd_ptr <= rd_ptr + 1'b1;
            gray_rd_ptr <= gray_rd_ptr + 1'b1;
            dst_valid <= 1'b0;
        end else if (cnt > 0 && !dst_valid) begin
            dst_valid <= 1'b1;
        end
    end

    always @(posedge src_clk_i) begin
        src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
    end

    always @(posedge dst_clk_i) begin
        dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
    end

endmodule
