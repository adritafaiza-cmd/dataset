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
    wire [LOG_DEPTH:0] src_gray;
    wire [LOG_DEPTH:0] dst_gray;
    wire [LOG_DEPTH:0] sync_gray_src_to_dst;
    wire [LOG_DEPTH:0] sync_gray_dst_to_src;
    wire [LOG_DEPTH-1:0] src_gray_bin;
    wire [LOG_DEPTH-1:0] dst_gray_bin;
    wire [LOG_DEPTH-1:0] sync_gray_bin_src_to_dst;
    wire [LOG_DEPTH-1:0] sync_gray_bin_dst_to_src;
    wire src_full;
    wire src_empty;
    wire dst_full;
    wire dst_empty;
    wire src_clear_active;
    wire dst_clear_active;

    // Gray counters for source and destination
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_active),
        .increment_i(src_valid_i & src_ready_o),
        .gray_o(src_gray)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_active),
        .increment_i(dst_valid_o & dst_ready_i),
        .gray_o(dst_gray)
    );

    // Synchronize Gray codes between source and destination
    sync_ffs #(.WIDTH(LOG_DEPTH+1), .SYNC_STAGES(SYNC_STAGES)) sync_ffs_src_to_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d_i(src_gray),
        .q_o(sync_gray_src_to_dst)
    );

    sync_ffs #(.WIDTH(LOG_DEPTH+1), .SYNC_STAGES(SYNC_STAGES)) sync_ffs_dst_to_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .d_i(dst_gray),
        .q_o(sync_gray_dst_to_src)
    );

    // Convert Gray codes to binary
    gray_to_bin #(.LOG_DEPTH(LOG_DEPTH)) gray_to_bin_src (
        .gray_i(src_gray),
        .bin_o(src_gray_bin)
    );

    gray_to_bin #(.LOG_DEPTH(LOG_DEPTH)) gray_to_bin_sync_src_to_dst (
        .gray_i(sync_gray_src_to_dst),
        .bin_o(sync_gray_bin_src_to_dst)
    );

    gray_to_bin #(.LOG_DEPTH(LOG_DEPTH)) gray_to_bin_dst (
        .gray_i(dst_gray),
        .bin_o(dst_gray_bin)
    );

    gray_to_bin #(.LOG_DEPTH(LOG_DEPTH)) gray_to_bin_sync_dst_to_src (
        .gray_i(sync_gray_dst_to_src),
        .bin_o(sync_gray_bin_dst_to_src)
    );

    // FIFO memory
    fifo_memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_mem (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_active),
        .write_i(src_valid_i & src_ready_o),
        .read_i(dst_valid_o & dst_ready_i),
        .write_addr_i(src_gray_bin),
        .read_addr_i(sync_gray_bin_dst_to_src),
        .data_i(src_data_i),
        .data_o(dst_data_o)
    );

    // Clear logic
    clear_logic clear_logic_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .clear_i(src_clear_i),
        .clear_pending_o(src_clear_pending_o),
        .clear_active_o(src_clear_active)
    );

    clear_logic clear_logic_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .clear_i(dst_clear_i),
        .clear_pending_o(dst_clear_pending_o),
        .clear_active_o(dst_clear_active)
    );

    // FIFO status
    assign src_full = (src_gray_bin == {sync_gray_bin_src_to_dst[LOG_DEPTH-1:0] + 1'b1});
    assign src_empty = (src_gray_bin == sync_gray_bin_src_to_dst[LOG_DEPTH-1:0]);
    assign dst_full = (dst_gray_bin == {sync_gray_bin_dst_to_src[LOG_DEPTH-1:0] + 1'b1});
    assign dst_empty = (dst_gray_bin == sync_gray_bin_dst_to_src[LOG_DEPTH-1:0]);

    // Ready and valid signals
    assign src_ready_o = ~src_full;
    assign dst_valid_o = ~dst_empty;

endmodule

// Gray code to binary conversion
module gray_to_bin #(
    parameter LOG_DEPTH = 3
)(
    input  [LOG_DEPTH:0] gray_i,
    output [LOG_DEPTH-1:0] bin_o
);

    genvar i;
    generate
        for (i = 0; i < LOG_DEPTH; i = i + 1) begin : gen_gray_to_bin
            assign bin_o[i] = ^(gray_i[i+1:0]);
        end
    endgenerate

endmodule

// Gray counter module
module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    input                  increment_i,
    output [LOG_DEPTH:0] gray_o
);

    reg [LOG_DEPTH-1:0] counter;
    reg [LOG_DEPTH:0] gray;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            counter <= {LOG_DEPTH{1'b0}};
            gray <= {LOG_DEPTH+1{1'b0}};
        end else if (clear_i) begin
            counter <= {LOG_DEPTH{1'b0}};
            gray <= {LOG_DEPTH+1{1'b0}};
        end else if (increment_i) begin
            counter <= counter + 1'b1;
            gray <= {counter[LOG_DEPTH-1], counter[LOG_DEPTH-1:0] ^ counter[LOG_DEPTH-2:0]};
        end
    end

    assign gray_o = gray;

endmodule

// Synchronization flip-flops
module sync_ffs #(
    parameter WIDTH = 4,
    parameter SYNC_STAGES = 3
)(
    input  clk_i,
    input  rst_ni,
    input  [WIDTH-1:0] d_i,
    output [WIDTH-1:0] q_o
);

    reg [WIDTH-1:0] sync_ff [0:SYNC_STAGES-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_ff[0] <= {WIDTH{1'b0}};
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_ff[i] <= {WIDTH{1'b0}};
            end
        end else begin
            sync_ff[0] <= d_i;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_ff[i] <= sync_ff[i-1];
            end
        end
    end

    assign q_o = sync_ff[SYNC_STAGES-1];

endmodule

// FIFO memory module
module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    input                  write_i,
    input                  read_i,
    input  [LOG_DEPTH-1:0] write_addr_i,
    input  [LOG_DEPTH-1:0] read_addr_i,
    input  [WIDTH-1:0]     data_i,
    output [WIDTH-1:0]     data_o
);

    reg [WIDTH-1:0] mem [0:(1<<LOG_DEPTH)-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < (1<<LOG_DEPTH); i = i + 1) begin
                mem[i] <= {WIDTH{1'b0}};
            end
        end else if (clear_i) begin
            for (int i = 0; i < (1<<LOG_DEPTH); i = i + 1) begin
                mem[i] <= {WIDTH{1'b0}};
            end
        end else if (write_i) begin
            mem[write_addr_i] <= data_i;
        end
    end

    assign data_o = mem[read_addr_i];

endmodule

// Clear logic module
module clear_logic (
    input  clk_i,
    input  rst_ni,
    input  clear_i,
    output clear_pending_o,
    output clear_active_o
);

    reg clear_pending;
    reg clear_active;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            clear_pending <= 1'b0;
            clear_active <= 1'b0;
        end else begin
            clear_pending <= clear_i;
            clear_active <= clear_i;
        end
    end

    assign clear_pending_o = clear_pending;
    assign clear_active_o = clear_active;

endmodule
