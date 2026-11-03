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

    reg [WIDTH-1:0]         fifo_data [2**LOG_DEPTH-1:0];
    reg [LOG_DEPTH-1:0]    wr_ptr;
    reg [LOG_DEPTH-1:0]    rd_ptr;
    reg [LOG_DEPTH-1:0]    gray_wr_ptr;
    reg [LOG_DEPTH-1:0]    gray_rd_ptr;
    reg [WIDTH-1:0]        dst_data_reg;
    reg                    dst_valid_reg;
    reg                    src_clear_pending_reg;
    reg                    dst_clear_pending_reg;
    reg                    src_ready_reg;
    reg [SYNC_STAGES-1:0]  src_clear_sync;
    reg [SYNC_STAGES-1:0]  dst_clear_sync;
    reg [SYNC_STAGES-1:0]  src_rst_sync;
    reg [SYNC_STAGES-1:0]  dst_rst_sync;

    assign src_clear_pending_o = src_clear_pending_reg;
    assign dst_clear_pending_o = dst_clear_pending_reg;
    assign src_ready_o = src_ready_reg;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            src_clear_pending_reg <= 1'b0;
            src_ready_reg <= 1'b0;
            wr_ptr <= {LOG_DEPTH{1'b0}};
            gray_wr_ptr <= {LOG_DEPTH{1'b0}};
            src_clear_sync <= {SYNC_STAGES{1'b0}};
            src_rst_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            if (src_clear_i) begin
                src_clear_pending_reg <= 1'b1;
                wr_ptr <= {LOG_DEPTH{1'b0}};
                gray_wr_ptr <= {LOG_DEPTH{1'b0}};
            end else if (src_clear_pending_reg) begin
                src_clear_pending_reg <= 1'b0;
            end

            if (src_valid_i && src_ready_reg) begin
                fifo_data[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1'b1;
            end

            src_ready_reg <= (wr_ptr != {LOG_DEPTH{1'b1}}) && !src_clear_pending_reg;

            src_clear_sync[0] <= src_clear_i;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                src_clear_sync[i] <= src_clear_sync[i-1];
            end

            src_rst_sync[0] <= ~src_rst_ni;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                src_rst_sync[i] <= src_rst_sync[i-1];
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            dst_clear_pending_reg <= 1'b0;
            dst_valid_reg <= 1'b0;
            rd_ptr <= {LOG_DEPTH{1'b0}};
            gray_rd_ptr <= {LOG_DEPTH{1'b0}};
            dst_clear_sync <= {SYNC_STAGES{1'b0}};
            dst_rst_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending_reg <= 1'b1;
                rd_ptr <= {LOG_DEPTH{1'b0}};
                gray_rd_ptr <= {LOG_DEPTH{1'b0}};
            end else if (dst_clear_pending_reg) begin
                dst_clear_pending_reg <= 1'b0;
            end

            if (dst_valid_reg && dst_ready_i) begin
                dst_valid_reg <= 1'b0;
                rd_ptr <= rd_ptr + 1'b1;
            end else if (dst_valid_reg && !dst_ready_i) begin
                dst_valid_reg <= 1'b1;
            end

            if (!dst_clear_pending_reg && !dst_valid_reg) begin
                dst_data_reg <= fifo_data[rd_ptr];
                dst_valid_reg <= 1'b1;
            end

            dst_clear_sync[0] <= dst_clear_i;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                dst_clear_sync[i] <= dst_clear_sync[i-1];
            end

            dst_rst_sync[0] <= ~dst_rst_ni;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                dst_rst_sync[i] <= dst_rst_sync[i-1];
            end
        end
    end

    always @(posedge src_clk_i) begin
        gray_wr_ptr <= {wr_ptr[LOG_DEPTH-1], wr_ptr[LOG_DEPTH-2:0]};
    end

    always @(posedge dst_clk_i) begin
        gray_rd_ptr <= {rd_ptr[LOG_DEPTH-1], rd_ptr[LOG_DEPTH-2:0]};
    end

endmodule
