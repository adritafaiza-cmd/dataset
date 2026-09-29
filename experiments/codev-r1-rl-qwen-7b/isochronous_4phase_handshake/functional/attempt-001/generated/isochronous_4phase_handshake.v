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
    reg src_valid_reg;
    reg dst_ready_sync1, dst_ready_sync2;

    // Destination domain signals
    reg dst_valid_reg;
    reg src_valid_sync1, src_valid_sync2;
    reg src_ready_sync1, src_ready_sync2;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_reg <= 1'b0;
            dst_ready_sync1 <= 1'b0;
            dst_ready_sync2 <= 1'b0;
        end else begin
            dst_ready_sync1 <= dst_ready_i;
            dst_ready_sync2 <= dst_ready_sync1;

            // Start handshake when valid input is received and not busy
            if (src_valid_i && !src_valid_reg)
                src_valid_reg <= 1'b1;
            // Deassert valid once destination acknowledges
            else if (src_valid_reg && dst_ready_sync2)
                src_valid_reg <= 1'b0;
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 1'b0;
            src_valid_sync1 <= 1'b0;
            src_valid_sync2 <= 1'b0;
            src_ready_sync1 <= 1'b0;
            src_ready_sync2 <= 1'b0;
        end else begin
            src_valid_sync1 <= src_valid_reg;
            src_valid_sync2 <= src_valid_sync1;

            // Synchronize src_ready_o to destination domain
            src_ready_sync1 <= src_ready_o;
            src_ready_sync2 <= src_ready_sync1;

            // Handshake steps
            if (src_valid_sync2 && !dst_valid_reg)
                dst_valid_reg <= 1'b1;
            else if (dst_valid_reg && src_ready_sync2)
                dst_valid_reg <= 1'b0;
        end
    end

    assign src_ready_o = ~src_valid_reg; // Ready when not busy
    assign dst_valid_o = dst_valid_reg;

endmodule
