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

    wire [LOG_DEPTH:0] gray_src, gray_dst;
    wire [LOG_DEPTH-1:0] src_wr_ptr, dst_rd_ptr;
    wire fifo_wr_en;
    wire [WIDTH-1:0] fifo_data_out, fifo_data_sync_0;
    wire [LOG_DEPTH:0] gray_src_sync, gray_dst_sync;

    // Source Gray Code Counter
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_src_counter (
        .gray  (gray_src),
        .count (src_wr_ptr),
        .clk   (src_clk_i),
        .rst_n (src_rst_ni)
    );

    // Destination Gray Code Counter
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_dst_counter (
        .gray  (gray_dst),
        .count (dst_rd_ptr),
        .clk   (dst_clk_i),
        .rst_n (dst_rst_ni)
    );

    // Synchronize Gray Code from Source to Destination
    sync_register #(.WIDTH(LOG_DEPTH+1)) sync_gray_src_to_dst (
        .data_in  (gray_src),
        .data_out (gray_src_sync),
        .clk      (dst_clk_i),
        .rst_n    (dst_rst_ni)
    );

    // Synchronize Gray Code from Destination to Source
    sync_register #(.WIDTH(LOG_DEPTH+1)) sync_gray_dst_to_src (
        .data_in  (gray_dst),
        .data_out (gray_dst_sync),
        .clk      (src_clk_i),
        .rst_n    (src_rst_ni)
    );

    // FIFO Memory Array
    memory_array #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_memory (
        .clk      (src_clk_i),
        .rst_n    (src_rst_ni),
        .wr_en    (fifo_wr_en),
        .wr_addr  (src_wr_ptr),
        .din      (src_data_i),
        .rd_addr  (dst_rd_ptr),
        .dout     (fifo_data_out)
    );

    // First stage of FIFO data synchronization
    sync_register #(.WIDTH(WIDTH)) sync_fifo_data_out_0 (
        .data_in  (fifo_data_out),
        .data_out (fifo_data_sync_0),
        .clk      (dst_clk_i),
        .rst_n    (dst_rst_ni)
    );

    // Second stage of FIFO data synchronization
    sync_register #(.WIDTH(WIDTH)) sync_fifo_data_out_1 (
        .data_in  (fifo_data_sync_0),
        .data_out (dst_data_o),
        .clk      (dst_clk_i),
        .rst_n    (dst_rst_ni)
    );

    // FIFO Write Enable
    assign fifo_wr_en = src_valid_i && src_ready_o;

    // Source Ready Output
    assign src_ready_o = !(gray_src_sync[LOG_DEPTH] ^ gray_src[LOG_DEPTH]) && (gray_src_sync[LOG_DEPTH-1:0] != gray_src[LOG_DEPTH-1:0]);

    // Destination Valid Output
    assign dst_valid_o = !(gray_dst_sync[LOG_DEPTH] ^ gray_dst[LOG_DEPTH]) && (gray_dst_sync[LOG_DEPTH-1:0] != gray_dst[LOG_DEPTH-1:0]);

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    output [LOG_DEPTH:0] gray,
    output [LOG_DEPTH-1:0] count,
    input                  clk,
    input                  rst_n
);

    reg [LOG_DEPTH-1:0] cnt_reg;
    reg [LOG_DEPTH:0] gray_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_reg <= '0;
            gray_reg <= '0;
        end else begin
            cnt_reg <= cnt_reg + 1;
            gray_reg <= {cnt_reg[LOG_DEPTH-1] ^ cnt_reg[LOG_DEPTH-2:0], cnt_reg[LOG_DEPTH-1:0]};
        end
    end

    assign count = cnt_reg;
    assign gray = gray_reg;

endmodule

module sync_register #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out,
    input              clk,
    input              rst_n
);

    reg [WIDTH-1:0] sync_reg_0, sync_reg_1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg_0 <= '0;
            sync_reg_1 <= '0;
        end else begin
            sync_reg_0 <= data_in;
            sync_reg_1 <= sync_reg_0;
        end
    end

    assign data_out = sync_reg_1;

endmodule

module memory_array #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_n,
    input                  wr_en,
    input  [LOG_DEPTH-1:0] wr_addr,
    input  [WIDTH-1:0]     din,
    input  [LOG_DEPTH-1:0] rd_addr,
    output [WIDTH-1:0]     dout
);

    reg [WIDTH-1:0] mem [0:(2**LOG_DEPTH)-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < (2**LOG_DEPTH); i = i + 1) begin
                mem[i] <= '0;
            end
        end else if (wr_en) begin
            mem[wr_addr] <= din;
        end
    end

    assign dout = mem[rd_addr];

endmodule
