module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal synchronization flip-flops for reset
    logic rst_sync_1;
    logic rst_sync_2;

    // Internal synchronization flip-flops for initialization
    logic init_sync_1;
    logic init_sync_2;

    // Synchronize the input reset rst_ni into the clk_i domain using two flip-flops
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_1 <= 1'b0;
            rst_sync_2 <= 1'b0;
        end else begin
            rst_sync_1 <= 1'b1;
            rst_sync_2 <= rst_sync_1;
        end
    end

    // Generate the final synchronized reset
    assign rst_no = test_mode_i ? 1'b0 : rst_sync_2;

    // Generate the initialization indication
    always_ff @(posedge clk_i or negedge rst_no) begin
        if (!rst_no) begin
            init_sync_1 <= 1'b0;
            init_sync_2 <= 1'b0;
        end else begin
            init_sync_1 <= 1'b1;
            init_sync_2 <= init_sync_1;
        end
    end

    // Generate the final initialization indication
    assign init_no = ~init_sync_2;

endmodule
