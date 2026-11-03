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
    reg [LOG_DEPTH-1:0] src_gray_ptr, dst_gray_ptr, sync_gray_ptr;
    reg [LOG_DEPTH-1:0] src_bin_ptr, dst_bin_ptr;
    reg                 src_full, src_empty, dst_full, dst_empty;
    reg                 src_clear_active, dst_clear_active;
    reg                 src_clear_done, dst_clear_done;
    reg                 fifo_write, fifo_read;
    reg  [WIDTH-1:0]    fifo_data;

    // Gray counters
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) gray_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_active),
        .bin_ptr_i(src_bin_ptr),
        .gray_ptr_o(src_gray_ptr)
    );

    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) gray_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_active),
        .bin_ptr_i(dst_bin_ptr),
        .gray_ptr_o(dst_gray_ptr)
    );

    // Synchronizer
    sync_register #(
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_reg (
        .src_clk_i(src_clk_i),
        .src_gray_ptr_i(src_gray_ptr),
        .dst_clk_i(dst_clk_i),
        .dst_gray_ptr_o(sync_gray_ptr)
    );

    // FIFO memory
    fifo_memory #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_mem (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .write_i(fifo_write),
        .write_addr_i(src_bin_ptr),
        .write_data_i(src_data_i),
        .read_i(fifo_read),
        .read_addr_i(dst_bin_ptr),
        .read_data_o(fifo_data)
    );

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_bin_ptr <= 0;
            src_clear_active <= 0;
            src_clear_done <= 0;
        end else begin
            if (src_clear_i && !src_clear_active) begin
                src_clear_active <= 1;
                src_clear_done <= 0;
            end else if (src_clear_active && src_empty) begin
                src_clear_active <= 0;
                src_clear_done <= 1;
            end

            if (!src_clear_active && !src_full && src_valid_i) begin
                src_bin_ptr <= src_bin_ptr + 1;
            end
        end
    end

    assign src_full = (src_bin_ptr == {LOG_DEPTH{1'b1}});
    assign src_empty = (src_bin_ptr == dst_bin_ptr);
    assign fifo_write = src_valid_i && !src_full && !src_clear_active;
    assign src_ready_o = !src_full && !src_clear_active;
    assign src_clear_pending_o = !src_clear_done;

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_bin_ptr <= 0;
            dst_clear_active <= 0;
            dst_clear_done <= 0;
        end else begin
            if (dst_clear_i && !dst_clear_active) begin
                dst_clear_active <= 1;
                dst_clear_done <= 0;
            end else if (dst_clear_active && dst_empty) begin
                dst_clear_active <= 0;
                dst_clear_done <= 1;
            end

            if (!dst_clear_active && !dst_empty && dst_ready_i) begin
                dst_bin_ptr <= dst_bin_ptr + 1;
            end
        end
    end

    assign dst_full = (dst_bin_ptr == {LOG_DEPTH{1'b1}});
    assign dst_empty = (sync_gray_ptr == dst_gray_ptr);
    assign fifo_read = dst_ready_i && !dst_empty && !dst_clear_active;
    assign dst_data_o = fifo_data;
    assign dst_valid_o = !dst_empty && !dst_clear_active;
    assign dst_clear_pending_o = !dst_clear_done;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    input  [LOG_DEPTH-1:0] bin_ptr_i,
    output [LOG_DEPTH-1:0] gray_ptr_o
);

    reg [LOG_DEPTH-1:0] gray_ptr;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            gray_ptr <= 0;
        end else if (clear_i) begin
            gray_ptr <= 0;
        end else begin
            gray_ptr <= (bin_ptr_i >> 1) ^ bin_ptr_i;
        end
    end

    assign gray_ptr_o = gray_ptr;

endmodule

module sync_register #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_clk_i,
    input  [LOG_DEPTH-1:0] src_gray_ptr_i,
    input                  dst_clk_i,
    output [LOG_DEPTH-1:0] dst_gray_ptr_o
);

    reg [LOG_DEPTH-1:0] sync_gray_ptr [0:SYNC_STAGES-1];

    always @(posedge src_clk_i) begin
        sync_gray_ptr[0] <= src_gray_ptr_i;
    end

    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge dst_clk_i) begin
                sync_gray_ptr[i] <= sync_gray_ptr[i-1];
            end
        end
    endgenerate

    assign dst_gray_ptr_o = sync_gray_ptr[SYNC_STAGES-1];

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  write_i,
    input  [LOG_DEPTH-1:0] write_addr_i,
    input  [WIDTH-1:0]     write_data_i,
    input                  read_i,
    input  [LOG_DEPTH-1:0] read_addr_i,
    output [WIDTH-1:0]     read_data_o
);

    reg [WIDTH-1:0] mem [0:(1<<LOG_DEPTH)-1];
    reg [WIDTH-1:0] read_data;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            read_data <= 0;
            for (int i = 0; i < (1<<LOG_DEPTH); i = i + 1) begin
                mem[i] <= 0;
            end
        end else begin
            if (write_i) begin
                mem[write_addr_i] <= write_data_i;
            end
            if (read_i) begin
                read_data <= mem[read_addr_i];
            end
        end
    end

    assign read_data_o = read_data;

endmodule
