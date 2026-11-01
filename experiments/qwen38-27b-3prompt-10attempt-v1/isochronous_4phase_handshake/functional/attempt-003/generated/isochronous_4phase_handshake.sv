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

    // Synchronizers for src_valid to dst domain
    reg [1:0] src_valid_sync;
    wire src_valid_synced = src_valid_sync[1];

    // Synchronizers for dst_ready to src domain
    reg [1:0] dst_ready_sync;
    wire dst_ready_synced = dst_ready_sync[1];

    // Synchronizers for dst_valid to src domain
    reg [1:0] dst_valid_sync;
    wire dst_valid_synced = dst_valid_sync[1];

    // Synchronizers for src_ready to dst domain
    reg [1:0] src_ready_sync;
    wire src_ready_synced = src_ready_sync[1];

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_reg <= 1'b0;
            src_ready_reg <= 1'b0;
        end else begin
            // Four-phase handshake in source domain
            // State 0: idle (valid=0, ready=0)
            // State 1: valid asserted (valid=1, ready=0)
            // State 2: ready asserted (valid=1, ready=1)
            // State 3: deassert valid (valid=0, ready=1)
            // State 4: deassert ready (valid=0, ready=0) -> back to idle

            // We track the handshake state using src_valid_reg and src_ready_reg
            // The source asserts valid when it has data to send
            // The source asserts ready when it sees dst_ready (synchronized)

            // src_valid_reg: source's valid signal
            // src_ready_reg: source's ready signal

            // Four-phase sequence:
            // 1. src_valid goes high (src_valid_reg = 1)
            // 2. dst sees valid, asserts ready (dst_ready_reg = 1)
            // 3. src sees dst_ready, asserts ready (src_ready_reg = 1)
            // 4. dst sees src_ready, deasserts valid (dst_valid_reg = 0)
            // 5. src sees dst_valid deasserted, deasserts valid (src_valid_reg = 0)
            // 6. dst sees src_valid deasserted, deasserts ready (dst_ready_reg = 0)
            // 7. src sees dst_ready deasserted, deasserts ready (src_ready_reg = 0)

            // Source side:
            // - Assert valid when not in a handshake and src_valid_i is high
            // - Assert ready when dst_ready_synced is high and valid is high
            // - Deassert valid when dst_valid_synced is low (dst has deasserted valid)
            // - Deassert ready when dst_ready_synced is low

            if (src_valid_reg == 1'b0 && src_ready_reg == 1'b0) begin
                // Idle state
                if (src_valid_i) begin
                    src_valid_reg <= 1'b1;
                end
            end else if (src_valid_reg == 1'b1 && src_ready_reg == 1'b0) begin
                // Valid asserted, waiting for dst_ready
                if (dst_ready_synced) begin
                    src_ready_reg <= 1'b1;
                end
            end else if (src_valid_reg == 1'b1 && src_ready_reg == 1'b1) begin
                // Both valid and ready asserted, waiting for dst to deassert valid
                if (!dst_valid_synced) begin
                    src_valid_reg <= 1'b0;
                end
            end else if (src_valid_reg == 1'b0 && src_ready_reg == 1'b1) begin
                // Valid deasserted, waiting for dst to deassert ready
                if (!dst_ready_synced) begin
                    src_ready_reg <= 1'b0;
                end
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 1'b0;
            dst_ready_reg <= 1'b0;
        end else begin
            // Four-phase sequence in destination domain:
            // 1. dst sees src_valid, asserts valid (dst_valid_reg = 1)
            // 2. src sees dst_valid, asserts ready (src_ready_reg = 1)
            // 3. dst sees src_ready, asserts ready (dst_ready_reg = 1)
            // 4. src sees dst_ready, deasserts valid (src_valid_reg = 0)
            // 5. dst sees src_valid deasserted, deasserts valid (dst_valid_reg = 0)
            // 6. src sees dst_valid deasserted, deasserts ready (src_ready_reg = 0)
            // 7. dst sees src_ready deasserted, deasserts ready (dst_ready_reg = 0)

            if (dst_valid_reg == 1'b0 && dst_ready_reg == 1'b0) begin
                // Idle state
                if (src_valid_synced) begin
                    dst_valid_reg <= 1'b1;
                end
            end else if (dst_valid_reg == 1'b1 && dst_ready_reg == 1'b0) begin
                // Valid asserted, waiting for src_ready
                if (src_ready_synced) begin
                    dst_ready_reg <= 1'b1;
                end
            end else if (dst_valid_reg == 1'b1 && dst_ready_reg == 1'b1) begin
                // Both valid and ready asserted, waiting for src to deassert valid
                if (!src_valid_synced) begin
                    dst_valid_reg <= 1'b0;
                end
            end else if (dst_valid_reg == 1'b0 && dst_ready_reg == 1'b1) begin
                // Valid deasserted, waiting for src to deassert ready
                if (!src_ready_synced) begin
                    dst_ready_reg <= 1'b0;
                end
            end
        end
    end

    // Synchronizer for src_valid to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync <= 2'b00;
        end else begin
            src_valid_sync <= {src_valid_sync[0], src_valid_reg};
        end
    end

    // Synchronizer for dst_ready to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync <= 2'b00;
        end else begin
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_reg};
        end
    end

    // Synchronizer for dst_valid to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_valid_sync <= 2'b00;
        end else begin
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_reg};
        end
    end

    // Synchronizer for src_ready to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ready_sync <= 2'b00;
        end else begin
            src_ready_sync <= {src_ready_sync[0], src_ready_reg};
        end
    end

    // Output assignments
    assign src_ready_o = src_ready_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
