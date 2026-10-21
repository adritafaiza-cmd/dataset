```systemverilog
module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Test mode bypass: if enabled, reset is immediately released (active low)
    // and initialization is asserted for one cycle to indicate state change.
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_no <= 1'b1;
            init_no <= 1'b1;
        end else if (test_mode_i) begin
            rst_no <= 1'b1;
            init_no <= 1'b1;
        end else begin
            // Synchronized reset release logic
            // Use a 2-stage synchronizer to ensure clean release of reset
            // in the clk_i domain.
            logic rst_n_sync_1;
            logic rst_n_sync_2;

            always_ff @(posedge clk_i) begin
                rst_n_sync_1 <= rst_ni;
                rst_n_sync_2 <= rst_n_sync_1;
            end

            // Generate the synchronized reset signal
            // Active low: 1 means reset is active, 0 means reset is released
            rst_no <= ~rst_n_sync_2;

            // Initialization indication:
            // Asserted when the reset transitions from active to inactive.
            // This indicates the domain has just been released from reset.
            if (rst_n_sync_2 && !rst_n_sync_1) begin
                init_no <= 1'b1;
            end else begin
                init_no <= 1'b0;
            end
        end
    end

endmodule
```<|im_end|>
