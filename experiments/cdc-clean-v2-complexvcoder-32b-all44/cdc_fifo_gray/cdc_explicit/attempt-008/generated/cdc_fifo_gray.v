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
    reg  [LOG_DEPTH:0]     src_gray_ptr;
    reg  [LOG_DEPTH:0]     src_gray_ptr_synced;
    reg  [LOG_DEPTH:0]     dst_gray_ptr;
    reg  [LOG_DEPTH:0]     dst_gray_ptr_synced;
    reg                    src_wr_en;
    reg                    dst_rd_en;
    reg  [WIDTH-1:0]       dst_data_stage1;
    reg  [WIDTH-1:0]       dst_data_stage2;
    reg                    dst_valid_stage1;
    reg                    dst_valid_stage2;

    // Source Gray-code counter
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) src_gray_counter (
        .clk      (src_clk_i),
        .rst_n    (src_rst_ni),
        .load     (src_wr_en),
        .inc      (1'b1),
        .gray_out (src_gray_ptr)
    );

    // Destination Gray-code counter
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) dst_gray_counter (
        .clk      (dst_clk_i),
        .rst_n    (dst_rst_ni),
        .load     (dst_rd_en),
        .inc      (1'b1),
        .gray_out (dst_gray_ptr)
    );

    // Synchronize source gray pointer to destination domain
    sync_flop #(.LOG_DEPTH(LOG_DEPTH)) sync_src_gray_ptr (
        .clk (dst_clk_i),
        .rst_n (dst_rst_ni),
        .d (src_gray_ptr),
        .q (src_gray_ptr_synced)
    );

    // Synchronize destination gray pointer to source domain
    sync_flop #(.LOG_DEPTH(LOG_DEPTH)) sync_dst_gray_ptr (
        .clk (src_clk_i),
        .rst_n (src_rst_ni),
        .d (dst_gray_ptr),
        .q (dst_gray_ptr_synced)
    );

    // Dual-port RAM for FIFO storage
    dual_port_ram #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH)) fifo_ram (
        .clk_a (src_clk_i),
        .we_a  (src_wr_en),
        .addr_a(src_gray_ptr[LOG_DEPTH-1:0]),
        .din_a (src_data_i),
        .clk_b (dst_clk_i),
        .addr_b(dst_gray_ptr[LOG_DEPTH-1:0]),
        .dout_b(dst_data_stage1)
    );

    // Source ready logic
    assign src_ready_o = ~(|(src_gray_ptr_synced ^ src_gray_ptr[LOG_DEPTH:1]));

    // Source write enable
    assign src_wr_en = src_valid_i & src_ready_o;

    // Destination read enable
    assign dst_rd_en = dst_valid_o & dst_ready_i;

    // Synchronize data and valid across two stages
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_stage1 <= 0;
            dst_data_stage2 <= 0;
            dst_valid_stage1 <= 0;
            dst_valid_stage2 <= 0;
        end else begin
            dst_data_stage1 <= dst_data_stage1;
            dst_data_stage2 <= dst_data_stage1;
            dst_valid_stage1 <= (src_gray_ptr_synced != dst_gray_ptr);
            dst_valid_stage2 <= dst_valid_stage1;
        end
    end

    // Destination output logic
    assign dst_data_o = dst_data_stage2;
    assign dst_valid_o = dst_valid_stage2;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_n,
    input                  load,
    input                  inc,
    output [LOG_DEPTH:0]   gray_out
);

    reg  [LOG_DEPTH:0] bin_counter;
    reg  [LOG_DEPTH:0] bin_counter_next;
    reg  [LOG_DEPTH:0] gray_counter;

    // Binary counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_counter <= 0;
        else if (load && inc)
            bin_counter <= bin_counter_next;
    end

    // Binary counter next value
    assign bin_counter_next = bin_counter + 1;

    // Gray-code encoding
    assign gray_counter = bin_counter ^ (bin_counter >> 1);

    // Gray-code output
    assign gray_out = gray_counter;

endmodule

module sync_flop #(
    parameter LOG_DEPTH = 3
)(
    input                  clk,
    input                  rst_n,
    input  [LOG_DEPTH:0]   d,
    output [LOG_DEPTH:0]   q
);

    reg [LOG_DEPTH:0] q_reg;

    // Synchronizer flop
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q_reg <= 0;
        else
            q_reg <= d;
    end

    // Output assignment
    assign q = q_reg;

endmodule

module dual_port_ram #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_a,
    input                  we_a,
    input  [LOG_DEPTH-1:0] addr_a,
    input  [WIDTH-1:0]     din_a,
    input                  clk_b,
    input  [LOG_DEPTH-1:0] addr_b,
    output [WIDTH-1:0]     dout_b
);

    reg [WIDTH-1:0] ram [2**LOG_DEPTH-1:0];

    // Write operation
    always @(posedge clk_a) begin
        if (we_a)
            ram[addr_a] <= din_a;
    end

    // Read operation
    always @(posedge clk_b) begin
        dout_b <= ram[addr_b];
    end

endmodule
