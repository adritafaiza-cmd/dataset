module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal signals
    logic rst_sync;
    logic rst_sync_reg;
    logic init_reg;

    // Synchronization of rst_ni to clk_i domain using two FFs
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync <= 1'b1;
            rst_sync_reg <= 1'b1;
        end else begin
            rst_sync <= 1'b0;
            rst_sync_reg <= rst_sync;
        end
    end

    // Bypass synchronization in test mode
    assign rst_no = test_mode_i ? rst_ni : rst_sync_reg;

    // Initialization qualifier logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_reg <= 1'b1;
        end else if (rst_sync_reg) begin
            init_reg <= 1'b0;
        end
    end

    assign init_no = init_reg;

endmodule
