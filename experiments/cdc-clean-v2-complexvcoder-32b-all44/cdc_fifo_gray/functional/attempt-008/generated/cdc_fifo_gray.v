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

    wire [LOG_DEPTH:0]     gray_src;
    wire [LOG_DEPTH:0]     gray_dst;
    wire [LOG_DEPTH:0]     gray_src_synced;
    wire [LOG_DEPTH:0]     gray_dst_synced;
    wire                   src_valid_synced;
    wire                   dst_ready_synced;
    wire [LOG_DEPTH:0]     wr_ptr;
    wire [LOG_DEPTH:0]     rd_ptr;
    wire [WIDTH-1:0]       wr_data;
    wire [WIDTH-1:0]       rd_data;
    wire                   src_ready;
    wire                   dst_valid;

    // Source Gray Counter
    gray_counter #(
        .WIDTH(LOG_DEPTH+1)
    ) gray_src_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .en_i(src_ready & src_valid_i),
        .load_i(1'b0),
        .load_data_i(LOG_DEPTH'(0)),
        .gray_o(gray_src)
    );

    // Destination Gray Counter
    gray_counter #(
        .WIDTH(LOG_DEPTH+1)
    ) gray_dst_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .en_i(dst_valid & dst_ready_i),
        .load_i(1'b0),
        .load_data_i(LOG_DEPTH'(0)),
        .gray_o(gray_dst)
    );

    // Synchronize Source Gray Counter to Destination Domain
    sync_register #(
        .WIDTH(LOG_DEPTH+1),
        .STAGES(SYNC_STAGES)
    ) sync_gray_src_to_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d_i(gray_src),
        .q_o(gray_src_synced)
    );

    // Synchronize Destination Gray Counter to Source Domain
    sync_register #(
        .WIDTH(LOG_DEPTH+1),
        .STAGES(SYNC_STAGES)
    ) sync_gray_dst_to_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .d_i(gray_dst),
        .q_o(gray_dst_synced)
    );

    // Synchronize Source Valid to Destination Domain
    sync_register #(
        .WIDTH(1),
        .STAGES(SYNC_STAGES)
    ) sync_src_valid_to_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d_i(src_valid_i),
        .q_o(src_valid_synced)
    );

    // Synchronize Destination Ready to Source Domain
    sync_register #(
        .WIDTH(1),
        .STAGES(SYNC_STAGES)
    ) sync_dst_ready_to_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .d_i(dst_ready_i),
        .q_o(dst_ready_synced)
    );

    // FIFO Memory
    fifo_memory #(
        .WIDTH(WIDTH),
        .DEPTH(2**LOG_DEPTH)
    ) fifo_mem (
        .wr_clk_i(src_clk_i),
        .wr_rst_ni(src_rst_ni),
        .wr_en_i(src_ready & src_valid_i),
        .wr_data_i(src_data_i),
        .rd_clk_i(dst_clk_i),
        .rd_rst_ni(dst_rst_ni),
        .rd_en_i(dst_valid & dst_ready_i),
        .rd_data_o(dst_data_o),
        .full_o(),
        .empty_o()
    );

    // Assign internal signals
    assign wr_ptr = gray_src;
    assign rd_ptr = gray_dst_synced;
    assign wr_data = src_data_i;
    assign src_ready = ~fifo_mem.full_o & ~gray_bin_eq(gray_src, gray_dst_synced);
    assign dst_valid = ~fifo_mem.empty_o & ~gray_bin_eq(gray_src_synced, gray_dst);

    // Gray code to binary comparison function
    function [LOG_DEPTH:0] gray_bin_eq;
        input [LOG_DEPTH:0] gray1;
        input [LOG_DEPTH:0] gray2;
        reg [LOG_DEPTH:0] bin1;
        reg [LOG_DEPTH:0] bin2;
        integer i;
        begin
            bin1 = gray_to_bin(gray1);
            bin2 = gray_to_bin(gray2);
            gray_bin_eq = (bin1 == bin2);
        end
    endfunction

    // Gray to binary conversion function
    function [LOG_DEPTH:0] gray_to_bin;
        input [LOG_DEPTH:0] gray;
        reg [LOG_DEPTH:0] bin;
        integer i;
        begin
            bin[LOG_DEPTH] = gray[LOG_DEPTH];
            for (i = LOG_DEPTH-1; i >= 0; i = i - 1) begin
                bin[i] = bin[i+1] ^ gray[i];
            end
            gray_to_bin = bin;
        end
    endfunction

endmodule

module gray_counter #(
    parameter WIDTH = 4
)(
    input                  clk_i,
    input                  rst_ni,
    input                  en_i,
    input                  load_i,
    input  [WIDTH-1:0]     load_data_i,
    output [WIDTH-1:0]     gray_o
);

    reg [WIDTH-1:0] bin_cnt;
    reg [WIDTH-1:0] gray_cnt;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_cnt <= {WIDTH{1'b0}};
            gray_cnt <= {WIDTH{1'b0}};
        end else if (load_i) begin
            bin_cnt <= load_data_i;
            gray_cnt <= gray_encode(load_data_i);
        end else if (en_i) begin
            bin_cnt <= bin_cnt + 1;
            gray_cnt <= gray_encode(bin_cnt + 1);
        end
    end

    assign gray_o = gray_cnt;

    // Gray encoding function
    function [WIDTH-1:0] gray_encode;
        input [WIDTH-1:0] bin;
        begin
            gray_encode = bin ^ (bin >> 1);
        end
    endfunction

endmodule

module sync_register #(
    parameter WIDTH = 1,
    parameter STAGES = 2
)(
    input                  clk_i,
    input                  rst_ni,
    input  [WIDTH-1:0]     d_i,
    output [WIDTH-1:0]     q_o
);

    reg [WIDTH-1:0] sync_reg [STAGES-1:0];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < STAGES; i = i + 1) begin
                sync_reg[i] <= {WIDTH{1'b0}};
            end
        end else begin
            sync_reg[0] <= d_i;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign q_o = sync_reg[STAGES-1];

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter DEPTH = 8
)(
    input                  wr_clk_i,
    input                  wr_rst_ni,
    input                  wr_en_i,
    input  [WIDTH-1:0]     wr_data_i,
    input                  rd_clk_i,
    input                  rd_rst_ni,
    input                  rd_en_i,
    output [WIDTH-1:0]     rd_data_o,
    output                 full_o,
    output                 empty_o
);

    reg [WIDTH-1:0] mem [DEPTH-1:0];
    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;
    reg [$clog2(DEPTH):0] wr_ptr_gray;
    reg [$clog2(DEPTH):0] rd_ptr_gray;
    reg [$clog2(DEPTH):0] wr_ptr_gray_synced;
    reg [$clog2(DEPTH):0] rd_ptr_gray_synced;
    wire full;
    wire empty;

    // Write Pointer
    always @(posedge wr_clk_i or negedge wr_rst_ni) begin
        if (!wr_rst_ni) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en_i && !full) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= gray_encode(wr_ptr + 1);
        end
    end

    // Read Pointer
    always @(posedge rd_clk_i or negedge rd_rst_ni) begin
        if (!rd_rst_ni) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en_i && !empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= gray_encode(rd_ptr + 1);
        end
    end

    // Synchronize Write Pointer to Read Domain
    sync_register #(
        .WIDTH($clog2(DEPTH)+1),
        .STAGES(2)
    ) sync_wr_ptr_to_rd (
        .clk_i(rd_clk_i),
        .rst_ni(rd_rst_ni),
        .d_i(wr_ptr_gray),
        .q_o(wr_ptr_gray_synced)
    );

    // Synchronize Read Pointer to Write Domain
    sync_register #(
        .WIDTH($clog2(DEPTH)+1),
        .STAGES(2)
    ) sync_rd_ptr_to_wr (
        .clk_i(wr_clk_i),
        .rst_ni(wr_rst_ni),
        .d_i(rd_ptr_gray),
        .q_o(rd_ptr_gray_synced)
    );

    // Write Memory
    always @(posedge wr_clk_i) begin
        if (wr_en_i && !full) begin
            mem[wr_ptr] <= wr_data_i;
        end
    end

    // Read Memory
    always @(posedge rd_clk_i) begin
        if (rd_en_i && !empty) begin
            rd_data_o <= mem[rd_ptr];
        end
    end

    // Full and Empty Flags
    assign full = gray_bin_eq(wr_ptr_gray + 1'b1, rd_ptr_gray_synced);
    assign empty = gray_bin_eq(wr_ptr_gray_synced, rd_ptr_gray + 1'b1);

    // Assign outputs
    assign full_o = full;
    assign empty_o = empty;

    // Gray code to binary comparison function
    function [$clog2(DEPTH):0] gray_bin_eq;
        input [$clog2(DEPTH):0] gray1;
        input [$clog2(DEPTH):0] gray2;
        reg [$clog2(DEPTH):0] bin1;
        reg [$clog2(DEPTH):0] bin2;
        integer i;
        begin
            bin1 = gray_to_bin(gray1);
            bin2 = gray_to_bin(gray2);
            gray_bin_eq = (bin1 == bin2);
        end
    endfunction

    // Gray to binary conversion function
    function [$clog2(DEPTH):0] gray_to_bin;
        input [$clog2(DEPTH):0] gray;
        reg [$clog2(DEPTH):0] bin;
        integer i;
        begin
            bin[$clog2(DEPTH)] = gray[$clog2(DEPTH)];
            for (i = $clog2(DEPTH)-1; i >= 0; i = i - 1) begin
                bin[i] = bin[i+1] ^ gray[i];
            end
            gray_to_bin = bin;
        end
    endfunction

    // Gray encoding function
    function [$clog2(DEPTH):0] gray_encode;
        input [$clog2(DEPTH):0] bin;
        begin
            gray_encode = bin ^ (bin >> 1);
        end
    endfunction

endmodule
