module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic rst_synced;
    logic rst_synced_reg;

    // Synchronize rst_ni to clk_i using a two-stage flip-flop
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_synced <= 1'b1;
            rst_synced_reg <= 1'b1;
        end else begin
            rst_synced <= 1'b0;
            rst_synced_reg <= rst_synced;
        end
    end

    // Generate rst_no and init_no based on test_mode_i
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_no <= 1'b1;
            init_no <= 1'b1;
        end else if (test_mode_i) begin
            rst_no <= rst_ni;
            init_no <= rst_ni;
        end else begin
            rst_no <= rst_synced_reg;
            init_no <= rst_synced_reg;
        end
    end

endmodule
