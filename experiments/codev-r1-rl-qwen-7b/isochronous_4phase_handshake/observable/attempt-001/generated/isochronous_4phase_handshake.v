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

    // Synchronize dst_ready_i to src_clk
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync1 <= 1'b0;
            dst_ready_sync2 <= 1'b0;
        end else begin
            dst_ready_sync1 <= dst_ready_i;
            dst_ready_sync2 <= dst_ready_sync1;
        end
    end

    // src_valid_reg: holds the valid until handshake completes
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_reg <= 1'b0;
        end else begin
            if (src_ready_o && src_valid_i) begin
                src_valid_reg <= 1'b1;
            end else if (dst_ready_sync2) begin
                src_valid_reg <= 1'b0;
            end
        end
    end

    assign src_ready_o = ~src_valid_reg;

    // Synchronize src_valid_reg to dst_clk
    reg src_valid_sync1, src_valid_sync2;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync1 <= 1'b0;
            src_valid_sync2 <= 1'b0;
        end else begin
            src_valid_sync1 <= src_valid_reg;
            src_valid_sync2 <= src_valid_sync1;
        end
    end

    // Destination domain: generate dst_valid_o
    reg dst_valid_reg;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_valid_reg) begin
                if (dst_ready_i) begin
                    dst_valid_reg <= 1'b0;
                end
            end else begin
                if (src_valid_sync2) begin
                    dst_valid_reg <= 1'b1;
                end
            end
        end
    end

    assign dst_valid_o = dst_valid_reg;

endmodule
