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

    // Internal signals for synchronization
    reg async_src_valid;
    reg sync_src_valid;
    reg async_dst_ready;
    reg sync_dst_ready;

    // Instantiate the CDC synchronizers
    cdc_synchronizer src_to_dst_sync (
        .async_in(src_valid_i),
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .sync_out(sync_src_valid)
    );

    cdc_synchronizer dst_to_src_sync (
        .async_in(dst_ready_i),
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .sync_out(sync_dst_ready)
    );

    // Assign the synchronized signals to the output ports
    assign dst_valid_o = sync_src_valid;
    assign src_ready_o = sync_dst_ready;

endmodule

module cdc_synchronizer (
    input  async_in,
    input  clk,
    input  rst_ni,
    output sync_out
);

    // Internal synchronization registers
    reg sync_reg1;
    reg sync_reg2;

    // Two-stage synchronization with reset handling
    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg1 <= 1'b0;
            sync_reg2 <= 1'b0;
        end else begin
            sync_reg1 <= async_in;
            sync_reg2 <= sync_reg1;
        end
    end

    // Assign the final synchronized output
    assign sync_out = sync_reg2;

endmodule
