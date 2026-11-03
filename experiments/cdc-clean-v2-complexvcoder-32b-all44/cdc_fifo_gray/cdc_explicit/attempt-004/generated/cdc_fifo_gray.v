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

    // Internal signals
    wire [LOG_DEPTH:0] gray_wr_ptr;
    wire [LOG_DEPTH:0] gray_rd_ptr;
    wire [LOG_DEPTH:0] sync_wr_ptr;
    wire [LOG_DEPTH:0] sync_rd_ptr;
    wire [LOG_DEPTH-1:0] wr_ptr_bin;
    wire [LOG_DEPTH-1:0] rd_ptr_bin;
    wire [WIDTH-1:0] fifo_data;
    wire full;
    wire empty;
    wire valid;

    // Write enable and read enable
    wire wr_en;
    wire rd_en;

    // Gray code counters
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_src_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .inc_i(wr_en),
        .gray_o(gray_wr_ptr)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_dst_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .inc_i(rd_en),
        .gray_o(gray_rd_ptr)
    );

    // Synchronizers for Gray code pointers
    sync_gray #(.LOG_DEPTH(LOG_DEPTH)) wr_sync (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .async_i(gray_wr_ptr),
        .sync_o(sync_wr_ptr)
    );

    sync_gray #(.LOG_DEPTH(LOG_DEPTH)) rd_sync (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .async_i(gray_rd_ptr),
        .sync_o(sync_rd_ptr)
    );

    // FIFO memory
    fifo_memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_mem (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .wr_en_i(wr_en),
        .wr_addr_i(wr_ptr_bin),
        .din_i(src_data_i),
        .rd_clk_i(dst_clk_i),
        .rd_en_i(rd_en),
        .rd_addr_i(rd_ptr_bin),
        .dout_o(fifo_data)
    );

    // Binary conversion for write and read pointers
    binary_conversion #(.LOG_DEPTH(LOG_DEPTH)) bin_conv_wr (
        .gray_i(gray_wr_ptr),
        .bin_o(wr_ptr_bin)
    );

    binary_conversion #(.LOG_DEPTH(LOG_DEPTH)) bin_conv_rd (
        .gray_i(gray_rd_ptr),
        .bin_o(rd_ptr_bin)
    );

    // Write enable and read enable logic
    assign wr_en = src_valid_i & src_ready_o;
    assign rd_en = dst_valid_o & dst_ready_i;

    // FIFO control logic
    fifo_control #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES)) fifo_ctrl (
        .src_clk_i(src_clk_i),
        .src_rst_ni(src_rst_ni),
        .dst_clk_i(dst_clk_i),
        .dst_rst_ni(dst_rst_ni),
        .wr_ptr_bin(wr_ptr_bin),
        .rd_ptr_bin(rd_ptr_bin),
        .sync_wr_ptr(sync_wr_ptr),
        .sync_rd_ptr(sync_rd_ptr),
        .src_ready_o(src_ready_o),
        .dst_data_o(fifo_data),
        .dst_valid_o(dst_valid_o),
        .full(full),
        .empty(empty),
        .valid(valid)
    );

endmodule

// Gray code counter
module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input clk_i,
    input rst_ni,
    input inc_i,
    output reg [LOG_DEPTH:0] gray_o
);

    reg [LOG_DEPTH:0] bin_cnt;
    reg [LOG_DEPTH:0] gray_cnt;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_cnt <= 0;
            gray_cnt <= 0;
            gray_o <= 0;
        end else begin
            if (inc_i) begin
                bin_cnt <= bin_cnt + 1;
                gray_cnt <= bin_cnt ^ (bin_cnt >> 1);
                gray_o <= gray_cnt;
            end
        end
    end

endmodule

// Synchronizer for Gray code pointers
module sync_gray #(
    parameter LOG_DEPTH = 3
)(
    input clk_i,
    input rst_ni,
    input [LOG_DEPTH:0] async_i,
    output reg [LOG_DEPTH:0] sync_o
);

    reg [LOG_DEPTH:0] sync_stages [0:SYNC_STAGES-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_o <= 0;
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_stages[i] <= 0;
            end
        end else begin
            sync_stages[0] <= async_i;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stages[i] <= sync_stages[i-1];
            end
            sync_o <= sync_stages[SYNC_STAGES-1];
        end
    end

endmodule

// FIFO memory
module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input clk_i,
    input rst_ni,
    input wr_en_i,
    input [LOG_DEPTH-1:0] wr_addr_i,
    input [WIDTH-1:0] din_i,
    input rd_clk_i,
    input rd_en_i,
    input [LOG_DEPTH-1:0] rd_addr_i,
    output reg [WIDTH-1:0] dout_o
);

    reg [WIDTH-1:0] memory [0:(2**LOG_DEPTH)-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 2**LOG_DEPTH; i = i + 1) begin
                memory[i] <= 0;
            end
        end else begin
            if (wr_en_i) begin
                memory[wr_addr_i] <= din_i;
            end
        end
    end

    always @(posedge rd_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            dout_o <= 0;
        end else begin
            if (rd_en_i) begin
                dout_o <= memory[rd_addr_i];
            end
        end
    end

endmodule

// Binary conversion from Gray code
module binary_conversion #(
    parameter LOG_DEPTH = 3
)(
    input [LOG_DEPTH:0] gray_i,
    output reg [LOG_DEPTH-1:0] bin_o
);

    always @(*) begin
        bin_o = gray_i ^ (gray_i >> 1);
    end

endmodule

// FIFO control logic
module fifo_control #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input src_clk_i,
    input src_rst_ni,
    input dst_clk_i,
    input dst_rst_ni,
    input [LOG_DEPTH-1:0] wr_ptr_bin,
    input [LOG_DEPTH-1:0] rd_ptr_bin,
    input [LOG_DEPTH:0] sync_wr_ptr,
    input [LOG_DEPTH:0] sync_rd_ptr,
    output reg src_ready_o,
    input [WIDTH-1:0] dst_data_o,
    output reg dst_valid_o,
    output reg full,
    output reg empty,
    output reg valid
);

    reg [LOG_DEPTH:0] wr_ptr_sync;
    reg [LOG_DEPTH:0] rd_ptr_sync;

    // Synchronize write pointer to destination domain
    sync_gray #(.LOG_DEPTH(LOG_DEPTH)) wr_sync_ctrl (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .async_i({1'b0, wr_ptr_bin}),
        .sync_o(wr_ptr_sync)
    );

    // Synchronize read pointer to source domain
    sync_gray #(.LOG_DEPTH(LOG_DEPTH)) rd_sync_ctrl (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .async_i({1'b0, rd_ptr_bin}),
        .sync_o(rd_ptr_sync)
    );

    // Source ready logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o <= 1;
        end else begin
            src_ready_o <= (wr_ptr_sync != {1'b0, wr_ptr_bin} + 1);
        end
    end

    // Full flag
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            full <= 0;
        end else begin
            full <= (wr_ptr_sync == {1'b0, wr_ptr_bin} + 1);
        end
    end

    // Destination valid logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 0;
            valid <= 0;
        end else begin
            if (rd_ptr_sync != sync_wr_ptr) begin
                dst_valid_o <= 1;
                valid <= 1;
            end else begin
                dst_valid_o <= 0;
                valid <= 0;
            end
        end
    end

    // Empty flag
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            empty <= 1;
        end else begin
            empty <= (sync_wr_ptr == sync_rd_ptr);
        end
    end

endmodule
