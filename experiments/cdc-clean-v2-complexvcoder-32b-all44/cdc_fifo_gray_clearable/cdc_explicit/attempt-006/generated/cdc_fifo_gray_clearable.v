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
    wire [LOG_DEPTH-1:0] src_gray;
    wire [LOG_DEPTH-1:0] dst_gray;
    wire [LOG_DEPTH-1:0] sync_gray;
    wire                 src_clear_sync;
    wire                 dst_clear_sync;
    wire                 sync_valid;
    wire                 sync_ready;
    wire                 fifo_wr_en;
    wire                 fifo_rd_en;
    wire                 fifo_empty;
    wire                 fifo_full;

    // Source Gray Counter
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) src_gray_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .count_o(src_gray),
        .wr_en_i(fifo_wr_en),
        .rd_en_i(1'b0) // No decrement from source
    );

    // Destination Gray Counter
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_gray_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .count_o(dst_gray),
        .wr_en_i(1'b0), // No increment from destination
        .rd_en_i(fifo_rd_en)
    );

    // Synchronize Gray Counter
    sync_register #(
        .WIDTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) gray_sync (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .d_i(src_gray),
        .q_o(sync_gray)
    );

    // Synchronize Clear Signal to Source Domain
    sync_register #(
        .WIDTH(1),
        .SYNC_STAGES(SYNC_STAGES)
    ) clear_sync_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .d_i(dst_clear_i),
        .q_o(src_clear_sync)
    );

    // Synchronize Clear Signal to Destination Domain
    sync_register #(
        .WIDTH(1),
        .SYNC_STAGES(SYNC_STAGES)
    ) clear_sync_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d_i(src_clear_i),
        .q_o(dst_clear_sync)
    );

    // Synchronize Valid Signal
    sync_register #(
        .WIDTH(1),
        .SYNC_STAGES(SYNC_STAGES)
    ) valid_sync (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d_i(src_valid_i),
        .q_o(sync_valid)
    );

    // Synchronize Ready Signal
    sync_register #(
        .WIDTH(1),
        .SYNC_STAGES(SYNC_STAGES)
    ) ready_sync (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .d_i(dst_ready_i),
        .q_o(sync_ready)
    );

    // FIFO Memory
    fifo_memory #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_mem (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .wr_en_i(fifo_wr_en),
        .rd_en_i(fifo_rd_en),
        .wr_addr_i(src_gray),
        .rd_addr_i(sync_gray),
        .data_i(src_data_i),
        .data_o(dst_data_o),
        .empty_o(fifo_empty),
        .full_o(fifo_full)
    );

    // Source side logic
    assign src_ready_o = ~fifo_full & ~src_clear_i;
    assign fifo_wr_en = src_valid_i & sync_ready & ~fifo_full & ~src_clear_i;
    assign src_clear_pending_o = src_clear_i | src_clear_sync;

    // Destination side logic
    assign dst_valid_o = ~fifo_empty & ~dst_clear_i & sync_valid;
    assign fifo_rd_en = dst_ready_i & ~fifo_empty & ~dst_clear_i;
    assign dst_clear_pending_o = dst_clear_i | dst_clear_sync;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    output [LOG_DEPTH-1:0] count_o,
    input                  wr_en_i,
    input                  rd_en_i
);

    reg [LOG_DEPTH-1:0] count;
    reg [LOG_DEPTH-1:0] next_count;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count <= {LOG_DEPTH{1'b0}};
        end else if (clear_i) begin
            count <= {LOG_DEPTH{1'b0}};
        end else begin
            if (wr_en_i) begin
                count <= next_count;
            end else if (rd_en_i) begin
                count <= count - 1;
            end
        end
    end

    assign next_count = count + 1;
    assign count_o = count ^ (count >> 1);

endmodule

module sync_register #(
    parameter WIDTH = 1,
    parameter SYNC_STAGES = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     d_i,
    output [WIDTH-1:0]     q_o
);

    reg [WIDTH-1:0] sync_stages [SYNC_STAGES-1:0];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_stages[i] <= {WIDTH{1'b0}};
            end
        end else begin
            sync_stages[0] <= d_i;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stages[i] <= sync_stages[i-1];
            end
        end
    end

    assign q_o = sync_stages[SYNC_STAGES-1];

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    input                  wr_en_i,
    input                  rd_en_i,
    input  [LOG_DEPTH-1:0] wr_addr_i,
    input  [LOG_DEPTH-1:0] rd_addr_i,
    input  [WIDTH-1:0]     data_i,
    output [WIDTH-1:0]     data_o,
    output                 empty_o,
    output                 full_o
);

    reg [WIDTH-1:0] memory [1 << LOG_DEPTH];
    reg [LOG_DEPTH:0] wr_ptr;
    reg [LOG_DEPTH:0] rd_ptr;
    reg [LOG_DEPTH:0] rd_ptr_gray;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else if (clear_i) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (wr_en_i && !full_o) begin
                memory[wr_addr_i] <= data_i;
                wr_ptr <= wr_ptr + 1;
            end
            if (rd_en_i && !empty_o) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);
    assign data_o = memory[rd_addr_i];
    assign empty_o = (wr_ptr == rd_ptr);
    assign full_o = (wr_ptr[LOG_DEPTH] != rd_ptr_gray[LOG_DEPTH] && wr_ptr[LOG_DEPTH-1:0] == rd_ptr_gray[LOG_DEPTH-1:0]);

endmodule
