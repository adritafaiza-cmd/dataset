module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronization logic for the reset signal
    // When test_mode_i is high, the reset is passed through directly (bypass).
    // Otherwise, a 2-stage synchronizer is used to ensure metastability is resolved.
    logic rst_sync_1, rst_sync_2;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_1 <= 1'b0;
            rst_sync_2 <= 1'b0;
        end else begin
            rst_sync_1 <= rst_ni;
            rst_sync_2 <= rst_sync_1;
        end
    end

    // Generate the synchronized active-low reset output
    // If test_mode_i is high, rst_no follows rst_ni directly.
    // Otherwise, rst_no follows the synchronized signal rst_sync_2.
    assign rst_no = test_mode_i ? rst_ni : rst_sync_2;

    // Generate the initialization qualifier
    // init_no is asserted (0) for one clock cycle after the reset is released.
    // It is de-asserted (1) once the reset is stable.
    // In test mode, it follows the same logic as rst_no but delayed by one cycle relative to release.
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_no <= 1'b1;
        end else begin
            // If reset was released in the previous cycle, assert init_no for this cycle
            if (rst_sync_2 && !rst_sync_1) begin
                init_no <= 1'b1;
            end else begin
                // If still in reset or reset just released previously (handled by above),
                // we need to ensure init_no goes low after the first valid cycle post-reset.
                // However, the requirement is "short initialization qualifier after reset release".
                // Standard interpretation: init_no is 0 while rst is active, then 1 for 1 cycle, then 0.
                // OR: init_no is 0 for 1 cycle after reset release, then 1.
                // Given "init_no is a short initialization qualifier", typically it means:
                // 0 during reset, 0 for 1 cycle after release (to allow logic to settle), then 1.
                // Let's implement: init_no = 0 when rst is active OR rst just released.
                // Actually, a common pattern for "init qualifier" is:
                // 0 during reset, 0 for 1 cycle after reset release, then 1.
                // Let's refine:
                // If rst_sync_2 is 0 (reset active), init_no = 0.
                // If rst_sync_2 is 1 (reset released) AND rst_sync_1 was 0 (just released), init_no = 0.
                // Otherwise init_no = 1.
                
                if (!rst_sync_2) begin
                    init_no <= 1'b0;
                end else if (!rst_sync_1) begin
                    // Reset just released
                    init_no <= 1'b0;
                end else begin
                    init_no <= 1'b1;
                end
            end
        end
    end

endmodule<|im_end|>
