module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal signals for synchronization
    logic rst_sync;
    logic rst_sync_reg;
    logic init_sync;
    logic init_sync_reg;

    // Synchronize rst_ni into clk_i domain
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync <= 1'b0;
            rst_sync_reg <= 1'b0;
        end else begin
            rst_sync <= 1'b1;
            rst_sync_reg <= rst_sync;
        end
    end

    // Generate initialization indication after two clock cycles of active reset
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_sync <= 1'b0;
            init_sync_reg <= 1'b0;
        end else begin
            init_sync <= rst_sync_reg;
            init_sync_reg <= init_sync;
        end
    end

    // Assign outputs based on test_mode_i
    assign rst_no = test_mode_i ? rst_ni : rst_sync_reg;
    assign init_no = test_mode_i ? rst_ni : init_sync_reg;

endmodule
