module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    wire [N-1:0] sync_chain;

    // Instantiate the reset_synchronizer module
    reset_synchronizer #(.N(N)) rst_sync_inst (
        .clk    (clk),
        .rst_in (rst),
        .rst_out(sync_chain[N-1])
    );

    // Generate the synchronization chain
    genvar i;
    generate
        for (i = 0; i < N-1; i = i + 1) begin : gen_sync_chain
            dff_sync_chain dff_sync_chain_inst (
                .clk    (clk),
                .rst_in (sync_chain[i]),
                .rst_out(sync_chain[i+1])
            );
        end
    endgenerate

    // Assign the final synchronized output
    assign out = sync_chain[N-1];

endmodule

module reset_synchronizer #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst_in,
    output wire rst_out
);

    wire [N-1:0] sync_chain;

    // First stage of the synchronizer
    dff_sync_chain dff_sync_chain_inst_0 (
        .clk    (clk),
        .rst_in (rst_in),
        .rst_out(sync_chain[0])
    );

    // Generate the remaining stages of the synchronizer
    genvar i;
    generate
        for (i = 1; i < N; i = i + 1) begin : gen_sync_chain
            dff_sync_chain dff_sync_chain_inst (
                .clk    (clk),
                .rst_in (sync_chain[i-1]),
                .rst_out(sync_chain[i])
            );
        end
    endgenerate

    // Final output of the synchronizer
    assign rst_out = sync_chain[N-1];

endmodule

module dff_sync_chain
(
    input  wire clk,
    input  wire rst_in,
    output reg  rst_out
);

    always @(posedge clk) begin
        rst_out <= rst_in;
    end

endmodule
