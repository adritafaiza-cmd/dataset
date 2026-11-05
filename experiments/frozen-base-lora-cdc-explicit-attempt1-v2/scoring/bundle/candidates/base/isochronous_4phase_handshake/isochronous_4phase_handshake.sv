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
    reg src_valid_r;
    reg src_ready_r;

    // Destination domain signals
    reg dst_valid_r;
    reg dst_ready_r;

    // Synchronizers for crossing to destination domain
    reg [1:0] src_valid_sync;
    reg [1:0] src_ready_sync;

    // Synchronizers for crossing to source domain
    reg [1:0] dst_valid_sync;
    reg [1:0] dst_ready_sync;

    // Synchronize src_valid to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_valid_sync <= 2'b00;
        else
            src_valid_sync <= {src_valid_sync[0], src_valid_r};
    end

    // Synchronize src_ready to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_ready_sync <= 2'b00;
        else
            src_ready_sync <= {src_ready_sync[0], src_ready_r};
    end

    // Synchronize dst_valid to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_valid_sync <= 2'b00;
        else
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_r};
    end

    // Synchronize dst_ready to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_sync <= 2'b00;
        else
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_r};
    end

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_r <= 1'b0;
            src_ready_r <= 1'b0;
        end else begin
            // Four-phase handshake in source domain
            // State 0: idle (valid=0, ready=0)
            // State 1: valid asserted (valid=1, ready=0)
            // State 2: ready asserted (valid=1, ready=1)
            // State 3: deasserting (valid=0, ready=1)
            // State 4: idle (valid=0, ready=0)

            // src_valid_r: assert when src_valid_i is high and we are in idle or deasserting state
            // src_ready_r: assert when dst_valid_sync is high (destination has accepted)

            // Simplified four-phase:
            // src_valid_r goes high when src_valid_i is high and src_ready_r is low
            // src_ready_r goes high when dst_valid_sync is high
            // src_valid_r goes low when src_ready_r is high
            // src_ready_r goes low when dst_valid_sync is low

            if (src_valid_i && !src_ready_r) begin
                src_valid_r <= 1'b1;
            end else if (src_ready_r) begin
                src_valid_r <= 1'b0;
            end

            if (dst_valid_sync[1]) begin
                src_ready_r <= 1'b1;
            end else if (!dst_valid_sync[1]) begin
                src_ready_r <= 1'b0;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_r <= 1'b0;
            dst_ready_r <= 1'b0;
        end else begin
            // dst_valid_r: assert when src_valid_sync is high and dst_ready_r is low
            // dst_ready_r: assert when dst_ready_i is high
            // dst_valid_r goes low when dst_ready_r is high
            // dst_ready_r goes low when dst_ready_i is low

            if (src_valid_sync[1] && !dst_ready_r) begin
                dst_valid_r <= 1'b1;
            end else if (dst_ready_r) begin
                dst_valid_r <= 1'b0;
            end

            if (dst_ready_i) begin
                dst_ready_r <= 1'b1;
            end else begin
                dst_ready_r <= 1'b0;
            end
        end
    end

    assign src_ready_o = src_ready_r;
    assign dst_valid_o = dst_valid_r;

endmodule
