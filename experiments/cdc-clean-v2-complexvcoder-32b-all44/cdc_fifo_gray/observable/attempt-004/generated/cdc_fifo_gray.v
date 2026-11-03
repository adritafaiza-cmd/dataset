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
    reg [LOG_DEPTH:0]      src_gray_wptr;
    reg [LOG_DEPTH-1:0]    src_wptr;
    reg [LOG_DEPTH:0]      dst_gray_rptr;
    reg [LOG_DEPTH-1:0]    dst_rptr;
    reg [LOG_DEPTH:0]      sync_src_gray_wptr;
    reg [LOG_DEPTH-1:0]    sync_src_wptr;
    reg [LOG_DEPTH:0]      sync_dst_gray_rptr;
    reg [LOG_DEPTH-1:0]    sync_dst_rptr;
    reg                    src_write_en;
    reg                    dst_read_en;
    reg  [WIDTH-1:0]       fifo_data_out;
    wire                   src_full;
    wire                   dst_empty;

    // Source write pointer and destination read pointer generation
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) src_gray_counter (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .en(src_write_en),
        .gray_out(src_gray_wptr),
        .bin_out(src_wptr)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) dst_gray_counter (
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .en(dst_read_en),
        .gray_out(dst_gray_rptr),
        .bin_out(dst_rptr)
    );

    // Synchronization of write and read pointers
    sync_gray #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES)) sync_src_gray_wptr_inst (
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .in_gray(src_gray_wptr),
        .out_gray(sync_src_gray_wptr)
    );

    sync_gray #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES)) sync_dst_gray_rptr_inst (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .in_gray(dst_gray_rptr),
        .out_gray(sync_dst_gray_rptr)
    );

    // Conversion of synchronized Gray codes to binary
    gray_to_bin #(.LOG_DEPTH(LOG_DEPTH)) sync_src_gray_wptr_to_bin (
        .gray_in(sync_src_gray_wptr),
        .bin_out(sync_src_wptr)
    );

    gray_to_bin #(.LOG_DEPTH(LOG_DEPTH)) sync_dst_gray_rptr_to_bin (
        .gray_in(sync_dst_gray_rptr),
        .bin_out(sync_dst_rptr)
    );

    // FIFO memory
    fifo_memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_memory_inst (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .wr_en(src_write_en),
        .rd_en(dst_read_en),
        .wr_addr(src_wptr),
        .rd_addr(dst_rptr),
        .din(src_data_i),
        .dout(fifo_data_out)
    );

    // FIFO control logic
    assign src_full = (sync_src_wptr == (sync_dst_rptr + 1)) || (sync_src_wptr == {1'b1, {LOG_DEPTH{1'b0}}} && sync_dst_rptr == {LOG_DEPTH{1'b1}});
    assign dst_empty = (sync_src_wptr == sync_dst_rptr);

    assign src_write_en = src_valid_i & ~src_full;
    assign dst_read_en = dst_ready_i & ~dst_empty;

    assign src_ready_o = ~src_full;
    assign dst_valid_o = ~dst_empty;
    assign dst_data_o = fifo_data_out;

endmodule

// Gray code counter
module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_n,
    input                  en,
    output reg [LOG_DEPTH:0] gray_out,
    output reg [LOG_DEPTH-1:0] bin_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_out <= {LOG_DEPTH+1{1'b0}};
            bin_out <= {LOG_DEPTH{1'b0}};
        end else if (en) begin
            bin_out <= bin_out + 1;
            gray_out <= (bin_out + 1) ^ bin_out;
        end
    end

endmodule

// Synchronizer for Gray code
module sync_gray #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  clk,
    input                  rst_n,
    input  [LOG_DEPTH:0]   in_gray,
    output reg [LOG_DEPTH:0] out_gray
);

    reg [LOG_DEPTH:0] sync_reg [0:SYNC_STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_gray <= {LOG_DEPTH+1{1'b0}};
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= {LOG_DEPTH+1{1'b0}};
            end
        end else begin
            sync_reg[0] <= in_gray;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
            out_gray <= sync_reg[SYNC_STAGES-1];
        end
    end

endmodule

// Gray to binary converter
module gray_to_bin #(
    parameter LOG_DEPTH = 3
)(
    input  [LOG_DEPTH:0]   gray_in,
    output reg [LOG_DEPTH-1:0] bin_out
);

    integer i;

    always @(*) begin
        bin_out = gray_in[LOG_DEPTH-1];
        for (i = LOG_DEPTH-2; i >= 0; i = i - 1) begin
            bin_out[i] = bin_out[i+1] ^ gray_in[i];
        end
    end

endmodule

// FIFO memory
module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_n,
    input                  wr_en,
    input                  rd_en,
    input  [LOG_DEPTH-1:0] wr_addr,
    input  [LOG_DEPTH-1:0] rd_addr,
    input  [WIDTH-1:0]     din,
    output reg [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] mem [0:(2**LOG_DEPTH)-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {WIDTH{1'b0}};
            for (integer i = 0; i < 2**LOG_DEPTH; i = i + 1) begin
                mem[i] <= {WIDTH{1'b0}};
            end
        end else begin
            if (wr_en) begin
                mem[wr_addr] <= din;
            end
            if (rd_en) begin
                dout <= mem[rd_addr];
            end
        end
    end

endmodule
