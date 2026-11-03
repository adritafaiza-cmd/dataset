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

    wire [LOG_DEPTH-1:0] src_gray_out;
    wire [LOG_DEPTH-1:0] src_gray_sync_in;
    wire [LOG_DEPTH-1:0] dst_gray_out;
    wire [LOG_DEPTH-1:0] dst_gray_sync_in;
    wire                 src_clear_out;
    wire                 dst_clear_out;
    wire                 src_clear_pending;
    wire                 dst_clear_pending;

    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) src_gray_counter (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .gray_sync_in(dst_gray_sync_in),
        .gray_out(src_gray_out)
    );

    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_gray_counter (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .gray_sync_in(src_gray_sync_in),
        .gray_out(dst_gray_out)
    );

    sync_register #(
        .WIDTH(LOG_DEPTH)
    ) src_gray_sync (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .data_in(src_gray_out),
        .data_out(src_gray_sync_in)
    );

    sync_register #(
        .WIDTH(LOG_DEPTH)
    ) dst_gray_sync (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .data_in(dst_gray_out),
        .data_out(dst_gray_sync_in)
    );

    fifo_memory #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_mem (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_clear(src_clear_out),
        .src_valid(src_valid_i),
        .src_data(src_data_i),
        .src_ready(src_ready_o),
        .dst_rst_ni(dst_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_clear(dst_clear_out),
        .dst_ready(dst_ready_i),
        .dst_data(dst_data_o),
        .dst_valid(dst_valid_o)
    );

    clear_logic src_clear_logic (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .clear_i(src_clear_i),
        .clear_out(src_clear_out),
        .clear_pending(src_clear_pending)
    );

    clear_logic dst_clear_logic (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .clear_i(dst_clear_i),
        .clear_out(dst_clear_out),
        .clear_pending(dst_clear_pending)
    );

    assign src_clear_pending_o = src_clear_pending;
    assign dst_clear_pending_o = dst_clear_pending;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input  [LOG_DEPTH-1:0] gray_sync_in,
    output [LOG_DEPTH-1:0] gray_out
);

    reg  [LOG_DEPTH-1:0] binary_counter;
    wire [LOG_DEPTH-1:0] gray_code;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            binary_counter <= {LOG_DEPTH{1'b0}};
        end else begin
            if (gray_sync_in != gray_out) begin
                binary_counter <= binary_counter + 1;
            end
        end
    end

    assign gray_code = binary_counter ^ (binary_counter >> 1);
    assign gray_out = gray_code;

endmodule

module sync_register #(
    parameter WIDTH = 8
)(
    input                  rst_ni,
    input                  clk_i,
    input  [WIDTH-1:0]     data_in,
    output [WIDTH-1:0]     data_out
);

    reg [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= {WIDTH{1'b0}};
            end
        end else begin
            sync_reg[0] <= data_in;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign data_out = sync_reg[SYNC_STAGES-1];

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear,
    input                  src_valid,
    input  [WIDTH-1:0]     src_data,
    output                 src_ready,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear,
    input                  dst_ready,
    output [WIDTH-1:0]     dst_data,
    output                 dst_valid
);

    reg  [WIDTH-1:0] fifo_memory [0:(1<<LOG_DEPTH)-1];
    reg  [LOG_DEPTH-1:0] src_wr_ptr;
    reg  [LOG_DEPTH-1:0] src_rd_ptr;
    reg  [LOG_DEPTH-1:0] dst_wr_ptr;
    reg  [LOG_DEPTH-1:0] dst_rd_ptr;

    wire full;
    wire empty;
    wire [LOG_DEPTH-1:0] gray_src_wr;
    wire [LOG_DEPTH-1:0] gray_src_rd_sync;
    wire [LOG_DEPTH-1:0] gray_dst_wr_sync;
    wire [LOG_DEPTH-1:0] gray_dst_rd;

    assign full = (src_wr_ptr + 1) == src_rd_ptr;
    assign empty = src_wr_ptr == src_rd_ptr;

    assign gray_src_wr = src_wr_ptr ^ (src_wr_ptr >> 1);
    assign gray_src_rd_sync = gray_dst_wr_sync;
    assign gray_dst_wr_sync = gray_src_wr;
    assign gray_dst_rd = dst_rd_ptr ^ (dst_rd_ptr >> 1);

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {LOG_DEPTH{1'b0}};
            src_rd_ptr <= {LOG_DEPTH{1'b0}};
        end else begin
            if (src_clear) begin
                src_wr_ptr <= {LOG_DEPTH{1'b0}};
                src_rd_ptr <= {LOG_DEPTH{1'b0}};
            end else begin
                if (src_valid && !full) begin
                    fifo_memory[src_wr_ptr] <= src_data;
                    src_wr_ptr <= src_wr_ptr + 1;
                end
                if (gray_src_rd_sync != gray_src_wr) begin
                    src_rd_ptr <= src_rd_ptr + 1;
                end
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr <= {LOG_DEPTH{1'b0}};
            dst_rd_ptr <= {LOG_DEPTH{1'b0}};
        end else begin
            if (dst_clear) begin
                dst_wr_ptr <= {LOG_DEPTH{1'b0}};
                dst_rd_ptr <= {LOG_DEPTH{1'b0}};
            end else begin
                if (gray_src_wr != gray_dst_wr_sync) begin
                    dst_wr_ptr <= dst_wr_ptr + 1;
                end
                if (dst_ready && !empty) begin
                    dst_rd_ptr <= dst_rd_ptr + 1;
                end
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data <= {WIDTH{1'b0}};
            dst_valid <= 1'b0;
        end else begin
            if (gray_src_wr != gray_dst_wr_sync) begin
                dst_data <= fifo_memory[dst_wr_ptr];
                dst_valid <= 1'b1;
            end else if (dst_ready) begin
                dst_valid <= 1'b0;
            end
        end
    end

    assign src_ready = !full;

endmodule

module clear_logic (
    input  rst_ni,
    input  clk_i,
    input  clear_i,
    output clear_out,
    output clear_pending
);

    reg clear_active;
    reg clear_request;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            clear_active <= 1'b0;
            clear_request <= 1'b0;
        end else begin
            if (clear_i) begin
                clear_request <= 1'b1;
            end
            if (clear_request && !clear_active) begin
                clear_active <= 1'b1;
            end
            if (!clear_request && clear_active) begin
                clear_active <= 1'b0;
            end
        end
    end

    assign clear_out = clear_active;
    assign clear_pending = clear_request;

endmodule
