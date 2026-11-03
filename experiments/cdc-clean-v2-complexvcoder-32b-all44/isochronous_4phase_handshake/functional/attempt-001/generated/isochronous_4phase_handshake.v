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
        end else begin
            case (src_phase)
                2'b00: if (src_valid_i && (dst_phase == 2'b01)) src_phase <= 2'b01;
                2'b01: src_phase <= 2'b10;
                2'b10: if (src_valid_i && (dst_phase == 2'b11)) src_phase <= 2'b11;
                2'b11: src_phase <= 2'b00;
                default: src_phase <= 2'b00;
            endcase
        end
    end

    // Source ready output
    assign src_ready_o = (src_phase == 2'b00) || (src_phase == 2'b10);

    // Destination-side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase <= 2'b00;
        end else begin
            case (dst_phase)
                2'b00: if (dst_ready_i && (src_phase == 2'b01)) dst_phase <= 2'b01;
                2'b01: dst_phase <= 2'b10;
                2'b10: if (dst_ready_i && (src_phase == 2'b11)) dst_phase <= 2'b11;
                2'b11: dst_phase <= 2'b00;
                default: dst_phase <= 2'b00;
            endcase
        end
    end

    // Destination valid output
    assign dst_valid_o = (dst_phase == 2'b01) || (dst_phase == 2'b11);

endmodule
