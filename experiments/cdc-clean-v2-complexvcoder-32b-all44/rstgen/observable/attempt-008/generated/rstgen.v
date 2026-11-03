module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal signals for synchronization
    logic rst_sync_ff1;
    logic rst_sync_ff2;
    logic init_sync_ff1;
    logic init_sync_ff2;

    // Synchronize rst_ni into the clk_i domain using two flip-flops
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_ff1 <= 1'b0;
            rst_sync_ff2 <= 1'b0;
        end else begin
            rst_sync_ff1 <= 1'b1;
            rst_sync_ff2 <= rst_sync_ff1;
        end
    end

    // Generate rst_no as the synchronized reset signal
    assign rst_no = test_mode_i ? rst_ni : rst_sync_ff2;

    // Synchronize initialization signal using two flip-flops
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_sync_ff1 <= 1'b1;
            init_sync_ff2 <= 1'b1;
        end else begin
            init_sync_ff1 <= init_sync_ff2;
            init_sync_ff2 <= rst_sync_ff2;
        end
    end

    // Generate init_no as the initialization indication signal
    assign init_no = test_mode_i ? rst_ni : init_sync_ff1;

endmodule
