module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal signals for synchronization
    logic rst_sync1;
    logic rst_sync2;
    logic init_sync;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync1 <= 1'b1;
            rst_sync2 <= 1'b1;
            init_sync <= 1'b1;
        end else begin
            rst_sync1 <= 1'b0;
            rst_sync2 <= rst_sync1;
            init_sync <= rst_sync2;
        end
    end

    // Assign outputs based on test mode
    assign rst_no  = test_mode_i ? rst_ni : rst_sync2;
    assign init_no = test_mode_i ? rst_ni : init_sync;

endmodule
