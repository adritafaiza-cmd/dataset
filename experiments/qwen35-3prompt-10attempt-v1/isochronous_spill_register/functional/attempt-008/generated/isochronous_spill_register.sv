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
    output reg [WIDTH-1:0] dst_data_o
);

    // Source domain state: 0 = empty, 1 = full
    reg src_state;
    // Destination domain state: 0 = empty, 1 = full
    reg dst_state;
    // Data storage for the buffer
    reg [WIDTH-1:0] src_data_reg;
    reg [WIDTH-1:0] dst_data_reg;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state <= 1'b0;
            src_data_reg <= 0;
        end else begin
            if (src_valid_i && !src_state) begin
                src_state <= 1'b1;
                src_data_reg <= src_data_i;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state <= 1'b0;
            dst_data_reg <= 0;
            dst_valid_o <= 1'b0;
            dst_data_o <= 0;
        end else begin
            if (dst_state && dst_ready_i) begin
                dst_state <= 1'b0;
                dst_valid_o <= 1'b1;
                dst_data_o <= dst_data_reg;
            end else if (src_state) begin
                dst_state <= 1'b1;
                dst_data_reg <= src_data_reg;
                dst_valid_o <= 1'b0;
                dst_data_o <= 0;
            end else begin
                dst_state <= 1'b0;
                dst_valid_o <= 1'b0;
                dst_data_o <= 0;
            end
        end
    end

    // Backpressure generation
    assign src_ready_o = src_state ? 1'b0 : 1'b1;

endmodule<|im_end|>
