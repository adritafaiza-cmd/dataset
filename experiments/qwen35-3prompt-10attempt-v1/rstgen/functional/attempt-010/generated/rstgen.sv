module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronization logic for the reset signal
    // When test_mode_i is high, the reset is passed directly without synchronization.
    // Otherwise, a 2-stage synchronizer is used to release the reset on the clock domain.
    logic rst_sync_1;
    logic rst_sync_2;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_1 <= 1'b1;
            rst_sync_2 <= 1'b1;
        end else begin
            rst_sync_1 <= rst_ni;
            rst_sync_2 <= rst_sync_1;
        end
    end

    // Generate the synchronized active-low reset output
    // If test_mode_i is high, rst_no follows rst_ni directly.
    // Otherwise, rst_no is the synchronized signal (rst_sync_2).
    assign rst_no = test_mode_i ? rst_ni : rst_sync_2;

    // Generate the initialization qualifier
    // init_no is active low for a short period after reset release.
    // It stays low for one clock cycle after rst_no goes high (reset released).
    // If test_mode_i is high, init_no is always high (no initialization qualifier needed).
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_no <= 1'b1;
        end else if (test_mode_i) begin
            init_no <= 1'b1;
        end else if (rst_no) begin
            // Reset has been released (rst_no is high), start the init pulse
            init_no <= 1'b0;
        end else begin
            // Reset is still active or in the middle of synchronization
            init_no <= 1'b1;
        end
    end

endmodule<|im_end|>
