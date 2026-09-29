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

    // Synchronize dst_ready_i to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync1 <= 0;
            dst_ready_sync2 <= 0;
        end else begin
            dst_ready_sync1 <= dst_ready_i;
            dst_ready_sync2 <= dst_ready_sync1;
        end
    end

    // Source state machine
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase1 <= 0;
            src_phase2 <= 0;
        end else begin
            if (src_phase1) begin
                if (dst_ready_sync2) begin
                    src_phase1 <= 0;
                    src_phase2 <= 1;
                end
            end else if (src_phase2) begin
                if (!dst_ready_sync2) begin
                    src_phase2 <= 0;
                end
            end else begin
                if (src_valid_i) begin
                    src_phase1 <= 1;
                end
            end
        end
    end

    assign src_ready_o = src_phase1 || src_phase2;

    // Destination domain signals
    reg src_valid_sync1, src_valid_sync2;

    // Synchronize src_valid_i to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync1 <= 0;
            src_valid_sync2 <= 0;
        end else begin
            src_valid_sync1 <= src_valid_i;
            src_valid_sync2 <= src_valid_sync1;
        end
    end

    // Destination state machine
    reg dst_phase1, dst_phase2;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase1 <= 0;
            dst_phase2 <= 0;
            dst_valid_o <= 0;
        end else begin
            if (dst_phase1) begin
                if (!src_valid_sync2) begin
                    dst_phase1 <= 0;
                    dst_phase2 <= 1;
                    dst_valid_o <= 0;
                end
            end else if (dst_phase2) begin
                if (dst_ready_i) begin
                    dst_phase2 <= 0;
                end
            end else begin
                if (src_valid_sync2) begin
                    dst_phase1 <= 1;
                    dst_valid_o <= 1;
                end
            end
        end
    end

endmodule
