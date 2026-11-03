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
    logic init_sync_1;
    logic init_sync_2;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_1 <= 1'b1;
            rst_sync_2 <= 1'b1;
        end else begin
            rst_sync_1 <= 1'b0;
            rst_sync_2 <= rst_sync_1;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_sync_1 <= 1'b1;
            init_sync_2 <= 1'b1;
        end else begin
            init_sync_1 <= 1'b0;
            init_sync_2 <= init_sync_1;
        end
    end

    // Assign the final synchronized reset and initialization signals
    assign rst_no  = test_mode_i ? rst_ni : rst_sync_2;
    assign init_no = test_mode_i ? rst_ni : ~rst_sync_2;

endmodule
