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
    wire [LOG_DEPTH:0] src_gray_wr_ptr;
    wire [LOG_DEPTH:0] dst_gray_rd_ptr;
    wire [LOG_DEPTH:0] dst_gray_wr_ptr_sync;
    wire [LOG_DEPTH:0] src_gray_rd_ptr_sync;
    wire src_wr_en;
    wire dst_rd_en;

    // Instantiate the gray counters for source and destination
    cdc_gray_counter_2phase src_gray_counter (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .en_i(src_wr_en),
        .gray_ptr_o(src_gray_wr_ptr)
    );

    cdc_gray_counter_2phase dst_gray_counter (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .en_i(dst_rd_en),
        .gray_ptr_o(dst_gray_rd_ptr)
    );

    // Instantiate the gray synchronizers
    cdc_gray_sync_2phase wr_ptr_sync (
        .src_clk_i(src_clk_i),
        .dst_clk_i(dst_clk_i),
        .src_gray_i(src_gray_wr_ptr),
        .dst_gray_o(dst_gray_wr_ptr_sync)
    );

    cdc_gray_sync_2phase rd_ptr_sync (
        .src_clk_i(src_clk_i),
        .dst_clk_i(dst_clk_i),
        .src_gray_i(dst_gray_rd_ptr),
        .dst_gray_o(src_gray_rd_ptr_sync)
    );

    // Instantiate the FIFO memory
    fifo_memory_2phase fifo_memory (
        .clk_i(src_clk_i),
        .wr_en_i(src_wr_en),
        .wr_ptr_i(src_gray_wr_ptr_sync),
        .data_i(src_data_i),
        .clk_o(dst_clk_i),
        .rd_ptr_i(src_gray_rd_ptr_sync),
        .data_o(dst_data_o)
    );

    // FIFO control logic
    reg [LOG_DEPTH:0] src_gray_wr_ptr_gray;
    reg [LOG_DEPTH:0] dst_gray_wr_ptr_sync_gray;
    reg [LOG_DEPTH:0] src_gray_rd_ptr_sync_gray;
    reg [LOG_DEPTH:0] dst_gray_rd_ptr_gray;

    reg [LOG_DEPTH:0] src_gray_wr_ptr_gray_sync;
    reg [LOG_DEPTH:0] dst_gray_wr_ptr_sync_gray_sync;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_wr_ptr_gray_sync <= 0;
        end else begin
            src_gray_wr_ptr_gray_sync <= src_gray_wr_ptr;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_wr_ptr_sync_gray_sync <= 0;
        end else begin
            dst_gray_wr_ptr_sync_gray_sync <= dst_gray_wr_ptr_sync;
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_wr_ptr_gray <= 0;
        end else begin
            src_gray_wr_ptr_gray <= src_gray_wr_ptr;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_wr_ptr_sync_gray <= 0;
            dst_gray_rd_ptr_gray <= 0;
            src_gray_rd_ptr_sync_gray <= 0;
        end else begin
            dst_gray_wr_ptr_sync_gray <= dst_gray_wr_ptr_sync;
            dst_gray_rd_ptr_gray <= dst_gray_rd_ptr;
            src_gray_rd_ptr_sync_gray <= src_gray_rd_ptr_sync;
        end
    end

    // Calculate the full and empty conditions
    wire full = (src_gray_wr_ptr_gray_sync == (dst_gray_wr_ptr_sync_gray_sync ^ {1'b1, {(LOG_DEPTH){1'b0}}));
    wire empty = (src_gray_rd_ptr_sync_gray == dst_gray_rd_ptr_gray);

    // Assign src_ready_o and dst_valid_o
    assign src_ready_o = ~full;
    assign dst_valid_o = ~empty;

    // Write enable logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_en <= 0;
        end else begin
            src_wr_en <= src_valid_i & src_ready_o;
        end
    end

    // Read enable logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_en <= 0;
        end else begin
            dst_rd_en <= dst_ready_i & dst_valid_o;
        end
    end

endmodule

// Gray counter module
module cdc_gray_counter_2phase (
    input  rst_ni,
    input  clk_i,
    input  en_i,
    output [LOG_DEPTH:0] gray_ptr_o
);

    reg [LOG_DEPTH:0] bin_ptr;
    reg [LOG_DEPTH:0] gray_ptr;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_ptr <= 0;
        end else if (en_i) begin
            bin_ptr <= bin_ptr + 1;
        end
    end

    assign gray_ptr = bin_ptr ^ (bin_ptr >> 1);
    assign gray_ptr_o = gray_ptr;

endmodule

// Gray synchronizer module
module cdc_gray_sync_2phase (
    input  src_clk_i,
    input  dst_clk_i,
    input  [LOG_DEPTH:0] src_gray_i,
    output [LOG_DEPTH:0] dst_gray_o
);

    reg [LOG_DEPTH:0] sync_reg1;
    reg [LOG_DEPTH:0] sync_reg2;

    always @(posedge src_clk_i) begin
        sync_reg1 <= src_gray_i;
    end

    always @(posedge dst_clk_i) begin
        sync_reg2 <= sync_reg1;
        dst_gray_o <= sync_reg2;
    end

endmodule

// FIFO memory module
module fifo_memory_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input  clk_i,
    input  wr_en_i,
    input  [LOG_DEPTH:0] wr_ptr_i,
    input  [WIDTH-1:0] data_i,
    input  clk_o,
    input  [LOG_DEPTH:0] rd_ptr_i,
    output [WIDTH-1:0] data_o
);

    reg [WIDTH-1:0] memory [0:(2**LOG_DEPTH)-1];

    always @(posedge clk_i) begin
        if (wr_en_i) begin
            memory[wr_ptr_i[LOG_DEPTH-1:0]] <= data_i;
        end
    end

    always @(posedge clk_o) begin
        data_o <= memory[rd_ptr_i[LOG_DEPTH-1:0]];
    end

endmodule
