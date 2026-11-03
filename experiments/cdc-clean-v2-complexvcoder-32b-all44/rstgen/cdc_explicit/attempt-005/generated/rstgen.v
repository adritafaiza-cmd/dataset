module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal signals
    logic rst_no_sync;
    logic init_no_sync;

    // Instantiate the sync_reset module
    sync_reset sync_reset_inst (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .test_mode_i(test_mode_i),
        .rst_no_sync(rst_no_sync),
        .init_no_sync(init_no_sync)
    );

    // Assign the outputs
    assign rst_no = rst_no_sync;
    assign init_no = init_no_sync;

endmodule

module sync_reset (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no_sync,
    output logic init_no_sync
);

    // Internal synchronization registers
    logic rst_sync1;
    logic rst_sync2;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync1 <= 1'b1;
            rst_sync2 <= 1'b1;
        end else begin
            rst_sync1 <= test_mode_i ? rst_ni : 1'b0;
            rst_sync2 <= rst_sync1;
        end
    end

    // Assign the synchronized reset and initialization qualifier
    assign rst_no_sync = rst_sync2;
    assign init_no_sync = test_mode_i ? 1'b0 : ~rst_sync1 & rst_sync2;

endmodule
