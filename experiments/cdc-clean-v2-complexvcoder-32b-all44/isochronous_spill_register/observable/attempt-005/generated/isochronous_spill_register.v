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

    cross_clock_buffer #(
        .WIDTH(WIDTH)
    ) cc_buffer_inst (
        .clk_i      (src_clk_i),
        .rst_ni     (src_rst_ni),
        .valid_i    (src_valid_i),
        .ready_o    (src_ready_o),
        .data_i     (src_data_i),
        .clk_o      (dst_clk_i),
        .rst_no     (dst_rst_ni),
        .valid_o    (dst_valid_o),
        .ready_i    (dst_ready_i),
        .data_o     (dst_data_o)
    );

endmodule

module cross_clock_buffer #(
    parameter WIDTH = 8
)(
    input              clk_i,
    input              rst_ni,
    input              valid_i,
    output             ready_o,
    input  [WIDTH-1:0] data_i,
    input              clk_o,
    input              rst_no,
    output             valid_o,
    input              ready_i,
    output [WIDTH-1:0] data_o
);

    reg [1:0]          fifo_valid;
    reg [WIDTH-1:0]    fifo_data [1:0];
    reg [1:0]          fifo_full;
    reg [1:0]          fifo_empty;
    reg                fifo_read;
    reg                fifo_write;

    // FIFO write logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            fifo_valid <= 2'b00;
            fifo_data  <= {2{WIDTH{1'b0}}};
        end else if (fifo_write) begin
            fifo_valid[fifo_write] <= 1'b1;
            fifo_data[fifo_write]  <= data_i;
        end else if (fifo_read) begin
            fifo_valid[fifo_read] <= 1'b0;
        end
    end

    // FIFO read logic
    always @(posedge clk_o or negedge rst_no) begin
        if (!rst_no) begin
            fifo_read <= 1'b0;
        end else if (valid_o && ready_i) begin
            fifo_read <= ~fifo_read;
        end
    end

    // FIFO write pointer logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            fifo_write <= 1'b0;
        end else if (valid_i && ready_o) begin
            fifo_write <= ~fifo_write;
        end
    end

    // FIFO status signals
    assign fifo_full = (fifo_valid[0] & fifo_valid[1]);
    assign fifo_empty = ~(fifo_valid[0] | fifo_valid[1]);

    // Ready and valid signals
    assign ready_o = ~fifo_full;
    assign valid_o = ~fifo_empty;

    // Output data
    assign data_o = fifo_data[fifo_read];

endmodule
