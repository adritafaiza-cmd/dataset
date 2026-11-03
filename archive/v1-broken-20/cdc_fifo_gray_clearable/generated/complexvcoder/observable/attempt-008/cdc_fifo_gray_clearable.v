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

    // Internal signals
    logic [WIDTH-1:0]       src_data_reg;
    logic                   src_valid_reg;
    logic                   src_ready_reg;
    logic                   src_clear_reg;
    logic                   dst_clear_reg;
    logic                   src_clear_pending_reg;
    logic                   dst_clear_pending_reg;

    // FIFO instances
    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_gray_src (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_clear_i(src_clear_reg),
        .src_data_i(src_data_reg),
        .src_valid_i(src_valid_reg),
        .src_ready_o(src_ready_reg),
        .dst_rst_ni(dst_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_clear_i(src_clear_pending_reg),
        .dst_data_o(dst_data_o),
        .dst_valid_o(dst_valid_o),
        .dst_ready_i(dst_ready_i)
    );

    fifo_gray #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_gray_dst (
        .src_rst_ni(dst_rst_ni),
        .src_clk_i(dst_clk_i),
        .src_clear_i(dst_clear_reg),
        .src_data_i(dst_data_o),
        .src_valid_i(dst_valid_o),
        .src_ready_o(dst_ready_i),
        .dst_rst_ni(src_rst_ni),
        .dst_clk_i(src_clk_i),
        .dst_clear_i(dst_clear_pending_reg),
        .dst_data_o(src_data_reg),
        .dst_valid_o(src_valid_reg),
        .dst_ready_i(src_ready_reg)
    );

    // Clear logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_reg <= 1'b0;
        end else begin
            src_clear_reg <= src_clear_i;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_reg <= 1'b0;
        end else begin
            dst_clear_reg <= dst_clear_i;
        end
    end

    // Clear pending logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending_reg <= 1'b0;
        end else begin
            if (src_clear_i || dst_clear_pending_reg) begin
                src_clear_pending_reg <= 1'b1;
            end else if (src_ready_reg) begin
                src_clear_pending_reg <= 1'b0;
            end
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending_reg <= 1'b0;
        end else begin
            if (dst_clear_i || src_clear_pending_reg) begin
                dst_clear_pending_reg <= 1'b1;
            end else if (dst_ready_i) begin
                dst_clear_pending_reg <= 1'b0;
            end
        end
    end

    // Ready signal generation
    assign src_ready_o = src_ready_reg;
    assign dst_ready_o = dst_ready_reg;

    // Clear pending output
    assign src_clear_pending_o = src_clear_pending_reg;
    assign dst_clear_pending_o = dst_clear_pending_reg;

endmodule

module fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output reg [WIDTH-1:0] dst_data_o,
    output reg                 dst_valid_o,
    input                  dst_ready_i
);

    // Internal signals
    logic [WIDTH-1:0]       fifo [2**LOG_DEPTH-1:0];
    logic [LOG_DEPTH:0]     wr_ptr;
    logic [LOG_DEPTH:0]     rd_ptr;
    logic                   wr_en;
    logic                   rd_en;
    logic                   fifo_full;
    logic                   fifo_empty;
    logic                   sync_reg [SYNC_STAGES-1:0];

    // Write logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            wr_en <= 1'b0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                fifo[wr_ptr] <= src_data_i;
                wr_ptr <= wr_ptr + 1;
                wr_en <= 1'b1;
            end else begin
                wr_en <= 1'b0;
            end
        end
    end

    // Read logic
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            rd_en <= 1'b0;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                rd_ptr <= rd_ptr + 1;
                rd_en <= 1'b1;
            end else begin
                rd_en <= 1'b0;
            end
        end
    end

    // FIFO full and empty detection
    assign fifo_full = (wr_ptr - rd_ptr) == (2**LOG_DEPTH);
    assign fifo_empty = (wr_ptr - rd_ptr) == 0;

    // Clear logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
        end else if (src_clear_i) begin
            wr_ptr <= 0;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
        end else if (dst_clear_i) begin
            rd_ptr <= 0;
        end
    end

    // Output logic
    assign dst_data_o = fifo[rd_ptr];
    assign dst_valid_o = ~fifo_empty;

    // Synchronization
    generate
        if (SYNC_STAGES > 0) begin
            genvar i;
            generate
                for (i = 0; i < SYNC_STAGES; i = i + 1) begin
                    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
                        if (!dst_rst_ni) begin
                            sync_reg[i] <= 1'b0;
                        end else begin
                            sync_reg[i] <= dst_valid_o;
                        end
                    end
                end
            endgenerate
            assign dst_valid_o = sync_reg[SYNC_STAGES-1];
        end
    endgenerate

    // Ready signal generation
    assign src_ready_o = ~fifo_full;

endmodule
