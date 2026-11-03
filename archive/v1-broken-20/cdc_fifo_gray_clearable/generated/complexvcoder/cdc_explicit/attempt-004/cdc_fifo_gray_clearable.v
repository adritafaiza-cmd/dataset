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
    logic [LOG_DEPTH-1:0] src_gray_counter;
    logic [LOG_DEPTH-1:0] dst_gray_counter;
    logic [WIDTH-1:0] src_fifo_data_out;
    logic [WIDTH-1:0] dst_fifo_data_in;
    logic src_fifo_valid_out;
    logic dst_fifo_valid_in;
    logic src_fifo_ready_in;
    logic dst_fifo_ready_out;
    logic src_clear_pending;
    logic dst_clear_pending;

    // Gray counters
    gray_counter #(.WIDTH(LOG_DEPTH)) src_gray_counter (
        .count(src_gray_counter),
        .clr(src_clear_pending),
        .clk(src_clk_i),
        .rst_n(src_rst_ni)
    );

    gray_counter #(.WIDTH(LOG_DEPTH)) dst_gray_counter (
        .count(dst_gray_counter),
        .clr(dst_clear_pending),
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni)
    );

    // FIFO cores
    fifo_core #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_fifo (
        .data_in(src_data_i),
        .valid_in(src_valid_i),
        .ready_out(src_ready_o),
        .clr(src_clear_i),
        .clk(src_clk_i),
        .rst_n(src_rst_ni)
    );

    fifo_core #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_fifo (
        .data_out(dst_fifo_data_in),
        .valid_out(dst_fifo_valid_in),
        .ready_in(dst_ready_i),
        .clr(dst_clear_i),
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni)
    );

    // CDC paths
    cdc_path #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) src_to_dst_cdc (
        .data_in(src_fifo_data_out),
        .valid_in(src_fifo_valid_out),
        .ready_out(src_fifo_ready_in),
        .data_out(dst_fifo_data_in),
        .valid_out(dst_fifo_valid_in),
        .ready_in(dst_ready_i),
        .clk_in(src_clk_i),
        .clk_out(dst_clk_i),
        .rst_n_in(src_rst_ni),
        .rst_n_out(dst_rst_ni)
    );

    cdc_path #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dst_to_src_cdc (
        .data_in(dst_fifo_data_out),
        .valid_in(dst_fifo_valid_out),
        .ready_out(dst_fifo_ready_in),
        .data_out(src_fifo_data_out),
        .valid_out(src_fifo_valid_out),
        .ready_in(src_ready_o),
        .clk_in(dst_clk_i),
        .clk_out(src_clk_i),
        .rst_n_in(dst_rst_ni),
        .rst_n_out(src_rst_ni)
    );

    // Clear pending logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 1'b0;
        end else begin
            src_clear_pending <= src_clear_i;
        end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
        end else begin
            dst_clear_pending <= dst_clear_i;
        end
    end

    // Output clear pending
    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule

module gray_counter #(
    parameter WIDTH = 1
) (
    input [WIDTH-1:0] count,
    input clr,
    input clk,
    input rst_n
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else if (clr) begin
            count <= 0;
        end else begin
            count <= count + 1;
        end
    end

endmodule

module fifo_core #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
) (
    input  [WIDTH-1:0] data_in,
    input              valid_in,
    output             ready_out,
    input              clr,
    input              clk,
    input              rst_n
);

    logic [WIDTH-1:0] mem [0:(1<<LOG_DEPTH)-1];
    logic [LOG_DEPTH-1:0] wr_ptr;
    logic [LOG_DEPTH-1:0] rd_ptr;
    logic [LOG_DEPTH:0] full;
    logic [LOG_DEPTH:0] empty;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 0;
            empty <= 1;
        end else if (clr) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (valid_in && ready_out && !full) begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
                full <= wr_ptr == rd_ptr;
            end
            if (ready_out && !empty) begin
                rd_ptr <= rd_ptr + 1;
                empty <= wr_ptr == rd_ptr;
            end
        end
    end

    assign ready_out = !full;
    assign empty = wr_ptr == rd_ptr;

endmodule

module cdc_path #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
) (
    input  [WIDTH-1:0] data_in,
    input              valid_in,
    input              ready_out,
    output [WIDTH-1:0] data_out,
    output             valid_out,
    input              ready_in,
    input              clk_in,
    input              clk_out,
    input              rst_n_in,
    input              rst_n_out
);

    logic [WIDTH-1:0] data_sync [SYNC_STAGES];
    logic [SYNC_STAGES-1:0] valid_sync [SYNC_STAGES];
    logic [SYNC_STAGES-1:0] ready_sync [SYNC_STAGES];

    // Clock-domain crossing for data
    always_ff @(posedge clk_in or negedge rst_n_in) begin
        if (!rst_n_in) begin
            data_sync <= '{default: 0};
        end else begin
            data_sync[0] <= data_in;
        end
    end

    always_ff @(posedge clk_out or negedge rst_n_out) begin
        if (!rst_n_out) begin
            data_out <= 0;
        end else begin
            data_out <= data_sync[SYNC_STAGES-1];
        end
    end

    // Clock-domain crossing for valid
    always_ff @(posedge clk_in or negedge rst_n_in) begin
        if (!rst_n_in) begin
            valid_sync <= '{default: 0};
        end else begin
            valid_sync[0] <= valid_in;
        end
    end

    always_ff @(posedge clk_out or negedge rst_n_out) begin
        if (!rst_n_out) begin
            valid_out <= 0;
        end else begin
            valid_out <= valid_sync[SYNC_STAGES-1];
        end
    end

    // Clock-domain crossing for ready
    always_ff @(posedge clk_in or negedge rst_n_in) begin
        if (!rst_n_in) begin
            ready_sync <= '{default: 0};
        end else begin
            ready_sync[0] <= ready_out;
        end
    end

    always_ff @(posedge clk_out or negedge rst_n_out) begin
        if (!rst_n_out) begin
            ready_in <= 0;
        end else begin
            ready_in <= ready_sync[SYNC_STAGES-1];
        end
    end

endmodule
