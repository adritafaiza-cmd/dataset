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

    // Internal signals for the 2-deep buffer
    reg [WIDTH-1:0] data_reg_1, data_reg_2;
    reg             valid_reg_1, valid_reg_2;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o <= 1'b0;
            data_reg_1 <= {WIDTH{1'b0}};
            valid_reg_1 <= 1'b0;
        end else begin
            if (src_valid_i && !valid_reg_1) begin
                data_reg_1 <= src_data_i;
                valid_reg_1 <= 1'b1;
                src_ready_o <= 1'b1;
            end else if (valid_reg_2 && dst_ready_i) begin
                src_ready_o <= 1'b1;
            end else begin
                src_ready_o <= 1'b0;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 1'b0;
            data_reg_2 <= {WIDTH{1'b0}};
            valid_reg_2 <= 1'b0;
        end else begin
            if (valid_reg_1 && !valid_reg_2) begin
                data_reg_2 <= data_reg_1;
                valid_reg_1 <= 1'b0;
                valid_reg_2 <= 1'b1;
                dst_valid_o <= 1'b1;
            end else if (valid_reg_2 && dst_ready_i) begin
                valid_reg_2 <= 1'b0;
                dst_valid_o <= 1'b0;
            end else begin
                dst_valid_o <= valid_reg_2;
            end
        end
    end

    // Output the data from the second register stage
    assign dst_data_o = data_reg_2;

endmodule
