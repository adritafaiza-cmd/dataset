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
    reg [WIDTH-1:0]       fifo [0:(2**LOG_DEPTH)-1];
    reg [LOG_DEPTH:0]     src_wr_ptr;
    reg [LOG_DEPTH:0]     src_rd_ptr;
    reg [LOG_DEPTH:0]     dst_wr_ptr;
    reg [LOG_DEPTH:0]     dst_rd_ptr;
    reg                   src_full;
    reg                   src_empty;
    reg                   dst_full;
    reg                   dst_empty;
    reg                   src_clear_done;
    reg                   dst_clear_done;

    // Clear pending signals
    reg                   src_clear_pending;
    reg                   dst_clear_pending;

    // Clock domains
    wire                  src_clk_en;
    wire                  dst_clk_en;

    // Synchronizers
    wire [LOG_DEPTH:0]    src_wr_ptr_sync;
    wire [LOG_DEPTH:0]    src_rd_ptr_sync;
    wire [LOG_DEPTH:0]    dst_wr_ptr_sync;
    wire [LOG_DEPTH:0]    dst_rd_ptr_sync;

    // Instantiate synchronizers
    sync_ff #(.WIDTH(LOG_DEPTH+1), .STAGES(SYNC_STAGES)) src_wr_ptr_sync_ff (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .din(src_wr_ptr),
        .dout(src_wr_ptr_sync)
    );
    sync_ff #(.WIDTH(LOG_DEPTH+1), .STAGES(SYNC_STAGES)) src_rd_ptr_sync_ff (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .din(src_rd_ptr),
        .dout(src_rd_ptr_sync)
    );
    sync_ff #(.WIDTH(LOG_DEPTH+1), .STAGES(SYNC_STAGES)) dst_wr_ptr_sync_ff (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .din(dst_wr_ptr),
        .dout(dst_wr_ptr_sync)
    );
    sync_ff #(.WIDTH(LOG_DEPTH+1), .STAGES(SYNC_STAGES)) dst_rd_ptr_sync_ff (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .din(dst_rd_ptr),
        .dout(dst_rd_ptr_sync)
    );

    // Clear logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_done <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_done <= 1'b0;
            end else if (src_clear_pending && dst_clear_done) begin
                src_clear_done <= 1'b1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_done <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_done <= 1'b0;
            end else if (src_clear_done && dst_clear_pending) begin
                dst_clear_done <= 1'b1;
            end
        end
    end

    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

    // FIFO logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_rd_ptr <= 0;
            src_clear_pending <= 1'b0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1'b1;
            end else if (src_clear_done) begin
                src_wr_ptr <= 0;
                src_rd_ptr <= 0;
                src_clear_pending <= 1'b0;
            end else begin
                if (src_valid_i && src_ready_o && !src_full) begin
                    fifo[src_wr_ptr] <= src_data_i;
                    src_wr_ptr <= src_wr_ptr + 1;
                end
                if (src_valid_i && src_ready_o && src_wr_ptr == src_rd_ptr) begin
                    src_full <= 1'b1;
                end
                if (src_ready_o && src_wr_ptr > src_rd_ptr) begin
                    src_full <= 1'b0;
                end
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr <= 0;
            dst_rd_ptr <= 0;
            dst_clear_pending <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending <= 1'b1;
            end else if (dst_clear_done) begin
                dst_wr_ptr <= 0;
                dst_rd_ptr <= 0;
                dst_clear_pending <= 1'b0;
            end else begin
                if (src_valid_i && src_ready_o && dst_ready_i && !dst_full) begin
                    dst_data_o <= fifo[dst_rd_ptr];
                    dst_rd_ptr <= dst_rd_ptr + 1;
                    dst_valid_o <= 1'b1;
                end
                if (src_valid_i && src_ready_o && dst_ready_i && dst_rd_ptr == dst_wr_ptr) begin
                    dst_full <= 1'b1;
                end
                if (dst_ready_i && dst_wr_ptr > dst_rd_ptr) begin
                    dst_full <= 1'b0;
                end
            end
        end
    end

    // Ready logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o <= 1'b1;
        end else begin
            if (src_clear_i) begin
                src_ready_o <= 1'b0;
            end else if (src_clear_done) begin
                src_ready_o <= 1'b1;
            end else if (src_full) begin
                src_ready_o <= 1'b0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                dst_valid_o <= 1'b0;
            end else if (dst_clear_done) begin
                dst_valid_o <= 1'b0;
            end else if (dst_full) begin
                dst_valid_o <= 1'b1;
            end
        end
    end

endmodule

module sync_ff #(
    parameter WIDTH = 1,
    parameter STAGES = 1
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     din,
    output [WIDTH-1:0]     dout
);
    reg [WIDTH-1:0]       shift_reg [0:STAGES-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            shift_reg <= {WIDTH{1'b0}};
        end else begin
            shift_reg <= {shift_reg[STAGES-2:0], din};
        end
    end

    assign dout = shift_reg[STAGES-1];

endmodule
