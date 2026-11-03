module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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

    // Internal signals
    reg [WIDTH-1:0]        fifo_memory [0:(2**LOG_DEPTH)-1];
    reg [$clog2(2**LOG_DEPTH):0] src_wr_ptr, src_wr_ptr_next, src_rd_ptr_sync;
    reg [$clog2(2**LOG_DEPTH):0] dst_wr_ptr_sync, dst_rd_ptr, dst_rd_ptr_next;
    reg [1:0]                sync_src_valid, sync_dst_ready;
    reg                      async_src_valid_sync, async_dst_ready_sync;
    reg                      fifo_empty, fifo_full;
    reg [WIDTH-1:0]        fifo_dout;
    reg                      fifo_valid;

    // Synchronization flip-flops
    sync_ff sync_src_valid_ff (
        .async_in (src_valid_i),
        .clk      (dst_clk_i),
        .rst_ni   (dst_rst_ni),
        .sync_out (sync_src_valid)
    );

    sync_ff sync_dst_ready_ff (
        .async_in (dst_ready_i),
        .clk      (src_clk_i),
        .rst_ni   (src_rst_ni),
        .sync_out (sync_dst_ready)
    );

    // Assign synchronized signals
    assign async_src_valid_sync = sync_src_valid[1];
    assign async_dst_ready_sync = sync_dst_ready[1];

    // FIFO control logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
        end else begin
            src_wr_ptr <= src_wr_ptr_next;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
        end else begin
            dst_rd_ptr <= dst_rd_ptr_next;
        end
    end

    // Source side logic
    always @(*) begin
        src_wr_ptr_next = src_wr_ptr;
        if (src_valid_i && !fifo_full) begin
            src_wr_ptr_next = src_wr_ptr + 1;
        end
    end

    // Destination side logic
    always @(*) begin
        dst_rd_ptr_next = dst_rd_ptr;
        if (fifo_valid && dst_ready_i) begin
            dst_rd_ptr_next = dst_rd_ptr + 1;
        end
    end

    // FIFO memory write
    always @(posedge src_clk_i) begin
        if (src_valid_i && !fifo_full) begin
            fifo_memory[src_wr_ptr] <= src_data_i;
        end
    end

    // FIFO memory read
    always @(posedge dst_clk_i) begin
        fifo_dout <= fifo_memory[dst_rd_ptr];
    end

    // FIFO status
    always @(*) begin
        fifo_empty = (src_wr_ptr == dst_rd_ptr_sync);
        fifo_full  = (src_wr_ptr_next == dst_wr_ptr_sync);
    end

    // Synchronize pointers
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_rd_ptr_sync <= 0;
        end else begin
            src_rd_ptr_sync <= src_wr_ptr;
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_wr_ptr_sync <= 0;
        end else begin
            dst_wr_ptr_sync <= dst_rd_ptr;
        end
    end

    // Outputs
    assign src_ready_o = !fifo_full;
    assign dst_data_o = fifo_dout;
    assign fifo_valid = !fifo_empty;
    assign dst_valid_o = fifo_valid & async_src_valid_sync;

endmodule

module sync_ff (
    input  async_in,
    input  clk,
    input  rst_ni,
    output sync_out
);

    reg ff1, ff2;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            ff1 <= 0;
            ff2 <= 0;
        end else begin
            ff1 <= async_in;
            ff2 <= ff1;
        end
    end

    assign sync_out = ff2;

endmodule
