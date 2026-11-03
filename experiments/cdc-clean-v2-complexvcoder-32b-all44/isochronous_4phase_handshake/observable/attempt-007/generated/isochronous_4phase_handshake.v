module isochronous_4phase_handshake (
    input  src_clk_i,
    input  src_rst_ni,
    input  src_valid_i,
    output src_ready_o,
    input  dst_clk_i,
    input  dst_rst_ni,
    output dst_valid_o,
    input  dst_ready_i
);

    reg [1:0] src_phase;
    reg [1:0] dst_phase;
    reg       src_valid_ff;
    reg       dst_valid_ff;

    // Source clock domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase <= 2'b00;
            src_valid_ff <= 1'b0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                src_phase <= src_phase + 1;
                src_valid_ff <= 1'b1;
            end else if (src_ready_o) begin
                src_valid_ff <= 1'b0;
            end
        end
    end

    // Destination clock domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase <= 2'b00;
            dst_valid_ff <= 1'b0;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                dst_phase <= dst_phase + 1;
                dst_valid_ff <= 1'b1;
            end else if (dst_ready_i) begin
                dst_valid_ff <= 1'b0;
            end
        end
    end

    // Ready signal logic in source clock domain
    assign src_ready_o = (src_phase != dst_phase);

    // Valid signal logic in destination clock domain
    assign dst_valid_o = (src_phase == dst_phase);

endmodule
