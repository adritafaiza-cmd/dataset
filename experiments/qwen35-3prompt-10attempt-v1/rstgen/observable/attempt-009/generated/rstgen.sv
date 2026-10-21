```systemverilog
module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronize the asynchronous reset signal to the clk_i domain
    // Using a 2-stage synchronizer to prevent metastability
    logic rst_n_sync_1;
    logic rst_n_sync_2;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_n_sync_1 <= 1'b1;
        end else begin
            rst_n_sync_1 <= rst_n_sync_1;
        end
    end

    always_ff @(posedge clk_i or negedge rst_n_sync_1) begin
        if (!rst_n_sync_1) begin
            rst_n_sync_2 <= 1'b1;
        end else begin
            rst_n_sync_2 <= rst_n_sync_2;
        end
    end

    // Generate the synchronized reset output
    // If test_mode is active, bypass the synchronizer and use the raw input
    // Otherwise, use the synchronized signal
    assign rst_no = test_mode_i ? rst_ni : rst_n_sync_2;

    // Generate the initialization indication
    // The system is considered initialized when the synchronized reset is released
    // and the raw reset input has also been released (to ensure stability)
    // In test mode, initialization is immediate upon reset release
    assign init_no = (test_mode_i && rst_ni) || (!test_mode_i && rst_n_sync_2);

endmodule
```<|im_end|>
