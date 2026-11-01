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
    reg src_valid_r;
    reg src_ready_r;

    // Destination domain state
    reg dst_valid_r;
    reg dst_ready_r;

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
            src_valid_r <= 1'b0;
            src_ready_r <= 1'b1;
        end else begin
            // Four-phase handshake in source domain
            // State 0: idle (valid=0, ready=1)
            // State 1: valid asserted (valid=1, ready=1)
            // State 2: ready deasserted (valid=1, ready=0)
            // State 3: valid deasserted (valid=0, ready=0)
            // Back to State 0

            if (src_valid_r == 1'b0 && src_ready_r == 1'b1) begin
                // Idle state
                if (src_valid_i) begin
                    src_valid_r <= 1'b1;
                    src_ready_r <= 1'b1;
                end
            end else if (src_valid_r == 1'b1 && src_ready_r == 1'b1) begin
                // Valid asserted, waiting for ready to deassert
                if (dst_ready_synced == 1'b0) begin
                    src_ready_r <= 1'b0;
                end
            end else if (src_valid_r == 1'b1 && src_ready_r == 1'b0) begin
                // Ready deasserted, waiting for valid to deassert
                if (src_valid_i == 1'b0) begin
                    src_valid_r <= 1'b0;
                end
            end else if (src_valid_r == 1'b0 && src_ready_r == 1'b0) begin
                // Valid deasserted, waiting for ready to assert
                if (dst_ready_synced == 1'b1) begin
                    src_ready_r <= 1'b1;
                end
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_r <= 1'b0;
            dst_ready_r <= 1'b1;
        end else begin
            // Four-phase handshake in destination domain
            if (dst_valid_r == 1'b0 && dst_ready_r == 1'b1) begin
                // Idle state
                if (src_valid_synced) begin
                    dst_valid_r <= 1'b1;
                    dst_ready_r <= 1'b1;
                end
            end else if (dst_valid_r == 1'b1 && dst_ready_r == 1'b1) begin
                // Valid asserted, waiting for ready to deassert
                if (dst_ready_i == 1'b0) begin
                    dst_ready_r <= 1'b0;
                end
            end else if (dst_valid_r == 1'b1 && dst_ready_r == 1'b0) begin
                // Ready deasserted, waiting for valid to deassert
                if (src_valid_synced == 1'b0) begin
                    dst_valid_r <= 1'b0;
                end
            end else if (dst_valid_r == 1'b0 && dst_ready_r == 1'b0) begin
                // Valid deasserted, waiting for ready to assert
                if (dst_ready_i == 1'b1) begin
                    dst_ready_r <= 1'b1;
                end
            end
        end
    end

    // Synchronizer for src_valid to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync <= 2'b00;
        end else begin
            src_valid_sync <= {src_valid_sync[0], src_valid_r};
        end
    end

    // Synchronizer for dst_ready to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync <= 2'b00;
        end else begin
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_r};
        end
    end

    // Synchronizer for dst_valid to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_valid_sync <= 2'b00;
        end else begin
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_r};
        end
    end

    // Synchronizer for src_ready to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ready_sync <= 2'b00;
        end else begin
            src_ready_sync <= {src_ready_sync[0], src_ready_r};
        end
    end

    assign src_ready_o = src_ready_r;
    assign dst_valid_o = dst_valid_r;

endmodule
