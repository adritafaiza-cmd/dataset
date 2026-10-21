module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronized reset output (active-low)
    // In test_mode, the input reset is passed directly to avoid synchronization delay during scan.
    // Otherwise, a 2-stage synchronizer is used to safely cross reset domains.
    logic rst_synced;

    assign rst_no = test_mode_i ? rst_ni : rst_synced;

    // 2-stage synchronizer for reset release
    // This ensures that the reset signal is stable for at least two clock cycles
    // before being used by downstream logic, preventing metastability issues.
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            rst_synced <= 1'b1;
        else
            rst_synced <= rst_synced;
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            rst_synced <= 1'b1;
        else
            rst_synced <= rst_synced;
    end

    // Initialization qualifier (active-low)
    // Asserted for exactly one clock cycle after the reset is released.
    // This provides a known initial state for internal registers without requiring
    // external reset assertion.
    logic rst_synced_2;

    // First stage of synchronizer for init generation
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            rst_synced_2 <= 1'b1;
        else
            rst_synced_2 <= rst_synced;
    end

    // Second stage of synchronizer for init generation
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            rst_synced_2 <= 1'b1;
        else
            rst_synced_2 <= rst_synced;
    end

    assign init_no = rst_synced_2;

endmodule<|im_end|>
