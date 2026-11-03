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

    // Internal signals
    reg [1:0] src_handshake_phase;
    reg [1:0] dst_handshake_phase;
    reg       src_handshake_valid;
    reg       dst_handshake_valid;
    reg       src_handshake_ready;
    reg       dst_handshake_ready;
    reg       src_handshake_crossed;
    reg       dst_handshake_crossed;

    // Source clock domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_handshake_phase <= 2'b00;
            src_handshake_valid <= 1'b0;
            src_handshake_ready <= 1'b0;
            src_handshake_crossed <= 1'b0;
        end else begin
            case (src_handshake_phase)
                2'b00: begin
                    if (src_valid_i && !src_handshake_valid) begin
                        src_handshake_valid <= 1'b1;
                        src_handshake_phase <= 2'b01;
                    end
                end
                2'b01: begin
                    src_handshake_phase <= 2'b10;
                end
                2'b10: begin
                    if (dst_handshake_crossed) begin
                        src_handshake_valid <= 1'b0;
                        src_handshake_phase <= 2'b11;
                    end
                end
                2'b11: begin
                    src_handshake_phase <= 2'b00;
                end
            endcase
        end
    end

    // Destination clock domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_handshake_phase <= 2'b00;
            dst_handshake_valid <= 1'b0;
            dst_handshake_ready <= 1'b0;
            dst_handshake_crossed <= 1'b0;
        end else begin
            case (dst_handshake_phase)
                2'b00: begin
                    if (src_handshake_valid && !dst_handshake_valid) begin
                        dst_handshake_valid <= 1'b1;
                        dst_handshake_phase <= 2'b01;
                    end
                end
                2'b01: begin
                    if (dst_ready_i && !dst_handshake_ready) begin
                        dst_handshake_ready <= 1'b1;
                        dst_handshake_phase <= 2'b10;
                    end
                end
                2'b10: begin
                    dst_handshake_phase <= 2'b11;
                end
                2'b11: begin
                    dst_handshake_valid <= 1'b0;
                    dst_handshake_ready <= 1'b0;
                    dst_handshake_crossed <= 1'b1;
                    dst_handshake_phase <= 2'b00;
                end
            endcase
        end
    end

    // Cross-domain synchronization
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_handshake_crossed <= 1'b0;
        end else begin
            dst_handshake_crossed <= dst_handshake_ready;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_handshake_crossed <= 1'b0;
        end else begin
            src_handshake_crossed <= src_handshake_valid;
        end
    end

    // Output assignments
    assign src_ready_o = (src_handshake_phase == 2'b00);
    assign dst_valid_o = (dst_handshake_phase == 2'b01);

endmodule
