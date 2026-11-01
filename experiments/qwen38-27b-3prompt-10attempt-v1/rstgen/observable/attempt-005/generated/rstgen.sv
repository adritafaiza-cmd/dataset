module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronization chain for reset release
    logic [1:0] sync_rst_n;

    always_ff @(posedge clk_i) begin
        sync_rst_n <= {sync_rst_n[0], rst_ni};
    end

    // Synchronized reset (active-low)
    assign rst_no = sync_rst_n[1];

    // Initialization indication: high when reset has been released
    // init_no is high when the reset is deasserted (synchronized)
    assign init_no = rst_no;

endmodule
