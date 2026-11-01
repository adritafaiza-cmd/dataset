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
            src_ready_reg <= 1'b1;
        end else begin
            // Four-phase handshake in source domain
            // State 0: Idle (valid=0, ready=1)
            // State 1: Valid asserted (valid=1, ready=1)
            // State 2: Handshake complete (valid=1, ready=0)
            // State 3: Deasserting valid (valid=0, ready=0)
            // State 4: Back to idle (valid=0, ready=1)

            // When dst_ready is synced and we have valid, we can deassert valid
            // When dst_valid is synced and we have ready, we can deassert ready

            if (src_valid_reg && dst_ready_synced) begin
                // Valid is high and destination is ready, so we can deassert valid
                src_valid_reg <= 1'b0;
                src_ready_reg <= 1'b0;
            end else if (!src_valid_reg && !src_ready_reg) begin
                // Both are low, now we can assert ready
                src_ready_reg <= 1'b1;
            end else if (!src_valid_reg && src_ready_reg && src_valid_i) begin
                // Idle state, source wants to send
                src_valid_reg <= 1'b1;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 1'b0;
            dst_ready_reg <= 1'b1;
        end else begin
            // Four-phase handshake in destination domain
            if (dst_valid_reg && dst_ready_i) begin
                // Valid is high and destination is ready, so we can deassert valid
                dst_valid_reg <= 1'b0;
                dst_ready_reg <= 1'b0;
            end else if (!dst_valid_reg && !dst_ready_reg) begin
                // Both are low, now we can assert ready
                dst_ready_reg <= 1'b1;
            end else if (!dst_valid_reg && dst_ready_reg && src_valid_synced) begin
                // Idle state, source has valid
                dst_valid_reg <= 1'b1;
            end
        end
    end

    // Synchronizer for src_valid to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync <= 2'b00;
        end else begin
            src_valid_sync <= {src_valid_sync[0], src_valid_i};
        end
    end

    // Synchronizer for dst_ready to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync <= 2'b00;
        end else begin
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
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

    // Outputs
    assign src_ready_o = src_ready_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
