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

    reg  [WIDTH-1:0] src_data_reg;
    reg              src_valid_reg;
    reg              src_ready_reg;
    reg  [WIDTH-1:0] dst_data_reg;
    reg              dst_valid_reg;
    reg              dst_ready_reg;
    reg  [WIDTH-1:0] src_to_dst_data;
    reg              src_to_dst_valid;
    reg              dst_to_src_ready;

    // Source clock domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_data_reg  <= {WIDTH{1'b0}};
            src_valid_reg <= 1'b0;
            src_ready_reg <= 1'b0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                src_data_reg  <= src_data_i;
                src_valid_reg <= 1'b1;
            end
            if (dst_to_src_ready) begin
                src_ready_reg <= 1'b1;
            end else begin
                src_ready_reg <= 1'b0;
            end
            if (src_valid_reg && dst_to_src_ready) begin
                src_valid_reg <= 1'b0;
            end
        end
    end

    // Destination clock domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg  <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
            dst_ready_reg <= 1'b0;
        end else begin
            if (src_to_dst_valid && dst_ready_i) begin
                dst_data_reg  <= src_to_dst_data;
                dst_valid_reg <= 1'b1;
            end
            if (dst_valid_reg && dst_ready_i) begin
                dst_ready_reg <= 1'b1;
            end else begin
                dst_ready_reg <= 1'b0;
            end
            if (dst_valid_reg && dst_ready_i) begin
                dst_valid_reg <= 1'b0;
            end
        end
    end

    // Cross-domain signals
    always @(posedge src_clk_i) begin
        src_to_dst_data  <= src_data_reg;
        src_to_dst_valid <= src_valid_reg;
    end

    always @(posedge dst_clk_i) begin
        dst_to_src_ready <= src_ready_reg;
    end

    // Outputs
    assign src_ready_o  = src_ready_reg;
    assign dst_valid_o  = dst_valid_reg;
    assign dst_data_o   = dst_data_reg;

endmodule
