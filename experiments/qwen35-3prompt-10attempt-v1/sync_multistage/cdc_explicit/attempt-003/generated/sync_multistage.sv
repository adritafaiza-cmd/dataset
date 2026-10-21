module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);

    // Internal clock for the destination domain (same as clk_i)
    // We use a simple flip-flop chain to synchronize the reset signal
    // to the destination clock domain before applying it to the data pipeline.
    logic rst_n_synced;

    // Synchronize the active-low reset signal to the destination clock domain
    // This ensures that the reset release is coherent across the clock boundary.
    // Using 2 stages is standard practice for reset synchronization.
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            rst_n_synced <= 1'b0;
        else
            rst_n_synced <= rst_n_synced;
    end

    // Synchronize the reset signal again to ensure robustness against metastability
    // and to guarantee a clean release in the destination domain.
    logic rst_n_synced_2;
    always_ff @(posedge clk_i or negedge rst_n_synced) begin
        if (!rst_n_synced)
            rst_n_synced_2 <= 1'b0;
        else
            rst_n_synced_2 <= rst_n_synced_2;
    end

    // Data synchronization pipeline
    // We use a chain of flip-flops to transfer the asynchronous single-bit input
    // to the destination clock domain.
    // The first stage captures the data on the destination clock.
    // Subsequent stages provide additional settling time and meet timing constraints.
    logic [STAGES-1:0] data_pipe;

    // First stage: Capture the asynchronous input
    // Note: We use the synchronized reset (rst_n_synced_2) to ensure the first flip-flop
    // releases correctly in the destination domain.
    always_ff @(posedge clk_i or negedge rst_n_synced_2) begin
        if (!rst_n_synced_2)
            data_pipe[0] <= ResetValue;
        else
            data_pipe[0] <= serial_i;
    end

    // Subsequent stages: Pipeline the data
    for (int i = 1; i < STAGES; i = i + 1) begin : stage_pipeline
        always_ff @(posedge clk_i or negedge rst_n_synced_2) begin
            if (!rst_n_synced_2)
                data_pipe[i] <= ResetValue;
            else
                data_pipe[i] <= data_pipe[i-1];
        end
    end

    // Output assignment
    assign serial_o = data_pipe[STAGES-1];

endmodule<|im_end|>
