module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal signals for synchronization
    logic rst_sync;
    logic init_sync;

    // Synchronize rst_ni to clk_i domain using two D flip-flops
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync  <= 1'b1;
            init_sync <= 1'b1;
        end else begin
            rst_sync  <= 1'b0;
            init_sync <= rst_sync;
        end
    end

    // Generate rst_no and init_no based on synchronized signals and test_mode_i
    always_comb begin
        if (test_mode_i) begin
            rst_no  = 1'b0;
            init_no = 1'b0;
        end else begin
            rst_no  = rst_sync;
            init_no = rst_sync & init_sync;
        end
    end

endmodule
