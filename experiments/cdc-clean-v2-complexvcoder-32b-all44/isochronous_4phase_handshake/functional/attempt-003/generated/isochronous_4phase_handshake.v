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

    // Source-side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase <= 2'b00;
            src_ready_o <= 1'b0;
        end else begin
            if (src_phase == 2'b00 && src_valid_i) begin
                src_ready_o <= 1'b1;
            end else begin
                src_ready_o <= 1'b0;
            end

            if (src_ready_o) begin
                src_phase <= src_phase + 1;
            end
        end
    end

    // Destination-side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase <= 2'b00;
            dst_valid_o <= 1'b0;
        end else begin
            if (dst_phase == 2'b01) begin
                dst_valid_o <= 1'b1;
            end else begin
                dst_valid_o <= 1'b0;
            end

            if (dst_ready_i && dst_valid_o) begin
                dst_phase <= dst_phase + 1;
            end
        end
    end

endmodule
