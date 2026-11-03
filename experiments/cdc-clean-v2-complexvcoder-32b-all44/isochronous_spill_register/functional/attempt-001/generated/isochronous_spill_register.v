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
    reg [1:0] src_ff_valid;
    reg [WIDTH*2-1:0] src_ff_data;
    reg [1:0] dst_ff_valid;
    reg [WIDTH*2-1:0] dst_ff_data;
    wire src_ready;
    wire dst_valid;

    // Source clock domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ff_valid <= 2'b00;
            src_ff_data <= {WIDTH*2{1'b0}};
        end else if (src_ready && src_valid_i) begin
            src_ff_valid <= {src_ff_valid[0], src_valid_i};
            src_ff_data <= {src_data_i, src_ff_data[WIDTH-1:0]};
        end
    end

    // Destination clock domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ff_valid <= 2'b00;
            dst_ff_data <= {WIDTH*2{1'b0}};
        end else if (dst_ready_i && dst_valid) begin
            dst_ff_valid <= {1'b0, dst_ff_valid[1]};
            dst_ff_data <= {dst_ff_data[WIDTH*2-1:WIDTH], WIDTH{1'b0}};
        end
    end

    // Source ready signal
    assign src_ready = ~src_ff_valid[0];
    assign src_ready_o = src_ready;

    // Destination valid and data signals
    assign dst_valid = dst_ff_valid[1];
    assign dst_valid_o = dst_valid;
    assign dst_data_o = dst_ff_data[WIDTH*2-1:WIDTH];

endmodule
