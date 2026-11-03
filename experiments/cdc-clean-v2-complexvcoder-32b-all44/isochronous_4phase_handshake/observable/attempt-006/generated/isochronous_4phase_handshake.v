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
    reg [1:0] src_phase_synced;
    reg [1:0] dst_phase_synced;
    reg       src_ready;
    reg       dst_valid;

    // Source clock domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase <= 2'b00;
            src_phase_synced <= 2'b00;
            src_ready <= 1'b0;
        end else begin
            // Increment src_phase
            src_phase <= src_phase + 1'b1;
            // Synchronize dst_phase to src_clk_i
            src_phase_synced <= dst_phase;
            // Determine src_ready
            src_ready <= (src_phase_synced == src_phase) && dst_ready_i;
        end
    end

    // Destination clock domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase <= 2'b00;
            dst_phase_synced <= 2'b00;
            dst_valid <= 1'b0;
        end else begin
            // Increment dst_phase
            dst_phase <= dst_phase + 1'b1;
            // Synchronize src_phase to dst_clk_i
            dst_phase_synced <= src_phase;
            // Determine dst_valid
            dst_valid <= (dst_phase_synced == dst_phase) && src_valid_i;
        end
    end

    // Assign outputs
    assign src_ready_o = src_ready;
    assign dst_valid_o = dst_valid;

endmodule
