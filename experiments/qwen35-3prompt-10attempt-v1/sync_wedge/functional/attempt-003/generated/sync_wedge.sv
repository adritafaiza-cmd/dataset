module sync_wedge #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output r_edge_o,
    output f_edge_o,
    output serial_o
);

    reg [STAGES-1:0] sync_reg;
    wire sync_valid;

    // Synchronizer chain
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_reg <= {STAGES{1'b0}};
        else
            sync_reg <= {sync_reg[STAGES-2:0], serial_i};
    end

    // Valid signal indicates the last stage has settled
    assign sync_valid = sync_reg[STAGES-1];

    // Edge detection logic
    reg prev_sync;
    reg curr_sync;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            prev_sync <= 1'b0;
            curr_sync <= 1'b0;
        end else if (sync_valid) begin
            prev_sync <= curr_sync;
            curr_sync <= sync_reg[STAGES-1];
        end
    end

    assign r_edge_o = (en_i) ? (curr_sync & ~prev_sync) : 1'b0;
    assign f_edge_o = (en_i) ? (~curr_sync & prev_sync) : 1'b0;
    assign serial_o = sync_valid ? sync_reg[STAGES-1] : 1'b0;

endmodule<|im_end|>
