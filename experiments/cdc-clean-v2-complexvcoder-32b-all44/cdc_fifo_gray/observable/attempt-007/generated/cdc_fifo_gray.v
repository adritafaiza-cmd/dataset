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
    wire                   write_enable;
    wire                   read_enable;
    wire [LOG_DEPTH-1:0]   src_gray_wptr;
    wire [LOG_DEPTH-1:0]   dst_gray_wptr;
    wire [LOG_DEPTH-1:0]   src_gray_wptr_synced;
    wire [LOG_DEPTH-1:0]   dst_gray_rptr_synced;
    reg  [LOG_DEPTH-1:0]   src_wptr;
    reg  [LOG_DEPTH-1:0]   dst_rptr;

    // Write enable and read enable logic
    assign write_enable = src_valid_i && src_ready_o;
    assign read_enable = dst_ready_i && dst_valid_o;

    // Gray counters
    gray_counter src_gray_counter (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .inc_i  (write_enable),
        .gray_o (src_gray_wptr)
    );

    gray_counter dst_gray_counter (
        .clk_i  (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .inc_i  (read_enable),
        .gray_o (dst_gray_wptr)
    );

    // Gray synchronizers
    sync_gray_counter dst_gray_wptr_sync (
        .clk_i  (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .gray_i (src_gray_wptr),
        .gray_o (src_gray_wptr_synced)
    );

    sync_gray_counter src_gray_rptr_sync (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .gray_i (dst_gray_wptr),
        .gray_o (dst_gray_rptr_synced)
    );

    // Binary conversion of synced gray counters
    binary_from_gray src_gray_wptr_synced_bin (
        .gray_i (src_gray_wptr_synced),
        .bin_o  (src_wptr)
    );

    binary_from_gray dst_gray_rptr_synced_bin (
        .gray_i (dst_gray_rptr_synced),
        .bin_o  (dst_rptr)
    );

    // FIFO memory
    dual_port_ram fifo_memory (
        .clk_i    (src_clk_i),
        .rst_ni   (src_rst_ni),
        .we_i     (write_enable),
        .addr_a_i (src_wptr),
        .din_a_i  (src_data_i),
        .addr_b_i (dst_rptr),
        .din_b_i  (0),
        .dout_b_o (dst_data_o)
    );

    // Ready and valid logic
    reg [LOG_DEPTH:0] src_full;
    reg [LOG_DEPTH:0] dst_empty;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_full <= 0;
        end else begin
            src_full <= (src_wptr == (src_gray_wptr_synced_bin + 1));
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_empty <= 1;
        end else begin
            dst_empty <= (dst_rptr == src_gray_wptr_synced_bin);
        end
    end

    assign src_ready_o = !src_full;
    assign dst_valid_o = !dst_empty;

endmodule

module gray_counter (
    input                  clk_i,
    input                  rst_ni,
    input                  inc_i,
    output [LOG_DEPTH-1:0] gray_o
);

    reg [LOG_DEPTH-1:0] binary;
    reg [LOG_DEPTH-1:0] next_binary;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            binary <= 0;
        end else if (inc_i) begin
            binary <= next_binary;
        end
    end

    assign next_binary = binary + 1;
    assign gray_o = (binary ^ (binary >> 1));

endmodule

module sync_gray_counter #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  clk_i,
    input                  rst_ni,
    input  [LOG_DEPTH-1:0] gray_i,
    output [LOG_DEPTH-1:0] gray_o
);

    reg [LOG_DEPTH-1:0] sync_gray [0:SYNC_STAGES];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_gray[0] <= 0;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_gray[i] <= 0;
            end
        end else begin
            sync_gray[0] <= gray_i;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_gray[i] <= sync_gray[i-1];
            end
        end
    end

    assign gray_o = sync_gray[SYNC_STAGES-1];

endmodule

module dual_port_ram #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  we_i,
    input  [LOG_DEPTH-1:0] addr_a_i,
    input  [WIDTH-1:0]     din_a_i,
    input  [LOG_DEPTH-1:0] addr_b_i,
    input  [WIDTH-1:0]     din_b_i,
    output [WIDTH-1:0]     dout_b_o
);

    reg [WIDTH-1:0] memory [0:(2**LOG_DEPTH)-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < (2**LOG_DEPTH); i = i + 1) begin
                memory[i] <= 0;
            end
        end else if (we_i) begin
            memory[addr_a_i] <= din_a_i;
        end
    end

    assign dout_b_o = memory[addr_b_i];

endmodule

module binary_from_gray #(
    parameter LOG_DEPTH = 3
)(
    input  [LOG_DEPTH-1:0] gray_i,
    output [LOG_DEPTH-1:0] bin_o
);

    reg [LOG_DEPTH-1:0] bin;

    always @(*) begin
        bin[LOG_DEPTH-1] = gray_i[LOG_DEPTH-1];
        for (integer i = LOG_DEPTH-2; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray_i[i];
        end
    end

    assign bin_o = bin;

endmodule
