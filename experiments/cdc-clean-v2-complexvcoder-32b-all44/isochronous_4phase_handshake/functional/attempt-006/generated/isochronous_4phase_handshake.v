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
    reg       src_req;
    reg       dst_req;

    // Source-domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase <= 2'b00;
            src_req   <= 1'b0;
        end else begin
            case (src_phase)
                2'b00: begin
                    if (src_valid_i && !src_req) begin
                        src_req <= 1'b1;
                        src_phase <= 2'b01;
                    end
                end
                2'b01: begin
                    src_phase <= 2'b10;
                end
                2'b10: begin
                    src_phase <= 2'b11;
                end
                2'b11: begin
                    if (dst_ready_i) begin
                        src_req <= 1'b0;
                        src_phase <= 2'b00;
                    end
                end
            endcase
        end
    end

    // Source ready output
    assign src_ready_o = (src_phase == 2'b00) && !src_req;

    // Destination-domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase <= 2'b00;
            dst_req   <= 1'b0;
        end else begin
            case (dst_phase)
                2'b00: begin
                    if (src_req && !dst_req) begin
                        dst_req <= 1'b1;
                        dst_phase <= 2'b01;
                    end
                end
                2'b01: begin
                    dst_phase <= 2'b10;
                end
                2'b10: begin
                    dst_phase <= 2'b11;
                end
                2'b11: begin
                    if (dst_ready_i) begin
                        dst_req <= 1'b0;
                        dst_phase <= 2'b00;
                    end
                end
            endcase
        end
    end

    // Destination valid output
    assign dst_valid_o = (dst_phase == 2'b01);

endmodule
