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

    // Stage 0 (source domain)
    reg [WIDTH-1:0] stage0_data;
    reg             stage0_valid;

    // Stage 1 (destination domain)
    reg [WIDTH-1:0] stage1_data;
    reg             stage1_valid;

    // Handshake signals
    wire src_accept = src_valid_i & src_ready_o;
    wire dst_accept = dst_valid_o & dst_ready_i;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            stage0_valid <= 1'b0;
            stage0_data  <= {WIDTH{1'b0}};
        end else begin
            if (src_accept) begin
                stage0_valid <= 1'b1;
                stage0_data  <= src_data_i;
            end else if (dst_accept) begin
                stage0_valid <= 1'b0;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            stage1_valid <= 1'b0;
            stage1_data  <= {WIDTH{1'b0}};
        end else begin
            if (dst_accept) begin
                stage1_valid <= 1'b0;
            end else if (src_accept) begin
                stage1_valid <= 1'b1;
                stage1_data  <= src_data_i;
            end
        end
    end

    // Outputs
    assign src_ready_o = !stage0_valid;
    assign dst_valid_o = stage1_valid;
    assign dst_data_o  = stage1_data;

endmodule
