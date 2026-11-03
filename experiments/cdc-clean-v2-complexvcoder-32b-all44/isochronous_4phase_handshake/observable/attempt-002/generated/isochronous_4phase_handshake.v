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

    wire src_valid_synced;
    wire dst_ready_synced;

    sync_ff src_valid_sync (
        .data_i(src_valid_i),
        .clk_i(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .data_o(src_valid_synced)
    );

    sync_ff dst_ready_sync (
        .data_i(dst_ready_i),
        .clk_i(src_clk_i),
        .rst_ni(src_rst_ni),
        .data_o(dst_ready_synced)
    );

    assign src_ready_o = dst_ready_synced;
    assign dst_valid_o = src_valid_synced;

endmodule

module sync_ff (
    input  data_i,
    input  clk_i,
    input  rst_ni,
    output data_o
);

    reg sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= 1'b0;
        end else begin
            sync_reg <= data_i;
        end
    end

    assign data_o = sync_reg;

endmodule
