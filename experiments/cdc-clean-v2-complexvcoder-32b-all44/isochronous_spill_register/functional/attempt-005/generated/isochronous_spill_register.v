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

    dual_clock_fifo #(
        .WIDTH(WIDTH)
    ) spill_fifo (
        .clk_w(src_clk_i),
        .rst_ni_w(src_rst_ni),
        .push_i(src_valid_i),
        .pop_o(src_ready_o),
        .data_i(src_data_i),
        .clk_r(dst_clk_i),
        .rst_ni_r(dst_rst_ni),
        .valid_o(dst_valid_o),
        .ready_i(dst_ready_i),
        .data_o(dst_data_o)
    );

endmodule

module dual_clock_fifo #(
    parameter WIDTH = 8
)(
    input              clk_w,
    input              rst_ni_w,
    input              push_i,
    output             pop_o,
    input  [WIDTH-1:0] data_i,
    input              clk_r,
    input              rst_ni_r,
    output             valid_o,
    input              ready_i,
    output [WIDTH-1:0] data_o
);

    reg [1:0] wptr, rptr;
    reg [1:0] wptr_gray, rptr_gray;
    reg [1:0] wptr_gray_r, rptr_gray_w;
    reg [WIDTH-1:0] mem [1:0];
    reg full, empty;

    // Gray code conversion
    assign wptr_gray = (wptr ^ (wptr >> 1));
    assign rptr_gray = (rptr ^ (rptr >> 1));

    // Write pointer update
    always @(posedge clk_w or negedge rst_ni_w) begin
        if (!rst_ni_w) begin
            wptr <= 2'b00;
            wptr_gray_r <= 2'b00;
        end else if (push_i && !full) begin
            wptr <= wptr + 1;
        end
    end

    // Read pointer update
    always @(posedge clk_r or negedge rst_ni_r) begin
        if (!rst_ni_r) begin
            rptr <= 2'b00;
            rptr_gray_w <= 2'b00;
        end else if (ready_i && valid_o) begin
            rptr <= rptr + 1;
        end
    end

    // Write to memory
    always @(posedge clk_w) begin
        if (push_i && !full) begin
            mem[wptr] <= data_i;
        end
    end

    // Read from memory
    always @(posedge clk_r) begin
        if (ready_i && valid_o) begin
            data_o <= mem[rptr];
        end
    end

    // Gray code synchronization
    always @(posedge clk_r) begin
        if (!rst_ni_r) begin
            wptr_gray_r <= 2'b00;
        end else begin
            wptr_gray_r <= wptr_gray;
        end
    end

    always @(posedge clk_w) begin
        if (!rst_ni_w) begin
            rptr_gray_w <= 2'b00;
        end else begin
            rptr_gray_w <= rptr_gray;
        end
    end

    // Full and empty flags
    assign full = (wptr_gray_r == {~rptr_gray_w[1], rptr_gray_w[0]});
    assign empty = (wptr_gray_r == rptr_gray_w);

    // Ready and valid signals
    assign pop_o = !full;
    assign valid_o = !empty;

endmodule
