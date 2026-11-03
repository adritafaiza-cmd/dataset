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
    reg [1:0] src_phase_synced;
    reg [1:0] dst_phase_synced;
    reg [1:0] src_phase_ff;
    reg [1:0] dst_phase_ff;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase <= 2'b00;
            src_phase_ff <= 2'b00;
            src_ready_o <= 1'b0;
        end else begin
            src_phase_ff <= src_phase;
            case (src_phase)
                2'b00: begin
                    if (src_valid_i) begin
                        src_phase <= 2'b01;
                    end
                end
                2'b01: begin
                    if (src_phase_synced == 2'b10) begin
                        src_phase <= 2'b10;
                    end
                end
                2'b10: begin
                    if (src_phase_synced == 2'b11) begin
                        src_phase <= 2'b11;
                    end
                end
                2'b11: begin
                    if (src_phase_synced == 2'b00) begin
                        src_phase <= 2'b00;
                        src_ready_o <= 1'b1;
                    end
                end
            endcase
        end
    end

    // Synchronize dst_phase to src_clk_i
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase_synced <= 2'b00;
        end else begin
            src_phase_synced <= dst_phase_ff;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase <= 2'b00;
            dst_phase_ff <= 2'b00;
            dst_valid_o <= 1'b0;
        end else begin
            dst_phase_ff <= dst_phase;
            case (dst_phase)
                2'b00: begin
                    if (dst_ready_i) begin
                        dst_phase <= 2'b01;
                    end
                end
                2'b01: begin
                    if (dst_phase_synced == 2'b10) begin
                        dst_phase <= 2'b10;
                    end
                end
                2'b10: begin
                    if (dst_phase_synced == 2'b11) begin
                        dst_phase <= 2'b11;
                    end
                end
                2'b11: begin
                    if (dst_phase_synced == 2'b00) begin
                        dst_phase <= 2'b00;
                        dst_valid_o <= 1'b1;
                    end
                end
            endcase
        end
    end

    // Synchronize src_phase to dst_clk_i
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase_synced <= 2'b00;
        end else begin
            dst_phase_synced <= src_phase_ff;
        end
    end

endmodule
