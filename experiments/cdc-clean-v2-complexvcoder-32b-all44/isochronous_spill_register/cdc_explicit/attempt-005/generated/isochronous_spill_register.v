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
    reg                src_reg_valid;
    reg  [WIDTH-1:0] src_reg_data;
    reg                dst_reg_valid;
    reg  [WIDTH-1:0] dst_reg_data;
    reg                src_next_ready;
    reg                dst_next_valid;

    // Source clock domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_reg_valid <= 0;
            src_reg_data  <= 0;
            src_next_ready <= 1;
        end else begin
            if (src_next_ready && src_valid_i) begin
                src_reg_valid <= 1;
                src_reg_data  <= src_data_i;
                src_next_ready <= 0;
            end else if (dst_next_valid) begin
                src_next_ready <= 1;
            end
        end
    end

    // Source ready output
    assign src_ready_o = src_next_ready;

    // Destination clock domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_reg_valid <= 0;
            dst_reg_data  <= 0;
            dst_next_valid <= 0;
        end else begin
            if (dst_ready_i && dst_valid_o) begin
                dst_reg_valid <= 0;
                dst_next_valid <= 0;
            end else if (!dst_reg_valid && src_reg_valid) begin
                dst_reg_valid <= 1;
                dst_reg_data  <= src_reg_data;
                dst_next_valid <= 1;
                src_reg_valid <= 0;
            end
        end
    end

    // Destination valid and data outputs
    assign dst_valid_o = dst_reg_valid;
    assign dst_data_o  = dst_reg_data;

endmodule
