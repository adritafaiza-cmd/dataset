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
    reg src_ack_r;

    // Destination domain state
    reg dst_valid_r;
    reg dst_ack_r;

    // Synchronizers for crossing from source to destination
    reg [1:0] src_valid_sync;
    reg [1:0] src_ack_sync;

    // Synchronizers for crossing from destination to source
    reg [1:0] dst_valid_sync;
    reg [1:0] dst_ack_sync;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_r <= 1'b0;
            src_ack_r   <= 1'b0;
        end else begin
            // Four-phase handshake:
            // src_valid_r goes high when src_valid_i is high and src_ack_r is low
            // src_valid_r goes low when src_ack_r is high
            // src_ack_r goes high when dst_valid_sync[1] is high
            // src_ack_r goes low when dst_valid_sync[1] is low (after being high)
            
            // Actually, let's think about this more carefully.
            // Four-phase handshake:
            // Phase 1: src_valid rises, dst_valid rises (after sync)
            // Phase 2: dst_ack rises, src_ack rises (after sync)
            // Phase 3: src_valid falls, dst_valid falls (after sync)
            // Phase 4: dst_ack falls, src_ack falls (after sync)
            
            // Source side:
            // src_valid_r: asserted when src_valid_i is high and src_ack_r is low
            //               deasserted when src_ack_r is high
            // src_ack_r:   asserted when dst_valid_sync[1] is high
            //               deasserted when dst_valid_sync[1] is low
            
            if (src_ack_r) begin
                src_valid_r <= 1'b0;
            end else if (src_valid_i) begin
                src_valid_r <= 1'b1;
            end
            
            if (dst_valid_sync[1]) begin
                src_ack_r <= 1'b1;
            end else begin
                src_ack_r <= 1'b0;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_r <= 1'b0;
            dst_ack_r   <= 1'b0;
        end else begin
            // dst_valid_r: asserted when src_valid_sync[1] is high
            //               deasserted when dst_ack_r is high
            // dst_ack_r:   asserted when dst_ready_i is high and dst_valid_r is high
            //               deasserted when src_valid_sync[1] is low
            
            if (dst_ack_r) begin
                dst_valid_r <= 1'b0;
            end else if (src_valid_sync[1]) begin
                dst_valid_r <= 1'b1;
            end
            
            if (dst_ready_i && dst_valid_r) begin
                dst_ack_r <= 1'b1;
            end else if (!src_valid_sync[1]) begin
                dst_ack_r <= 1'b0;
            end
        end
    end

    // Synchronizers: source to destination
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync <= 2'b00;
            src_ack_sync   <= 2'b00;
        end else begin
            src_valid_sync <= {src_valid_sync[0], src_valid_r};
            src_ack_sync   <= {src_ack_sync[0], src_ack_r};
        end
    end

    // Synchronizers: destination to source
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_valid_sync <= 2'b00;
            dst_ack_sync   <= 2'b00;
        end else begin
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_r};
            dst_ack_sync   <= {dst_ack_sync[0], dst_ack_r};
        end
    end

    // Outputs
    assign src_ready_o = ~src_valid_r;
    assign dst_valid_o = dst_valid_r;

endmodule
