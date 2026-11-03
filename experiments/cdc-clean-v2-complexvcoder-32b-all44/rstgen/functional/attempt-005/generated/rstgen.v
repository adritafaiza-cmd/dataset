module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic rst_sync;
    logic rst_sync_reg;
    logic init_reg;

    // Synchronize rst_ni to clk_i
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync <= 1'b0;
        end else begin
            rst_sync <= 1'b1;
        end
    end

    // Register rst_sync to generate rst_sync_reg
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_reg <= 1'b0;
        end else begin
            rst_sync_reg <= rst_sync;
        end
    end

    // Set init_no high for one clk_i cycle after rst_sync_reg is deasserted
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_reg <= 1'b0;
        end else if (!rst_sync_reg) begin
            init_reg <= 1'b1;
        end else begin
            init_reg <= 1'b0;
        end
    end

    // Assign outputs
    assign rst_no = test_mode_i ? rst_ni : rst_sync_reg;
    assign init_no = init_reg;

endmodule
