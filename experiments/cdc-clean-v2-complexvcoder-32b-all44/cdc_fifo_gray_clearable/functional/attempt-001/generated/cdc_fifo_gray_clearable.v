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
    reg                    src_clear_active;
    reg                    dst_clear_active;
    reg                    src_clear_pending;
    reg                    dst_clear_pending;
    reg                    src_ready;
    reg                    dst_valid;

    // Gray counters and synchronizers
    wire [LOG_DEPTH-1:0]   src_gray_count;
    wire [LOG_DEPTH-1:0]   src_binary_count;
    wire [LOG_DEPTH-1:0]   dst_gray_count;
    wire [LOG_DEPTH-1:0]   dst_binary_count;
    wire [LOG_DEPTH-1:0]   sync_src_gray;
    wire [LOG_DEPTH-1:0]   sync_dst_gray;

    // Gray counters
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) gray_src_counter (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .sync_gray_i(sync_dst_gray),
        .gray_count_o(src_gray_count),
        .binary_count_o(src_binary_count)
    );

    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) gray_dst_counter (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .sync_gray_i(sync_src_gray),
        .gray_count_o(dst_gray_count),
        .binary_count_o(dst_binary_count)
    );

    // Synchronizers
    sync_register #(
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_src_gray_reg (
        .rst_ni(src_rst_ni),
        .clk_i(dst_clk_i),
        .data_i(src_gray_count),
        .data_o(sync_src_gray)
    );

    sync_register #(
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_dst_gray_reg (
        .rst_ni(dst_rst_ni),
        .clk_i(src_clk_i),
        .data_i(dst_gray_count),
        .data_o(sync_dst_gray)
    );

    // RAM
    ram #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_ram (
        .src_rst_ni(src_rst_ni),
        .src_clk_i(src_clk_i),
        .src_addr_i(src_binary_count),
        .src_we_i(src_ready & src_valid_i & ~src_clear_active),
        .src_data_i(src_data_i),
        .dst_rst_ni(dst_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_addr_i(dst_binary_count),
        .dst_data_o(dst_data_o)
    );

    // Clear control logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_clear_active <= 0;
            src_clear_pending <= 0;
        end else begin
            if (src_clear_i) begin
                src_clear_active <= 1;
                src_clear_pending <= 1;
            end else if (src_clear_active && (src_gray_count == sync_dst_gray)) begin
                src_clear_active <= 0;
                src_clear_pending <= 0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_clear_active <= 0;
            dst_clear_pending <= 0;
        end else begin
            if (dst_clear_i) begin
                dst_clear_active <= 1;
                dst_clear_pending <= 1;
            end else if (dst_clear_active && (dst_gray_count == sync_src_gray)) begin
                dst_clear_active <= 0;
                dst_clear_pending <= 0;
            end
        end
    end

    // Ready and valid logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready <= 0;
        end else begin
            if (src_clear_active) begin
                src_ready <= 0;
            end else begin
                src_ready <= (src_gray_count != sync_dst_gray);
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid <= 0;
        end else begin
            if (dst_clear_active) begin
                dst_valid <= 0;
            end else begin
                dst_valid <= (dst_gray_count != sync_src_gray);
            end
        end
    end

    // Output assignments
    assign src_clear_pending_o = src_clear_pending;
    assign src_ready_o = src_ready & ~src_clear_active;
    assign dst_clear_pending_o = dst_clear_pending;
    assign dst_valid_o = dst_valid & ~dst_clear_active;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input  [LOG_DEPTH-1:0] sync_gray_i,
    output [LOG_DEPTH-1:0] gray_count_o,
    output [LOG_DEPTH-1:0] binary_count_o
);

    reg [LOG_DEPTH-1:0] binary_count;
    reg [LOG_DEPTH-1:0] gray_count;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            binary_count <= 0;
            gray_count <= 0;
        end else begin
            if (binary_count != sync_gray_i) begin
                binary_count <= binary_count + 1;
                gray_count <= (binary_count + 1) ^ (binary_count + 1 >> 1);
            end
        end
    end

    assign gray_count_o = gray_count;
    assign binary_count_o = binary_count;

endmodule

module sync_register #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input  [LOG_DEPTH-1:0] data_i,
    output [LOG_DEPTH-1:0] data_o
);

    reg [LOG_DEPTH-1:0] sync_reg [0:SYNC_STAGES-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= 0;
            end
        end else begin
            sync_reg[0] <= data_i;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign data_o = sync_reg[SYNC_STAGES-1];

endmodule

module ram #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [LOG_DEPTH-1:0] src_addr_i,
    input                  src_we_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input  [LOG_DEPTH-1:0] dst_addr_i,
    output [WIDTH-1:0]     dst_data_o
);

    reg [WIDTH-1:0] memory [0:(2**LOG_DEPTH)-1];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (int i = 0; i < (2**LOG_DEPTH); i = i + 1) begin
                memory[i] <= 0;
            end
        end else if (src_we_i) begin
            memory[src_addr_i] <= src_data_i;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= 0;
        end else begin
            dst_data_o <= memory[dst_addr_i];
        end
    end

endmodule
