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
    reg  [WIDTH-1:0]   src_reg_data;
    reg                dst_reg_valid;
    reg  [WIDTH-1:0]   dst_reg_data;
    reg                buffer_full;

    // Source-side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_reg_valid <= 0;
            src_reg_data  <= 0;
            buffer_full   <= 0;
            src_ready_o   <= 1;
        end else begin
            if (src_valid_i && !buffer_full) begin
                src_reg_valid <= 1;
                src_reg_data  <= src_data_i;
                buffer_full   <= 1;
                src_ready_o   <= 0;
            end else if (dst_ready_i && dst_reg_valid) begin
                buffer_full   <= 0;
                src_ready_o   <= 1;
            end
        end
    end

    // Destination-side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_reg_valid <= 0;
            dst_reg_data  <= 0;
            dst_valid_o   <= 0;
        end else begin
            if (src_reg_valid && !dst_reg_valid) begin
                dst_reg_valid <= 1;
                dst_reg_data  <= src_reg_data;
                dst_valid_o   <= 1;
                src_reg_valid <= 0;
            end else if (dst_ready_i && dst_reg_valid) begin
                dst_reg_valid <= 0;
                dst_valid_o   <= 0;
            end
        end
    end

    // Output data assignment
    assign dst_data_o = dst_reg_data;

endmodule
