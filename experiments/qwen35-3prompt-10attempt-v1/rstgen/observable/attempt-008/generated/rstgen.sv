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

    // Synchronizer chain for rst_ni
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            rst_n_sync_1 <= 1'b1;
        else
            rst_n_sync_1 <= rst_ni;
    end

    always_ff @(posedge clk_i or negedge rst_n_sync_1) begin
        if (!rst_n_sync_1)
            rst_n_sync_2 <= 1'b1;
        else
            rst_n_sync_2 <= rst_n_sync_1;
    end

    // Generate the synchronized reset output
    // If test_mode_i is high, bypass synchronization and pass rst_ni directly
    // Otherwise, use the synchronized signal
    assign rst_no = test_mode_i ? rst_ni : rst_n_sync_2;

    // Generate initialization indication
    // init_no is active low, indicating the system is still initializing
    // It stays low until the synchronized reset is released and stable
    // We add a small delay or check stability to ensure proper initialization sequence
    // Here, we assume init_no should be low during reset and for a few cycles after release
    // to allow internal logic to stabilize.
    
    // Simple approach: init_no is low during reset, and stays low for N cycles after reset release
    // to indicate initialization is in progress.
    // We use a counter that resets when rst_n_sync_2 is low.
    
    logic [3:0] init_cnt;
    
    always_ff @(posedge clk_i or negedge rst_n_sync_2) begin
        if (!rst_n_sync_2)
            init_cnt <= 4'd0;
        else
            init_cnt <= init_cnt + 4'd1;
    end

    // Initialize for 4 cycles after reset release, then go high
    // This gives internal logic time to stabilize
    assign init_no = (init_cnt < 4'd4) ? 1'b0 : 1'b1;

endmodule
```<|im_end|>
