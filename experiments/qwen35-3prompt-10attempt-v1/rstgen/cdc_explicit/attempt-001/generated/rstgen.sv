module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronize the active-low reset signal to the clock domain
    // Using a 2-stage synchronizer to ensure metastability is resolved
    logic rst_n_sync_1;
    logic rst_n_sync_2;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_n_sync_1 <= 1'b1;
        end else begin
            rst_n_sync_1 <= rst_ni;
        end
    end

    always_ff @(posedge clk_i or negedge rst_n_sync_1) begin
        if (!rst_n_sync_1) begin
            rst_n_sync_2 <= 1'b1;
        end else begin
            rst_n_sync_2 <= rst_n_sync_1;
        end
    end

    // Generate the synchronized reset output
    // In test mode, the reset is passed through directly (bypassed)
    // Otherwise, it uses the synchronized signal
    assign rst_no = test_mode_i ? rst_ni : rst_n_sync_2;

    // Generate the initialization qualifier
    // This signal is asserted (low) for a short duration after the reset is released
    // It helps distinguish between power-on reset and normal reset release
    logic rst_n_init;

    always_ff @(posedge clk_i or negedge rst_n_sync_2) begin
        if (!rst_n_sync_2) begin
            rst_n_init <= 1'b1;
        end else begin
            rst_n_init <= 1'b0;
        end
    end

    // Output the active-low initialization qualifier
    assign init_no = rst_n_init;

endmodule<|im_end|>
