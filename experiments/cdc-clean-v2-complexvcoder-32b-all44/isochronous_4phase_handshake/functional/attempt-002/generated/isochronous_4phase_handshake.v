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
    reg       src_ready;
    reg       dst_valid;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase <= 2'b00;
            src_ready <= 1'b0;
        end else begin
            if (src_valid_i && src_ready) begin
                src_phase <= src_phase + 1;
            end
            src_ready <= (src_phase == 2'b00 && dst_phase == 2'b11) ||
                         (src_phase == 2'b01 && dst_phase == 2'b00) ||
                         (src_phase == 2'b10 && dst_phase == 2'b01) ||
                         (src_phase == 2'b11 && dst_phase == 2'b10);
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase <= 2'b00;
            dst_valid <= 1'b0;
        end else begin
            if (dst_ready_i && dst_valid) begin
                dst_phase <= dst_phase + 1;
            end
            dst_valid <= (src_phase == 2'b01 && dst_phase == 2'b00) ||
                         (src_phase == 2'b10 && dst_phase == 2'b01) ||
                         (src_phase == 2'b11 && dst_phase == 2'b10) ||
                         (src_phase == 2'b00 && dst_phase == 2'b11);
        end
    end

    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;

endmodule
