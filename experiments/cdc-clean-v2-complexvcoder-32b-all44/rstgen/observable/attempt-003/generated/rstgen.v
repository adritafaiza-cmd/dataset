module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal synchronization signals
    logic rst_sync_1;
    logic rst_sync_2;
    logic init_sync;

    // Synchronize rst_ni into the clk_i domain using two flip-flops
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_1 <= 1'b0;
            rst_sync_2 <= 1'b0;
        end else begin
            rst_sync_1 <= 1'b1;
            rst_sync_2 <= rst_sync_1;
        end
    end

    // Bypass synchronization if test_mode_i is active
    always_comb begin
        if (test_mode_i) begin
            rst_no = rst_ni;
        end else begin
            rst_no = rst_sync_2;
        end
    end

    // Generate init_no to indicate the initialization state of the reset
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_sync <= 1'b0;
        end else begin
            init_sync <= 1'b1;
        end
    end

    // Assign init_no to the synchronized initialization signal
    assign init_no = init_sync;

endmodule
