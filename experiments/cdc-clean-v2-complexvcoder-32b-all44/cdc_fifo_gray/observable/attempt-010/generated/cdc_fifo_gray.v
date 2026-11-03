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

    localparam DEPTH = 2 ** LOG_DEPTH;
    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Internal signals
    reg [PTR_WIDTH-1:0] src_gray_wptr, src_gray_wptr_sync, src_bin_wptr;
    reg [PTR_WIDTH-1:0] dst_gray_rptr, dst_gray_rptr_sync, dst_bin_rptr;
    reg [WIDTH-1:0] fifo_data;
    reg full, empty;

    // Source side logic
    gray_counter src_gray_counter (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .en(src_ready_o),
        .count(src_gray_wptr)
    );

    gray_to_bin src_gray_to_bin (
        .gray(src_gray_wptr),
        .bin(src_bin_wptr)
    );

    sync_chain sync_wptr (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .async_in(src_gray_wptr),
        .sync_out(src_gray_wptr_sync)
    );

    // Destination side logic
    gray_counter dst_gray_counter (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .en(dst_ready_i),
        .count(dst_gray_rptr)
    );

    gray_to_bin dst_gray_to_bin (
        .gray(dst_gray_rptr),
        .bin(dst_bin_rptr)
    );

    sync_chain sync_rptr (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .async_in(dst_gray_rptr),
        .sync_out(dst_gray_rptr_sync)
    );

    // FIFO memory
    fifo_memory fifo_mem (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .wr_en(src_ready_o),
        .rd_en(dst_ready_i),
        .wr_addr(src_bin_wptr),
        .rd_addr(dst_bin_rptr),
        .din(src_data_i),
        .dout(fifo_data)
    );

    // FIFO control signals
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            full <= 1'b0;
        end else begin
            full <= (src_gray_wptr_sync[PTR_WIDTH-2:0] == dst_gray_rptr[PTR_WIDTH-2:0]) && (src_gray_wptr_sync[PTR_WIDTH-1] != dst_gray_rptr[PTR_WIDTH-1]);
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            empty <= 1'b1;
        end else begin
            empty <= (src_gray_wptr_sync[PTR_WIDTH-2:0] == dst_gray_rptr[PTR_WIDTH-2:0]) && (src_gray_wptr_sync[PTR_WIDTH-1] == dst_gray_rptr[PTR_WIDTH-1]);
        end
    end

    assign src_ready_o = !full;
    assign dst_valid_o = !empty;
    assign dst_data_o = fifo_data;

endmodule

module gray_counter (
    input clk,
    input rst_ni,
    input en,
    output reg [LOG_DEPTH:0] count
);

    reg [LOG_DEPTH:0] bin_count;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_count <= 0;
        end else if (en) begin
            bin_count <= bin_count + 1;
        end
    end

    always @(*) begin
        count = bin_count ^ (bin_count >> 1);
    end

endmodule

module gray_to_bin (
    input [LOG_DEPTH:0] gray,
    output reg [LOG_DEPTH:0] bin
);

    integer i;
    always @(*) begin
        bin = gray[LOG_DEPTH];
        for (i = LOG_DEPTH - 1; i >= 0; i = i - 1) begin
            bin[i] = bin[i + 1] ^ gray[i];
        end
    end

endmodule

module bin_to_gray (
    input [LOG_DEPTH:0] bin,
    output reg [LOG_DEPTH:0] gray
);

    always @(*) begin
        gray = bin ^ (bin >> 1);
    end

endmodule

module sync_chain #(
    parameter WIDTH = LOG_DEPTH + 1,
    parameter STAGES = SYNC_STAGES
)(
    input clk,
    input rst_ni,
    input [WIDTH-1:0] async_in,
    output reg [WIDTH-1:0] sync_out
);

    reg [WIDTH-1:0] sync_chain [0:STAGES-1];

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_out <= 0;
            for (integer i = 0; i < STAGES; i = i + 1) begin
                sync_chain[i] <= 0;
            end
        end else begin
            sync_chain[0] <= async_in;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_chain[i] <= sync_chain[i-1];
            end
            sync_out <= sync_chain[STAGES-1];
        end
    end

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter DEPTH = 2 ** LOG_DEPTH
)(
    input clk,
    input rst_ni,
    input wr_en,
    input rd_en,
    input [LOG_DEPTH:0] wr_addr,
    input [LOG_DEPTH:0] rd_addr,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] memory [0:DEPTH-1];

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                memory[i] <= 0;
            end
            dout <= 0;
        end else begin
            if (wr_en) begin
                memory[wr_addr] <= din;
            end
            if (rd_en) begin
                dout <= memory[rd_addr];
            end
        end
    end

endmodule
