module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronization chain for reset release
    logic [1:0] rst_sync;

    // Synchronize the external reset into the clk_i domain
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            rst_sync <= 2'b00;
        else
            rst_sync <= {rst_sync[0], 1'b1};
    end

    // Synchronized reset (active-low)
    assign rst_no = rst_sync[1];

    // Initialization indication: high when reset is deasserted
    assign init_no = rst_sync[1];

    // Test-mode bypass: when test_mode_i is high, bypass the reset
    // and force rst_no and init_no to active (deasserted) state
    assign rst_no  = test_mode_i ? 1'b1 : rst_sync[1];
    assign init_no = test_mode_i ? 1'b1 : rst_sync[1];

endmodule
