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
    wire [LOG_DEPTH:0]     src_gray_count;
    wire [LOG_DEPTH:0]     dst_gray_count;
    wire [LOG_DEPTH:0]     sync_wptr_data_out;
    wire [LOG_DEPTH:0]     sync_rptr_data_out;

    // Gray counters
    gray_counter #(.COUNT_WIDTH(LOG_DEPTH+1)) src_gray_counter (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .async_gray_count(sync_wptr_data_out),
        .gray_count(src_gray_count),
        .binary_count()
    );

    gray_counter #(.COUNT_WIDTH(LOG_DEPTH+1)) dst_gray_counter (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .async_gray_count(sync_rptr_data_out),
        .gray_count(dst_gray_count),
        .binary_count()
    );

    // Sync registers
    sync_register #(.DATA_WIDTH(LOG_DEPTH+1), .SYNC_STAGES(SYNC_STAGES)) sync_wptr (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_in(src_gray_count),
        .data_out(sync_wptr_data_out)
    );

    sync_register #(.DATA_WIDTH(LOG_DEPTH+1), .SYNC_STAGES(SYNC_STAGES)) sync_rptr (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_in(dst_gray_count),
        .data_out(sync_rptr_data_out)
    );

    // FIFO memory
    fifo_memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_mem (
        .src_clk_i(src_clk_i),
        .src_rst_ni(src_rst_ni),
        .data_in(src_data_i),
        .wr_addr(src_gray_count[LOG_DEPTH:0]),
        .wr_en(src_valid_i),
        .wr_ready(src_ready_o),
        .dst_clk_i(dst_clk_i),
        .dst_rst_ni(dst_rst_ni),
        .data_out(dst_data_o),
        .rd_addr(dst_gray_count[LOG_DEPTH:0]),
        .rd_en(dst_valid_o & dst_ready_i),
        .rd_ready(dst_valid_o)
    );

endmodule

module gray_counter #(
    parameter COUNT_WIDTH = 4
)(
    input                  clk,
    input                  rst_ni,
    input  [COUNT_WIDTH-1:0] async_gray_count,
    output [COUNT_WIDTH-1:0] gray_count,
    output [COUNT_WIDTH-1:0] binary_count
);

    reg [COUNT_WIDTH-1:0] current_count;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            current_count <= '0;
        end else begin
            current_count <= async_gray_count;
        end
    end

    assign gray_count = (current_count >> 1) ^ current_count;
    assign binary_count = current_count;

endmodule

module sync_register #(
    parameter DATA_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input                  clk,
    input                  rst_ni,
    input  [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH-1:0] data_out
);

    reg [DATA_WIDTH-1:0] sync_stage [0:SYNC_STAGES-1];

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= '0;
            end
        end else begin
            sync_stage[0] <= data_in;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= sync_stage[i-1];
            end
        end
    end

    assign data_out = sync_stage[SYNC_STAGES-1];

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_clk_i,
    input                  src_rst_ni,
    input  [WIDTH-1:0]     data_in,
    input  [LOG_DEPTH:0]   wr_addr,
    input                  wr_en,
    output                 wr_ready,
    input                  dst_clk_i,
    input                  dst_rst_ni,
    output [WIDTH-1:0]     data_out,
    input  [LOG_DEPTH:0]   rd_addr,
    input                  rd_en,
    output                 rd_ready
);

    reg [WIDTH-1:0] memory [0:(2**LOG_DEPTH)-1];
    reg [LOG_DEPTH:0] wr_ptr;
    reg [LOG_DEPTH:0] rd_ptr;
    reg [LOG_DEPTH:0] rd_ptr_gray;
    reg [LOG_DEPTH:0] wr_ptr_gray;
    reg [LOG_DEPTH:0] rd_ptr_gray_sync;
    reg [LOG_DEPTH:0] wr_ptr_gray_sync;

    // Write port
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= '0;
        end else if (wr_en && wr_ready) begin
            memory[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Write ready
    assign wr_ready = (wr_ptr_gray_sync != {wr_ptr[LOG_DEPTH], wr_ptr[LOG_DEPTH-1:0] + 1'b1});

    // Read port
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= '0;
        end else if (rd_en && rd_ready) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Read data
    assign data_out = memory[rd_ptr];

    // Read ready
    assign rd_ready = (rd_ptr_gray_sync != wr_ptr_gray_sync);

    // Gray code conversion for pointers
    assign wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;
    assign rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;

    // Synchronize write pointer to destination domain
    sync_register #(.DATA_WIDTH(LOG_DEPTH+1), .SYNC_STAGES(SYNC_STAGES)) sync_wr_ptr (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_in(wr_ptr_gray),
        .data_out(wr_ptr_gray_sync)
    );

    // Synchronize read pointer to source domain
    sync_register #(.DATA_WIDTH(LOG_DEPTH+1), .SYNC_STAGES(SYNC_STAGES)) sync_rd_ptr (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_in(rd_ptr_gray),
        .data_out(rd_ptr_gray_sync)
    );

endmodule
