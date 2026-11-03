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

    reg [1:0] src_handshake;
    reg [1:0] dst_handshake;

    // Source-side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_handshake <= 2'b00;
        end else begin
            case (src_handshake)
                2'b00: if (src_valid_i) src_handshake <= 2'b01;
                2'b01: if (dst_handshake == 2'b10) src_handshake <= 2'b11;
                2'b11: if (dst_handshake == 2'b00) src_handshake <= 2'b00;
                default: src_handshake <= 2'b00;
            endcase
        end
    end

    // Destination-side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_handshake <= 2'b00;
        end else begin
            case (dst_handshake)
                2'b00: if (src_handshake == 2'b01) dst_handshake <= 2'b10;
                2'b10: if (dst_ready_i) dst_handshake <= 2'b11;
                2'b11: if (src_handshake == 2'b00) dst_handshake <= 2'b00;
                default: dst_handshake <= 2'b00;
            endcase
        end
    end

    // Determine src_ready_o based on src_handshake and dst_handshake
    assign src_ready_o = (src_handshake == 2'b11) && (dst_handshake == 2'b00);

    // Determine dst_valid_o based on src_handshake and dst_handshake
    assign dst_valid_o = (src_handshake == 2'b01) && (dst_handshake == 2'b10);

endmodule
