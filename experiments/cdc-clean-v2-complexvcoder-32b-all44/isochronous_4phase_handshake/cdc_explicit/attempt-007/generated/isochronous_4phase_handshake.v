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

    // Internal signals for synchronization and CDC
    reg    src_valid_i_synced;
    reg    src_valid_i_crossed;
    reg    dst_ready_i_synced;
    reg    dst_ready_i_crossed;

    // Synchronize src_valid_i to dst_clk_i
    sync_register sync_src_valid (
        .clk_i  (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .d_i    (src_valid_i),
        .q_o    (src_valid_i_synced)
    );

    // Cross clock domain from src_clk_i to dst_clk_i
    cdc_flipflop ff_src_to_dst (
        .clk_i  (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .d_i    (src_valid_i_synced),
        .q_o    (src_valid_i_crossed)
    );

    // Synchronize dst_ready_i to src_clk_i
    sync_register sync_dst_ready (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .d_i    (dst_ready_i),
        .q_o    (dst_ready_i_synced)
    );

    // Cross clock domain from dst_clk_i to src_clk_i
    cdc_flipflop ff_dst_to_src (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .d_i    (dst_ready_i_synced),
        .q_o    (dst_ready_i_crossed)
    );

    // Assign outputs based on the four-phase handshake
    assign src_ready_o = dst_ready_i_crossed;
    assign dst_valid_o = src_valid_i_crossed;

endmodule

module cdc_flipflop (
    input  clk_i,
    input  rst_ni,
    input  d_i,
    output q_o
);

    reg ff1_q;
    reg q_o_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ff1_q   <= 1'b0;
            q_o_reg <= 1'b0;
        end else begin
            ff1_q   <= d_i;
            q_o_reg <= ff1_q;
        end
    end

    assign q_o = q_o_reg;

endmodule

module sync_register (
    input  clk_i,
    input  rst_ni,
    input  d_i,
    output q_o
);

    reg q_o_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            q_o_reg <= 1'b0;
        end else begin
            q_o_reg <= d_i;
        end
    end

    assign q_o = q_o_reg;

endmodule
