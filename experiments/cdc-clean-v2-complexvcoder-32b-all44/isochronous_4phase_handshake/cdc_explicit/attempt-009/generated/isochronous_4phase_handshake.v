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
    reg [1:0] src_phase_reg;
    reg [1:0] dst_phase_reg;
    reg       src_handshake_signal;
    reg       dst_handshake_signal;
    reg       src_handshake_signal_synced;
    reg       dst_handshake_signal_synced;

    // Synchronizers for crossing clock domains
    sync_cell sync_src_to_dst (
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .din(src_handshake_signal),
        .dout(src_handshake_signal_synced)
    );

    sync_cell sync_dst_to_src (
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .din(dst_handshake_signal),
        .dout(dst_handshake_signal_synced)
    );

    // Source-side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase_reg <= 2'b00;
            src_handshake_signal <= 1'b0;
            src_ready_o <= 1'b0;
        end else begin
            case (src_phase_reg)
                2'b00: begin
                    if (src_valid_i && !src_handshake_signal_synced) begin
                        src_handshake_signal <= 1'b1;
                        src_phase_reg <= 2'b01;
                    end
                end
                2'b01: begin
                    src_phase_reg <= 2'b10;
                end
                2'b10: begin
                    if (dst_ready_i) begin
                        src_phase_reg <= 2'b11;
                    end
                end
                2'b11: begin
                    src_handshake_signal <= 1'b0;
                    src_phase_reg <= 2'b00;
                    src_ready_o <= 1'b1;
                end
                default: begin
                    src_phase_reg <= 2'b00;
                end
            endcase
        end
    end

    // Destination-side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase_reg <= 2'b00;
            dst_handshake_signal <= 1'b0;
            dst_valid_o <= 1'b0;
        end else begin
            case (dst_phase_reg)
                2'b00: begin
                    if (src_handshake_signal_synced) begin
                        dst_handshake_signal <= 1'b1;
                        dst_phase_reg <= 2'b01;
                    end
                end
                2'b01: begin
                    dst_phase_reg <= 2'b10;
                end
                2'b10: begin
                    dst_phase_reg <= 2'b11;
                end
                2'b11: begin
                    dst_handshake_signal <= 1'b0;
                    dst_phase_reg <= 2'b00;
                    dst_valid_o <= 1'b1;
                end
                default: begin
                    dst_phase_reg <= 2'b00;
                end
            endcase
        end
    end

    // Synchronizer cell module
    module sync_cell (
        input  clk_i,
        input  rst_ni,
        input  din,
        output reg dout
    );
        reg dff1, dff2;

        always @(posedge clk_i or negedge rst_ni) begin
            if (!rst_ni) begin
                dff1 <= 1'b0;
                dff2 <= 1'b0;
                dout <= 1'b0;
            end else begin
                dff1 <= din;
                dff2 <= dff1;
                dout <= dff2;
            end
        end
    endmodule

endmodule
