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

    // Source domain state
    reg src_valid_reg;
    reg src_ready_reg;

    // Destination domain state
    reg dst_valid_reg;
    reg dst_ready_reg;

    // Synchronizers for signals crossing to destination domain
    reg [1:0] src_valid_sync;
    reg [1:0] dst_ready_sync;

    // Synchronizers for signals crossing to source domain
    reg [1:0] dst_valid_sync;
    reg [1:0] src_ready_sync;

    // Synchronizer for reset signals (to ensure safe reset release)
    // We synchronize the reset from the other domain to detect when it's safe
    // Actually, for 4-phase handshake, we need to ensure that when one side
    // deasserts its signal, the other side has seen it before asserting again.
    // The standard 4-phase handshake uses two bits per direction.

    // Let's use a simpler approach:
    // Source side:
    //   src_valid_reg: asserted when source has data, deasserted when dst_ready seen
    //   src_ready_reg: asserted when dst_valid seen, deasserted when src_valid seen
    //
    // Destination side:
    //   dst_valid_reg: asserted when src_valid seen, deasserted when dst_ready seen
    //   dst_ready_reg: asserted when dst_valid seen, deasserted when src_ready seen

    // Synchronize src_valid to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_valid_sync <= 2'b00;
        else
            src_valid_sync <= {src_valid_sync[0], src_valid_reg};
    end

    // Synchronize dst_ready to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_sync <= 2'b00;
        else
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_reg};
    end

    // Synchronize dst_valid to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_valid_sync <= 2'b00;
        else
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_reg};
    end

    // Synchronize src_ready to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_ready_sync <= 2'b00;
        else
            src_ready_sync <= {src_ready_sync[0], src_ready_reg};
    end

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_reg <= 1'b0;
            src_ready_reg <= 1'b0;
        end else begin
            // Four-phase handshake:
            // Phase 1: src_valid rises (src_valid_reg = 1)
            // Phase 2: dst_valid rises (dst_valid_reg = 1)
            // Phase 3: dst_ready rises (dst_ready_reg = 1)
            // Phase 4: src_ready rises (src_ready_reg = 1)
            // Then all deassert in reverse order.

            // Assert src_valid when source has valid input and we're not already in a transaction
            // Deassert src_valid when dst_ready is seen (synchronized)
            if (src_valid_i && !src_valid_reg) begin
                src_valid_reg <= 1'b1;
            end else if (dst_ready_sync[1]) begin
                src_valid_reg <= 1'b0;
            end

            // Assert src_ready when dst_valid is seen (synchronized)
            // Deassert src_ready when src_valid is asserted (new transaction)
            if (dst_valid_sync[1] && !src_ready_reg) begin
                src_ready_reg <= 1'b1;
            end else if (src_valid_reg) begin
                src_ready_reg <= 1'b0;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 1'b0;
            dst_ready_reg <= 1'b0;
        end else begin
            // Assert dst_valid when src_valid is seen (synchronized)
            // Deassert dst_valid when dst_ready is asserted
            if (src_valid_sync[1] && !dst_valid_reg) begin
                dst_valid_reg <= 1'b1;
            end else if (dst_ready_i) begin
                dst_valid_reg <= 1'b0;
            end

            // Assert dst_ready when dst_valid is asserted
            // Deassert dst_ready when src_ready is seen (synchronized)
            if (dst_valid_reg && !dst_ready_reg) begin
                dst_ready_reg <= 1'b1;
            end else if (src_ready_sync[1]) begin
                dst_ready_reg <= 1'b0;
            end
        end
    end

    assign src_ready_o = src_ready_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
