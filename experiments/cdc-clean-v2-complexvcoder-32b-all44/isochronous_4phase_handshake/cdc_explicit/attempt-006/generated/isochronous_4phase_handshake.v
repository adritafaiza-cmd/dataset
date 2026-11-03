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
    reg [1:0] src_phase;
    reg [1:0] dst_phase;
    reg       src_handshake;
    reg       dst_handshake;

    // Source-domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase <= 2'b00;
            src_handshake <= 1'b0;
        end else begin
            case (src_phase)
                2'b00: begin
                    if (src_valid_i && !src_handshake) begin
                        src_phase <= 2'b01;
                        src_handshake <= 1'b1;
                    end
                end
                2'b01: begin
                    src_phase <= 2'b10;
                end
                2'b10: begin
                    src_phase <= 2'b11;
                end
                2'b11: begin
                    src_phase <= 2'b00;
                    src_handshake <= 1'b0;
                end
                default: begin
                    src_phase <= 2'b00;
                    src_handshake <= 1'b0;
                end
            endcase
        end
    end

    // Destination-domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase <= 2'b00;
            dst_handshake <= 1'b0;
        end else begin
            case (dst_phase)
                2'b00: begin
                    if (src_handshake && !dst_handshake) begin
                        dst_phase <= 2'b01;
                        dst_handshake <= 1'b1;
                    end
                end
                2'b01: begin
                    dst_phase <= 2'b10;
                end
                2'b10: begin
                    dst_phase <= 2'b11;
                end
                2'b11: begin
                    dst_phase <= 2'b00;
                    dst_handshake <= 1'b0;
                end
                default: begin
                    dst_phase <= 2'b00;
                    dst_handshake <= 1'b0;
                end
            endcase
        end
    end

    // Source ready output
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o <= 1'b0;
        end else begin
            src_ready_o <= (src_phase == 2'b00);
        end
    end

    // Destination valid output
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 1'b0;
        end else begin
            dst_valid_o <= (dst_phase == 2'b01) && dst_ready_i;
        end
    end

endmodule
