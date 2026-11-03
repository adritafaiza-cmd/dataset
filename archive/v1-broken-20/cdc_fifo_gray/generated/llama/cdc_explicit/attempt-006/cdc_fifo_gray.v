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

    reg [WIDTH-1:0]                fifo [DEPTH-1:0];
    reg [LOG_DEPTH-1:0]            wr_ptr;
    reg [LOG_DEPTH-1:0]            rd_ptr;
    reg [LOG_DEPTH-1:0]            gray_wr_ptr;
    reg [LOG_DEPTH-1:0]            gray_rd_ptr;
    reg [SYNC_STAGES-1:0]          src_rst_sync;
    reg [SYNC_STAGES-1:0]          dst_rst_sync;
    reg [WIDTH-1:0]                dst_data_reg;
    reg                            dst_valid_reg;
    reg                            src_ready_reg;
    reg                            dst_valid_sync;
    reg                            dst_ready_sync;

    assign src_ready_o = src_ready_reg;
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rst_sync <= {SYNC_STAGES{1'b0}};
            src_ready_reg <= 1'b0;
            wr_ptr <= {LOG_DEPTH{1'b0}};
        end else begin
            src_rst_sync[0] <= ~src_rst_ni;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                src_rst_sync[i] <= src_rst_sync[i-1];
            end
            if (src_valid_i && src_ready_reg) begin
                fifo[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
            end
            if (src_rst_sync[SYNC_STAGES-1]) begin
                src_ready_reg <= (wr_ptr != rd_ptr + 1);
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rst_sync <= {SYNC_STAGES{1'b0}};
            dst_valid_reg <= 1'b0;
            rd_ptr <= {LOG_DEPTH{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
        end else begin
            dst_rst_sync[0] <= ~dst_rst_ni;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                dst_rst_sync[i] <= dst_rst_sync[i-1];
            end
            if (dst_valid_sync && dst_ready_i) begin
                dst_data_reg <= fifo[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                dst_valid_reg <= 1'b1;
            end else if (dst_valid_sync && !dst_ready_i) begin
                dst_valid_reg <= 1'b1;
            end else if (!dst_valid_sync) begin
                dst_valid_reg <= 1'b0;
            end
            if (dst_rst_sync[SYNC_STAGES-1]) begin
                dst_valid_sync <= (wr_ptr != rd_ptr);
            end
        end
    end

    always @(posedge src_clk_i) begin
        gray_wr_ptr <= {wr_ptr[LOG_DEPTH-1], wr_ptr[LOG_DEPTH-2:0]};
    end

    always @(posedge dst_clk_i) begin
        gray_rd_ptr <= {rd_ptr[LOG_DEPTH-1], rd_ptr[LOG_DEPTH-2:0]};
    end

    always @(posedge dst_clk_i) begin
        dst_ready_sync <= dst_ready_i;
    end

endmodule
