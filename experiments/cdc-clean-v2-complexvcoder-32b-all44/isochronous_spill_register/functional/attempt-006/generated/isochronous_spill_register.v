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

    reg                src_reg_valid;
    reg  [WIDTH-1:0]   src_reg_data;
    reg                dst_reg_valid;
    reg  [WIDTH-1:0]   dst_reg_data;
    reg                src_ready;
    reg                dst_valid;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_reg_valid <= 0;
            src_reg_data  <= 0;
            src_ready     <= 1;
        end else begin
            if (src_valid_i && src_ready) begin
                src_reg_valid <= 1;
                src_reg_data  <= src_data_i;
                src_ready     <= 0;
            end else if (!dst_reg_valid && src_reg_valid) begin
                src_ready     <= 1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_reg_valid <= 0;
            dst_reg_data  <= 0;
            dst_valid     <= 0;
        end else begin
            if (!dst_reg_valid && src_reg_valid) begin
                dst_reg_valid <= 1;
                dst_reg_data  <= src_reg_data;
                src_reg_valid <= 0;
            end else if (dst_ready_i && dst_valid) begin
                dst_reg_valid <= 0;
            end

            if (dst_reg_valid && !dst_valid) begin
                dst_valid <= 1;
                dst_data_o <= dst_reg_data;
            end else if (dst_ready_i && dst_valid) begin
                dst_valid <= 0;
            end
        end
    end

    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;

endmodule
