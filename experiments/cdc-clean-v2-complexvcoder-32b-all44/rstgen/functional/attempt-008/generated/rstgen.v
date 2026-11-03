module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal signals for synchronization
    logic rst_sync_1;
    logic rst_sync_2;
    logic rst_combined;
    logic init_qualifier;

    // Synchronize rst_ni to clk_i domain
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_1 <= 1'b1;
            rst_sync_2 <= 1'b1;
        end else begin
            rst_sync_1 <= 1'b0;
            rst_sync_2 <= rst_sync_1;
        end
    end

    // Combine synchronized signals
    assign rst_combined = rst_sync_2;

    // Mux to bypass synchronization in test mode
    assign rst_no = test_mode_i ? rst_ni : rst_combined;

    // Initialize qualifier generation
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_qualifier <= 1'b1;
        end else begin
            init_qualifier <= 1'b0;
        end
    end

    // Output init_no
    assign init_no = init_qualifier;

endmodule
