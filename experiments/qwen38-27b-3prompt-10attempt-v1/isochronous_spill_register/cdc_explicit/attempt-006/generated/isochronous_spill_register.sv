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

    // Source-domain registers
    reg  src_valid_r;
    reg  [WIDTH-1:0] src_data_r;

    // Destination-domain registers
    reg  dst_valid_r;
    reg  [WIDTH-1:0] dst_data_r;

    // Source-domain logic
    wire src_accept = src_valid_i & src_ready_o;
    wire src_full   = src_valid_r;

    assign src_ready_o = ~src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_r <= 1'b0;
            src_data_r  <= {WIDTH{1'b0}};
        end else begin
            if (src_accept) begin
                src_valid_r <= 1'b1;
                src_data_r  <= src_data_i;
            end else if (dst_valid_r) begin
                src_valid_r <= 1'b0;
            end
        end
    end

    // Destination-domain logic
    wire dst_accept = dst_valid_r & dst_ready_i;

    assign dst_valid_o = dst_valid_r;
    assign dst_data_o  = dst_data_r;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_r <= 1'b0;
            dst_data_r  <= {WIDTH{1'b0}};
        end else begin
            if (dst_accept) begin
                dst_valid_r <= 1'b0;
            end else if (src_valid_r) begin
                dst_valid_r <= 1'b1;
                dst_data_r  <= src_data_r;
            end
        end
    end

endmodule
