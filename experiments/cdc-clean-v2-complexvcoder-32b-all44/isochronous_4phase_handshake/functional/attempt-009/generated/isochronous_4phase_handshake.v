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
    reg       src_req;
    reg       dst_ack;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase <= 2'b00;
            src_req   <= 1'b0;
        end else begin
            if (src_ready_o) begin
                src_phase <= src_phase + 1;
                if (src_phase == 2'b00 && src_valid_i) begin
                    src_req <= 1'b1;
                end
            end
            if (src_phase == 2'b10) begin
                src_req <= 1'b0;
            end
        end
    end

    assign src_ready_o = (src_phase == 2'b00) && src_valid_i;

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase <= 2'b00;
            dst_ack   <= 1'b0;
        end else begin
            if (dst_valid_o) begin
                dst_phase <= dst_phase + 1;
                if (dst_phase == 2'b01 && dst_ready_i) begin
                    dst_ack <= 1'b1;
                end
            end
            if (dst_phase == 2'b11) begin
                dst_ack <= 1'b0;
            end
        end
    end

    assign dst_valid_o = (dst_phase == 2'b01) && dst_ready_i;

endmodule
