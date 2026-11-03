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
    reg  src_dst_ready_sync;
    reg  dst_src_valid_sync;
    reg [1:0] src_phase;
    reg [1:0] dst_phase;

    // Synchronize dst_ready_i to src_clk_i domain
    sync_ff src_sync_dst_ready (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .din(dst_ready_i),
        .dout(src_dst_ready_sync)
    );

    // Synchronize src_valid_i to dst_clk_i domain
    sync_ff dst_sync_src_valid (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .din(src_valid_i),
        .dout(dst_src_valid_sync)
    );

    // Source-side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase <= 2'b00;
            src_ready_o <= 1'b0;
        end else begin
            case (src_phase)
                2'b00: begin
                    src_ready_o <= src_dst_ready_sync;
                    if (src_valid_i && src_dst_ready_sync) begin
                        src_phase <= 2'b01;
                    end
                end
                2'b01: begin
                    if (!src_dst_ready_sync) begin
                        src_phase <= 2'b10;
                    end
                end
                2'b10: begin
                    if (src_dst_ready_sync) begin
                        src_phase <= 2'b11;
                    end
                end
                2'b11: begin
                    if (!src_dst_ready_sync) begin
                        src_phase <= 2'b00;
                    end
                end
                default: src_phase <= 2'b00;
            endcase
        end
    end

    // Destination-side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase <= 2'b00;
            dst_valid_o <= 1'b0;
        end else begin
            case (dst_phase)
                2'b00: begin
                    if (dst_src_valid_sync) begin
                        dst_phase <= 2'b01;
                    end
                end
                2'b01: begin
                    dst_valid_o <= 1'b1;
                    if (dst_ready_i) begin
                        dst_phase <= 2'b10;
                    end
                end
                2'b10: begin
                    if (!dst_ready_i) begin
                        dst_phase <= 2'b11;
                    end
                end
                2'b11: begin
                    if (!dst_src_valid_sync) begin
                        dst_phase <= 2'b00;
                        dst_valid_o <= 1'b0;
                    end
                end
                default: dst_phase <= 2'b00;
            endcase
        end
    end

endmodule

module sync_ff (
    input  clk,
    input  rst_ni,
    input  din,
    output dout
);

    reg ff1;
    reg ff2;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            ff1 <= 1'b0;
            ff2 <= 1'b0;
        end else begin
            ff1 <= din;
            ff2 <= ff1;
        end
    end

    assign dout = ff2;

endmodule
