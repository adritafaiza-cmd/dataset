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

// Source domain signals
reg src_phase1, src_phase2;
reg dst_ready_sync1, dst_ready_sync2;

// Destination domain signals
reg dst_phase1, dst_phase2;
reg src_phase1_sync1, src_phase1_sync2;

// Source domain logic
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_phase1 <= 0;
        src_phase2 <= 0;
        dst_ready_sync1 <= 0;
        dst_ready_sync2 <= 0;
    end else begin
        dst_ready_sync1 <= dst_ready_i;
        dst_ready_sync2 <= dst_ready_sync1;

        if (src_phase1) begin
            if (dst_ready_sync2) begin
                src_phase1 <= 0;
                src_phase2 <= 1;
            end
        end else if (src_phase2) begin
            if (!dst_ready_sync2) begin
                src_phase2 <= 0;
            end
        end else if (src_valid_i && src_ready_o) begin
            src_phase1 <= 1;
        end
    end
end

// Assign src_ready_o and dst_valid_o
assign src_ready_o = ~src_phase1 && ~src_phase2;
assign dst_valid_o = src_phase1;

// Destination domain synchronization
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        src_phase1_sync1 <= 0;
        src_phase1_sync2 <= 0;
    end else begin
        src_phase1_sync1 <= src_phase1;
        src_phase1_sync2 <= src_phase1_sync1;
    end
end

endmodule
