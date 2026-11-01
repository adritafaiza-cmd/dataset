module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronization chain for reset release
    logic [2:0] sync_ff;

    // Synchronize the external reset into the clk_i domain
    always_ff @(posedge clk_i) begin
        sync_ff <= {sync_ff[1:0], rst_ni};
    end

    // Synchronized reset (active-low)
    logic rst_sync_no;
    assign rst_sync_no = sync_ff[2];

    // Test mode bypass: if test_mode_i is high, force reset released
    assign rst_no = test_mode_i ? 1'b1 : rst_sync_no;

    // Initialization indication: high when reset has been released
    // init_no is high when the reset is not active (i.e., reset released)
    assign init_no = rst_no;

endmodule
