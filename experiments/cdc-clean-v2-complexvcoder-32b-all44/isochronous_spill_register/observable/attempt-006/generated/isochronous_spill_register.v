module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

    // Internal signals
    reg [WIDTH-1:0]    fifo [1:0];
    reg [1:0]          fifo_valid;
    reg [1:0]          fifo_ptr_w;
    reg [1:0]          fifo_ptr_r;
    reg                fifo_full;
    reg                fifo_empty;
    reg                fifo_wen;
    reg                fifo_ren;
    reg                sync_src_valid_q;
    reg [WIDTH-1:0]    sync_src_data_q;
    reg                sync_dst_ready_q;

    // Synchronize src_valid_i to dst_clk_i
    sync_register sync_src_valid (
        .clk_i (dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d_i   (src_valid_i),
        .q_o   (sync_src_valid_q)
    );

    // Synchronize src_data_i to dst_clk_i
    sync_register #(.WIDTH(WIDTH)) sync_src_data (
        .clk_i (dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d_i   (src_data_i),
        .q_o   (sync_src_data_q)
    );

    // Synchronize dst_ready_i to src_clk_i
    sync_register sync_dst_ready (
        .clk_i (src_clk_i),
        .rst_ni(src_rst_ni),
        .d_i   (dst_ready_i),
        .q_o   (sync_dst_ready_q)
    );

    // FIFO write enable
    always @(*) begin
        fifo_wen = sync_src_valid_q & ~fifo_full;
    end

    // FIFO read enable
    always @(*) begin
        fifo_ren = sync_dst_ready_q & ~fifo_empty;
    end

    // FIFO write logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            fifo_ptr_w <= 2'b00;
            fifo_valid <= 2'b00;
        end else if (fifo_wen) begin
            fifo[fifo_ptr_w] <= sync_src_data_q;
            fifo_valid[fifo_ptr_w] <= 1'b1;
            fifo_ptr_w <= fifo_ptr_w + 1;
        end
    end

    // FIFO read logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            fifo_ptr_r <= 2'b00;
        end else if (fifo_ren) begin
            fifo_valid[fifo_ptr_r] <= 1'b0;
            fifo_ptr_r <= fifo_ptr_r + 1;
        end
    end

    // FIFO status flags
    always @(*) begin
        fifo_full  = (fifo_ptr_w == fifo_ptr_r) & fifo_valid[fifo_ptr_w];
        fifo_empty = (fifo_ptr_w == fifo_ptr_r) & ~fifo_valid[fifo_ptr_w];
    end

    // FIFO read data output
    always @(*) begin
        dst_data_o = fifo[fifo_ptr_r];
    end

    // Source ready output
    assign src_ready_o = ~fifo_full;

    // Destination valid output
    assign dst_valid_o = ~fifo_empty;

endmodule

module sync_register #(
    parameter WIDTH = 1
)(
    input              clk_i,
    input              rst_ni,
    input  [WIDTH-1:0] d_i,
    output [WIDTH-1:0] q_o
);

    reg [WIDTH-1:0] reg1;
    reg [WIDTH-1:0] reg2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            reg1 <= {WIDTH{1'b0}};
            reg2 <= {WIDTH{1'b0}};
        end else begin
            reg1 <= d_i;
            reg2 <= reg1;
        end
    end

    assign q_o = reg2;

endmodule
