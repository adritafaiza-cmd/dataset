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
    reg src_valid_reg;
    reg dst_valid_reg;
    reg src_ready_reg;
    reg dst_ready_reg;
    reg src_valid_sync;
    reg dst_valid_sync;

    // Synchronize src_valid_i to dst_clk_i
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync <= 1'b0;
        end else begin
            src_valid_sync <= src_valid_i;
        end
    end

    // Synchronize dst_valid_i to src_clk_i
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_valid_sync <= 1'b0;
        end else begin
            dst_valid_sync <= dst_valid_i;
        end
    end

    // Four-phase handshake in src_clk_i domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_reg <= 1'b0;
            src_ready_reg <= 1'b0;
        end else begin
            if (src_ready_reg) begin
                src_valid_reg <= 1'b0;
            end else if (src_valid_i) begin
                src_valid_reg <= 1'b1;
            end

            if (dst_valid_sync) begin
                src_ready_reg <= 1'b1;
            end else begin
                src_ready_reg <= 1'b0;
            end
        end
    end

    // Four-phase handshake in dst_clk_i domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 1'b0;
            dst_ready_reg <= 1'b0;
        end else begin
            if (dst_ready_reg) begin
                dst_valid_reg <= 1'b0;
            end else if (dst_valid_i) begin
                dst_valid_reg <= 1'b1;
            end

            if (src_valid_sync) begin
                dst_ready_reg <= 1'b1;
            end else begin
                dst_ready_reg <= 1'b0;
            end
        end
    end

    // Output assignments
    assign src_ready_o = src_ready_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
