```systemverilog
module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronize the asynchronous reset signal to the clk_i domain
    // Using a 2-stage synchronizer to prevent metastability issues
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
    // If test_mode_i is high, bypass synchronization and pass rst_ni directly
    assign rst_no = test_mode_i ? rst_ni : rst_n_sync_2;

    // Generate the initialization indication signal
    // This signal indicates that the local domain has just exited reset
    // It is asserted low when rst_no is low, and deasserted one clock cycle after rst_no goes high
    logic rst_no_prev;
    logic rst_no_next;

    // Capture current state
    assign rst_no_next = rst_no;

    // Capture previous state
    always_ff @(posedge clk_i or negedge rst_n_sync_2) begin
        if (!rst_n_sync_2) begin
            rst_no_prev <= 1'b1;
        end else begin
            rst_no_prev <= rst_no;
        end
    end

    // Logic to detect the transition from reset to non-reset
    // init_no is active low: 1 during reset, 0 after reset is released
    // We want init_no to go low one cycle after rst_no goes high
    always_ff @(posedge clk_i or negedge rst_n_sync_2) begin
        if (!rst_n_sync_2) begin
            init_no <= 1'b1;
        end else begin
            // If current reset is high and previous reset was low, we are exiting reset
            // Set init_no to 0 for this cycle and subsequent cycles until next reset
            // Actually, standard practice for "init done" is to pulse or hold low until next reset.
            // Requirement: "initialization indication". Usually means "is initializing?".
            // Let's interpret: init_no = 1 while in reset, 0 when stable out of reset.
            // To make it a clean flag, we can hold it low once reset is released.
            
            if (rst_no) begin
                // Currently in reset
                init_no <= 1'b1;
            end else if (rst_no_prev) begin
                // Just exited reset
                init_no <= 1'b0;
            end else begin
                // Already out of reset
                init_no <= 1'b0;
            end
        end
    end

endmodule
```<|im_end|>
