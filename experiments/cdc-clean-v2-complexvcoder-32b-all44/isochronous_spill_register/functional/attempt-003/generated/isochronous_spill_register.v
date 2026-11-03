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

    reg [WIDTH-1:0] src_reg_data [1:0];
    reg             src_reg_valid [1:0];
    reg [1:0]       src_ptr;
    reg [1:0]       dst_ptr;
    reg [1:0]       src_count;
    reg [1:0]       dst_count;

    // Source clock domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_reg_valid <= 2'b0;
            src_ptr <= 2'b0;
            src_count <= 2'b0;
        end else if (src_ready_o && src_valid_i) begin
            src_reg_data[src_ptr] <= src_data_i;
            src_reg_valid[src_ptr] <= 1'b1;
            src_ptr <= src_ptr + 1;
            src_count <= src_count + 1;
        end else if (dst_valid_o && dst_ready_i) begin
            src_count <= src_count - 1;
        end
    end

    // Destination clock domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_reg_valid <= 2'b0;
            dst_ptr <= 2'b0;
            dst_count <= 2'b0;
        end else if (dst_ready_i && dst_valid_o) begin
            dst_reg_valid[dst_ptr] <= 1'b0;
            dst_ptr <= dst_ptr + 1;
            dst_count <= dst_count - 1;
        end else if (src_ready_o && src_valid_i) begin
            dst_count <= dst_count + 1;
        end
    end

    // Source ready signal
    assign src_ready_o = (src_count < 2);

    // Destination valid signal
    assign dst_valid_o = (dst_count > 0);

    // Destination data output
    assign dst_data_o = src_reg_data[dst_ptr];

endmodule
