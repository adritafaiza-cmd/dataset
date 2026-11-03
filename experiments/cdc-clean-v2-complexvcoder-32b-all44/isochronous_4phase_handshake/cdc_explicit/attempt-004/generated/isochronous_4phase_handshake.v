module cdc_flipflop (
    input  clk_i,
    input  rst_ni,
    input  din,
    output dout
);
    reg dout_reg1;
    reg dout_reg2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            dout_reg1 <= 1'b0;
            dout_reg2 <= 1'b0;
        end else begin
            dout_reg1 <= din;
            dout_reg2 <= dout_reg1;
        end
    end

    assign dout = dout_reg2;
endmodule

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
    reg [1:0] src_handshake_state;
    reg [1:0] dst_handshake_state;
    wire src_valid_synced;
    wire src_ready_synced;
    wire dst_ready_synced;
    wire dst_valid_synced;

    cdc_flipflop ff_src_valid (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .din(src_valid_i),
        .dout(src_valid_synced)
    );

    cdc_flipflop ff_src_ready (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .din(src_ready_o),
        .dout(src_ready_synced)
    );

    cdc_flipflop ff_dst_ready (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .din(dst_ready_i),
        .dout(dst_ready_synced)
    );

    cdc_flipflop ff_dst_valid (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .din(dst_valid_o),
        .dout(dst_valid_synced)
    );

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_handshake_state <= 2'b00;
            src_ready_o <= 1'b1;
        end else begin
            case (src_handshake_state)
                2'b00: begin // idle
                    if (src_valid_i) begin
                        src_handshake_state <= 2'b01; // phase 1
                        src_ready_o <= 1'b0;
                    end else begin
                        src_ready_o <= 1'b1;
                    end
                end
                2'b01: begin // phase 1
                    if (dst_ready_synced) begin
                        src_handshake_state <= 2'b10; // phase 2
                    end
                end
                2'b10: begin // phase 2
                    if (dst_ready_synced) begin
                        src_handshake_state <= 2'b11; // phase 3
                    end
                end
                2'b11: begin // phase 3
                    if (dst_ready_synced) begin
                        src_handshake_state <= 2'b00; // idle
                        src_ready_o <= 1'b1;
                    end
                end
                default: begin
                    src_handshake_state <= 2'b00; // idle
                    src_ready_o <= 1'b1;
                end
            endcase
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_handshake_state <= 2'b00;
            dst_valid_o <= 1'b0;
        end else begin
            case (dst_handshake_state)
                2'b00: begin // idle
                    if (src_valid_synced) begin
                        dst_handshake_state <= 2'b01; // phase 1
                        dst_valid_o <= 1'b1;
                    end else begin
                        dst_valid_o <= 1'b0;
                    end
                end
                2'b01: begin // phase 1
                    dst_handshake_state <= 2'b10; // phase 2
                end
                2'b10: begin // phase 2
                    if (dst_ready_i) begin
                        dst_handshake_state <= 2'b11; // phase 3
                        dst_valid_o <= 1'b0;
                    end
                end
                2'b11: begin // phase 3
                    if (dst_ready_i) begin
                        dst_handshake_state <= 2'b00; // idle
                    end
                end
                default: begin
                    dst_handshake_state <= 2'b00; // idle
                    dst_valid_o <= 1'b0;
                end
            endcase
        end
    end
endmodule
