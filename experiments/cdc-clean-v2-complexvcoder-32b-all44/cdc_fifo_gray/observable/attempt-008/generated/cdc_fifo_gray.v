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
    wire [LOG_DEPTH:0] src_gray_wptr;
    wire [LOG_DEPTH:0] dst_gray_wptr;
    wire [LOG_DEPTH:0] src_gray_wptr_sync;
    wire [LOG_DEPTH:0] dst_gray_wptr_sync;
    wire [LOG_DEPTH:0] src_gray_rptr;
    wire [LOG_DEPTH:0] dst_gray_rptr;
    wire [LOG_DEPTH:0] src_gray_rptr_sync;
    wire [LOG_DEPTH:0] sync_src_gray_wptr_out;
    wire [LOG_DEPTH:0] sync_dst_gray_rptr_out;
    wire               src_wren;
    wire               dst_rden;
    wire [LOG_DEPTH:0] src_gray_wptr_bin;
    wire [LOG_DEPTH:0] dst_gray_rptr_bin;

    // Gray counters for source and destination
    gray_counter src_gray_counter (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .wren(src_wren),
        .gray_ptr(src_gray_wptr)
    );

    gray_counter dst_gray_counter (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .wren(dst_rden),
        .gray_ptr(dst_gray_wptr)
    );

    // Synchronizers for gray counters
    sync_gray_counter sync_src_gray_wptr (
        .src_clk_i(src_clk_i),
        .dst_clk_i(dst_clk_i),
        .src_gray_wptr(src_gray_wptr),
        .dst_gray_wptr_sync(sync_src_gray_wptr_out)
    );

    sync_gray_counter sync_dst_gray_rptr (
        .src_clk_i(src_clk_i),
        .dst_clk_i(dst_clk_i),
        .src_gray_wptr(dst_gray_rptr),
        .dst_gray_wptr_sync(sync_dst_gray_rptr_out)
    );

    // Binary conversion for gray counters
    assign src_gray_wptr_bin = src_gray_wptr ^ (src_gray_wptr >> 1);
    assign dst_gray_wptr_sync_bin = sync_src_gray_wptr_out ^ (sync_src_gray_wptr_out >> 1);
    assign dst_gray_rptr_bin = dst_gray_rptr ^ (dst_gray_rptr >> 1);
    assign src_gray_rptr_sync_bin = sync_dst_gray_rptr_out ^ (sync_dst_gray_rptr_out >> 1);

    // Write and read enable signals
    assign src_wren = src_valid_i & src_ready_o;
    assign dst_rden = dst_ready_i & dst_valid_o;

    // FIFO memory
    dual_port_ram fifo_memory (
        .clk_i(src_clk_i),
        .wren(src_wren),
        .waddr(src_gray_wptr_bin),
        .din(src_data_i),
        .clk_o(dst_clk_i),
        .ren(dst_rden),
        .raddr(dst_gray_rptr_bin),
        .dout(dst_data_o)
    );

    // FIFO status signals
    assign src_ready_o = (src_gray_wptr_bin + 1) != dst_gray_rptr_sync_bin;
    assign dst_valid_o = src_gray_wptr_sync_bin != dst_gray_rptr_bin;

endmodule

module gray_counter (
    input                  clk_i,
    input                  rst_ni,
    input                  wren,
    output [LOG_DEPTH:0] gray_ptr
);

    reg [LOG_DEPTH:0] bin_ptr;
    reg [LOG_DEPTH:0] gray_ptr_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_ptr <= {LOG_DEPTH+1{1'b0}};
            gray_ptr_reg <= {LOG_DEPTH+1{1'b0}};
        end else if (wren) begin
            bin_ptr <= bin_ptr + 1;
            gray_ptr_reg <= bin_ptr ^ (bin_ptr >> 1);
        end
    end

    assign gray_ptr = gray_ptr_reg;

endmodule

module sync_gray_counter #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_clk_i,
    input                  dst_clk_i,
    input  [LOG_DEPTH:0] src_gray_wptr,
    output [LOG_DEPTH:0] dst_gray_wptr_sync
);

    reg [LOG_DEPTH:0] sync_reg [0:SYNC_STAGES-1];

    // Synchronizer chain
    always @(posedge src_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg[0] <= {LOG_DEPTH+1{1'b0}};
        end else begin
            sync_reg[0] <= src_gray_wptr;
        end
    end

    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_chain
            always @(posedge dst_clk_i or negedge rst_ni) begin
                if (!rst_ni) begin
                    sync_reg[i] <= {LOG_DEPTH+1{1'b0}};
                end else begin
                    sync_reg[i] <= sync_reg[i-1];
                end
            end
        end
    endgenerate

    assign dst_gray_wptr_sync = sync_reg[SYNC_STAGES-1];

endmodule

module dual_port_ram #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  wren,
    input  [LOG_DEPTH:0] waddr,
    input  [WIDTH-1:0]   din,
    input                  clk_o,
    input                  ren,
    input  [LOG_DEPTH:0] raddr,
    output [WIDTH-1:0]   dout
);

    reg [WIDTH-1:0] mem [0:(2**(LOG_DEPTH+1))-1];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            mem <= '{default: {WIDTH{1'b0}}};
        end else if (wren) begin
            mem[waddr] <= din;
        end
    end

    always @(posedge clk_o) begin
        if (ren) begin
            dout <= mem[raddr];
        end
    end

endmodule
