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

    // Generate the synchronized reset
    // If test_mode_i is high, bypass the synchronizer and use the raw input directly
    // This allows for faster reset assertion/release during testing if needed
    assign rst_no = test_mode_i ? rst_ni : rst_n_sync_2;

    // Generate the initialization indication
    // The module is considered initialized when the synchronized reset is released
    // and the system has had at least one clock cycle in the reset-free state.
    // Since rst_no is the active-low reset, !rst_no indicates the reset is released.
    // We use a flip-flop to capture the state of the reset release.
    logic init_done;

    always_ff @(posedge clk_i or negedge rst_no) begin
        if (!rst_no) begin
            init_done <= 1'b0;
        end else begin
            // Once reset is released, init_done stays high forever
            init_done <= 1'b1;
        end
    end

    assign init_no = init_done;

endmodule
```<|im_end|>
