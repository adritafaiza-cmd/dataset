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
    reg src_ack_reg;

    // Destination domain signals
    reg dst_valid_reg;
    reg dst_ack_reg;

    // Synchronizers for crossing from source to destination
    reg [1:0] src_valid_sync;
    reg [1:0] src_ack_sync;

    // Synchronizers for crossing from destination to source
    reg [1:0] dst_valid_sync;
    reg [1:0] dst_ack_sync;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_reg <= 1'b0;
            src_ack_reg   <= 1'b0;
        end else begin
            // Four-phase handshake in source domain
            // src_valid_reg goes high when src_valid_i is high and src_ack_reg is low
            // src_ack_reg goes high when dst_ack_sync[1] is high (ack from dest)
            // src_valid_reg goes low when src_ack_reg is high (after ack received)
            // src_ack_reg goes low when src_valid_reg is low (after valid deasserted)

            if (src_valid_i && !src_ack_reg) begin
                src_valid_reg <= 1'b1;
            end else if (src_ack_reg && !src_valid_i) begin
                src_valid_reg <= 1'b0;
            end

            if (dst_ack_sync[1] && !src_valid_reg) begin
                src_ack_reg <= 1'b1;
            end else if (!dst_ack_sync[1] && src_valid_reg) begin
                src_ack_reg <= 1'b0;
            end
        end
    end

    // Source ready is high when source is not in a valid state
    assign src_ready_o = !src_valid_reg;

    // Synchronize src_valid_reg to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync <= 2'b00;
        end else begin
            src_valid_sync <= {src_valid_sync[0], src_valid_reg};
        end
    end

    // Synchronize src_ack_reg to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ack_sync <= 2'b00;
        end else begin
            src_ack_sync <= {src_ack_sync[0], src_ack_reg};
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 1'b0;
            dst_ack_reg   <= 1'b0;
        end else begin
            // Four-phase handshake in destination domain
            // dst_valid_reg goes high when src_valid_sync[1] is high and dst_ack_reg is low
            // dst_ack_reg goes high when dst_ready_i is high and dst_valid_reg is high
            // dst_valid_reg goes low when dst_ack_reg is high (after ack sent)
            // dst_ack_reg goes low when dst_valid_reg is low (after valid deasserted)

            if (src_valid_sync[1] && !dst_ack_reg) begin
                dst_valid_reg <= 1'b1;
            end else if (dst_ack_reg && !src_valid_sync[1]) begin
                dst_valid_reg <= 1'b0;
            end

            if (dst_ready_i && dst_valid_reg) begin
                dst_ack_reg <= 1'b1;
            end else if (!dst_ready_i && !dst_valid_reg) begin
                dst_ack_reg <= 1'b0;
            end
        end
    end

    // Destination valid output
    assign dst_valid_o = dst_valid_reg;

    // Synchronize dst_valid_reg to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_valid_sync <= 2'b00;
        end else begin
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_reg};
        end
    end

    // Synchronize dst_ack_reg to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ack_sync <= 2'b00;
        end else begin
            dst_ack_sync <= {dst_ack_sync[0], dst_ack_reg};
        end
    end

endmodule
