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

    reg                src_ff_valid;
    reg [WIDTH-1:0]    src_ff_data;
    reg                dst_ff_valid;
    reg [WIDTH-1:0]    dst_ff_data;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ff_valid <= 0;
            src_ff_data  <= 0;
        end else if (src_valid_i && !src_ff_valid) begin
            src_ff_valid <= 1;
            src_ff_data  <= src_data_i;
        end else if (dst_ready_i && dst_ff_valid && src_ff_valid) begin
            src_ff_valid <= 0;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ff_valid <= 0;
            dst_ff_data  <= 0;
        end else if (src_ff_valid && !dst_ff_valid) begin
            dst_ff_valid <= 1;
            dst_ff_data  <= src_ff_data;
        end else if (dst_ready_i && dst_ff_valid) begin
            dst_ff_valid <= 0;
        end
    end

    // Ready and Valid signals
    assign src_ready_o = !src_ff_valid;
    assign dst_valid_o = dst_ff_valid;
    assign dst_data_o  = dst_ff_data;

endmodule
