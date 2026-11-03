module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal signals
    logic rst_sync;
    logic init_sync;

    // Instantiate the sync_reset module
    sync_reset sync_reset_inst (
        .clk_i       (clk_i),
        .rst_ni      (rst_ni),
        .test_mode_i (test_mode_i),
        .rst_sync    (rst_sync),
        .init_no     (init_sync)
    );

    // Assign outputs
    assign rst_no  = rst_sync;
    assign init_no = init_sync;

endmodule

module sync_reset (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_sync,
    output logic init_no
);

    // Internal registers for synchronization
    logic rst_sync_reg1;
    logic rst_sync_reg2;
    logic init_sync_reg1;
    logic init_sync_reg2;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_reg1 <= 1'b1;
            rst_sync_reg2 <= 1'b1;
            init_sync_reg1 <= 1'b0;
            init_sync_reg2 <= 1'b0;
        end else begin
            if (test_mode_i) begin
                rst_sync_reg1 <= rst_ni;
                rst_sync_reg2 <= rst_ni;
            end else begin
                rst_sync_reg1 <= rst_sync_reg2;
            end
            rst_sync_reg2 <= rst_sync_reg1;

            init_sync_reg1 <= ~rst_sync_reg2;
            init_sync_reg2 <= init_sync_reg1;
        end
    end

    // Output the synchronized reset and initialization qualifier
    assign rst_sync = rst_sync_reg2;
    assign init_no  = init_sync_reg2;

endmodule
