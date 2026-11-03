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
    reg [LOG_DEPTH:0]      src_gray_counter_gray_o;
    reg [LOG_DEPTH:0]      dst_gray_counter_gray_o;
    reg [LOG_DEPTH:0]      gray_sync_src_to_dst_dst_gray_o;
    reg [LOG_DEPTH:0]      gray_sync_dst_to_src_dst_gray_o;
    reg [LOG_DEPTH-1:0]    src_wr_addr;
    reg [LOG_DEPTH-1:0]    dst_rd_addr;
    reg                    src_wr_en;
    reg                    dst_rd_en;
    reg [WIDTH-1:0]        fifo_memory_inst_data_o;
    reg                    fifo_memory_inst_empty_o;

    // Clear pending signals
    reg                    src_clear_pending;
    reg                    dst_clear_pending;

    // Clear signals for counters
    reg                    src_clear;
    reg                    dst_clear;

    // Source Gray Counter
    gray_counter #(
        .WIDTH(LOG_DEPTH + 1)
    ) src_gray_counter (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear),
        .en(src_wr_en),
        .gray_o(src_gray_counter_gray_o)
    );

    // Destination Gray Counter
    gray_counter #(
        .WIDTH(LOG_DEPTH + 1)
    ) dst_gray_counter (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear),
        .en(dst_rd_en),
        .gray_o(dst_gray_counter_gray_o)
    );

    // Gray Code Synchronization from Source to Destination
    gray_sync #(
        .WIDTH(LOG_DEPTH + 1),
        .SYNC_STAGES(SYNC_STAGES)
    ) gray_sync_src_to_dst (
        .src_clk(src_clk_i),
        .src_gray(src_gray_counter_gray_o),
        .dst_clk(dst_clk_i),
        .dst_gray(gray_sync_src_to_dst_dst_gray_o)
    );

    // Gray Code Synchronization from Destination to Source
    gray_sync #(
        .WIDTH(LOG_DEPTH + 1),
        .SYNC_STAGES(SYNC_STAGES)
    ) gray_sync_dst_to_src (
        .src_clk(dst_clk_i),
        .src_gray(dst_gray_counter_gray_o),
        .dst_clk(src_clk_i),
        .dst_gray(gray_sync_dst_to_src_dst_gray_o)
    );

    // FIFO Memory
    fifo_memory #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_memory_inst (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .wr_en(src_wr_en),
        .wr_addr(src_wr_addr),
        .data_i(src_data_i),
        .rd_clk(dst_clk_i),
        .rd_rst_ni(dst_rst_ni),
        .rd_en(dst_rd_en),
        .rd_addr(dst_rd_addr),
        .data_o(fifo_memory_inst_data_o),
        .empty_o(fifo_memory_inst_empty_o)
    );

    // Source clear pending logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_pending <= 0;
        end else begin
            if (src_clear_i) begin
                src_clear_pending <= 1;
            end else if (src_clear) begin
                src_clear_pending <= 0;
            end
        end
    end

    // Destination clear pending logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_pending <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_pending <= 1;
            end else if (dst_clear) begin
                dst_clear_pending <= 0;
            end
        end
    end

    // Source clear logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear <= 0;
        end else begin
            src_clear <= src_clear_i;
        end
    end

    // Destination clear logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear <= 0;
        end else begin
            dst_clear <= dst_clear_i;
        end
    end

    // Write enable logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_en <= 0;
        end else begin
            src_wr_en <= src_valid_i && !src_clear;
        end
    end

    // Read enable logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_en <= 0;
        end else begin
            dst_rd_en <= dst_ready_i && !dst_clear;
        end
    end

    // Address assignment
    assign src_wr_addr = src_gray_counter_gray_o[LOG_DEPTH-1:0];
    assign dst_rd_addr = gray_sync_src_to_dst_dst_gray_o[LOG_DEPTH-1:0];

    // Output assignments
    assign src_clear_pending_o = src_clear_pending;
    assign src_ready_o = fifo_memory_inst_empty_o && !src_clear;
    assign dst_clear_pending_o = dst_clear_pending;
    assign dst_data_o = fifo_memory_inst_data_o;
    assign dst_valid_o = !fifo_memory_inst_empty_o && !dst_clear;

endmodule

// Gray Counter Module
module gray_counter #(
    parameter WIDTH = 4
)(
    input                  clk,
    input                  rst_ni,
    input                  clear_i,
    input                  en,
    output reg [WIDTH-1:0] gray_o
);

    reg [WIDTH-1:0] bin;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            bin <= 0;
            gray_o <= 0;
        end else if (clear_i) begin
            bin <= 0;
            gray_o <= 0;
        end else if (en) begin
            bin <= bin + 1;
            gray_o <= bin ^ (bin >> 1);
        end
    end

endmodule

// Gray Sync Module
module gray_sync #(
    parameter WIDTH = 4,
    parameter SYNC_STAGES = 3
)(
    input                  src_clk,
    input  [WIDTH-1:0]     src_gray,
    input                  dst_clk,
    output reg [WIDTH-1:0] dst_gray
);

    reg [WIDTH-1:0] sync_reg [SYNC_STAGES-1:0];

    // Synchronize gray code from src_clk domain to dst_clk domain
    always @(posedge src_clk) begin
        sync_reg[0] <= src_gray;
    end

    generate
        genvar i;
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : gen_sync_stages
            always @(posedge dst_clk) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    endgenerate

    always @(posedge dst_clk) begin
        dst_gray <= sync_reg[SYNC_STAGES-1];
    end

endmodule

// FIFO Memory Module
module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_ni,
    input                  wr_en,
    input  [LOG_DEPTH-1:0] wr_addr,
    input  [WIDTH-1:0]     data_i,
    input                  rd_clk,
    input                  rd_rst_ni,
    input                  rd_en,
    input  [LOG_DEPTH-1:0] rd_addr,
    output reg [WIDTH-1:0] data_o,
    output reg             empty_o
);

    reg [WIDTH-1:0] mem [0:(1 << LOG_DEPTH) - 1];

    // Write operation
    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            // No initialization needed for memory
        end else if (wr_en) begin
            mem[wr_addr] <= data_i;
        end
    end

    // Read operation
    always @(posedge rd_clk or negedge rd_rst_ni) begin
        if (!rd_rst_ni) begin
            data_o <= 0;
            empty_o <= 1;
        end else begin
            data_o <= mem[rd_addr];
            empty_o <= (wr_addr == rd_addr) && !wr_en && rd_en;
        end
    end

endmodule
