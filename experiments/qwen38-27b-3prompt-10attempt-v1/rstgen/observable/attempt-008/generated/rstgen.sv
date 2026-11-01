module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronization chain for reset release
    logic [1:0] sync_rst_n;

    // Synchronize the asynchronous reset input into the clk_i domain
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_rst_n <= 2'b00;
        else
            sync_rst_n <= {sync_rst_n[0], 1'b1};
    end

    // Synchronized reset (active-low)
    assign rst_no = sync_rst_n[1];

    // Initialization indication: high when reset is deasserted
    assign init_no = sync_rst_n[1];

    // Test mode bypass: when test_mode_i is high, force reset to be deasserted
    // and initialization to be asserted, bypassing the synchronization logic
    assign rst_no  = test_mode_i ? 1'b1 : sync_rst_n[1];
    assign init_no = test_mode_i ? 1'b1 : sync_rst_n[1];

endmodule
