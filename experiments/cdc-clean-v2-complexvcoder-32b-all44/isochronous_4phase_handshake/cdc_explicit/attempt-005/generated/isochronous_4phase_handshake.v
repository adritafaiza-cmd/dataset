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

    // Instantiate the phase_detector module
    phase_detector phase_detector_inst (
        .src_clk_i    (src_clk_i),
        .src_rst_ni   (src_rst_ni),
        .src_valid_i  (src_valid_i),
        .src_ready_o  (src_ready_o),
        .dst_clk_i    (dst_clk_i),
        .dst_rst_ni   (dst_rst_ni),
        .dst_ready_i  (dst_ready_i),
        .dst_valid_o  (dst_valid_o)
    );

endmodule

module phase_detector (
    input  src_clk_i,
    input  src_rst_ni,
    input  src_valid_i,
    output src_ready_o,
    input  dst_clk_i,
    input  dst_rst_ni,
    input  dst_ready_i,
    output dst_valid_o
);

    reg [1:0] src_phase;
    reg [1:0] dst_phase;
    reg src_handshake;
    reg dst_handshake;

    // Synchronize reset signals across clock domains
    reg src_rst_sync;
    reg dst_rst_sync;

    // Synchronize dst_rst_ni to src_clk_i
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_rst_sync <= 1'b0;
        end else begin
            src_rst_sync <= dst_rst_ni;
        end
    end

    // Synchronize src_rst_ni to dst_clk_i
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rst_sync <= 1'b0;
        end else begin
            dst_rst_sync <= src_rst_ni;
        end
    end

    // Source-side phase detector logic
    always @(posedge src_clk_i or negedge src_rst_sync) begin
        if (!src_rst_sync) begin
            src_phase <= 2'b00;
            src_handshake <= 1'b0;
        end else if (src_valid_i && src_ready_o) begin
            src_phase <= src_phase + 1'b1;
        end
    end

    // Destination-side phase detector logic
    always @(posedge dst_clk_i or negedge dst_rst_sync) begin
        if (!dst_rst_sync) begin
            dst_phase <= 2'b00;
            dst_handshake <= 1'b0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_phase <= dst_phase + 1'b1;
        end
    end

    // Control src_ready_o based on the phase of the handshake in the source clock domain
    always @(*) begin
        case (src_phase)
            2'b00: src_ready_o = ~src_handshake & dst_ready_i;
            2'b01: src_ready_o = 1'b0;
            2'b10: src_ready_o = 1'b0;
            2'b11: src_ready_o = ~src_handshake & dst_ready_i;
            default: src_ready_o = 1'b0;
        endcase
    end

    // Control dst_valid_o based on the phase of the handshake in the destination clock domain
    always @(*) begin
        case (dst_phase)
            2'b00: dst_valid_o = src_valid_i & ~dst_handshake;
            2'b01: dst_valid_o = 1'b0;
            2'b10: dst_valid_o = 1'b0;
            2'b11: dst_valid_o = src_valid_i & ~dst_handshake;
            default: dst_valid_o = 1'b0;
        endcase
    end

    // Update handshake signals
    always @(posedge src_clk_i or negedge src_rst_sync) begin
        if (!src_rst_sync) begin
            src_handshake <= 1'b0;
        end else if (src_valid_i && src_ready_o) begin
            src_handshake <= 1'b1;
        end else if (dst_ready_i) begin
            src_handshake <= 1'b0;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_sync) begin
        if (!dst_rst_sync) begin
            dst_handshake <= 1'b0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_handshake <= 1'b1;
        end else if (src_valid_i) begin
            dst_handshake <= 1'b0;
        end
    end

endmodule
