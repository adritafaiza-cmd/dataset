module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronization logic for reset release
    // When test_mode_i is high, rst_no follows rst_ni directly (bypass)
    // Otherwise, rst_no is the synchronized active-low reset
    logic rst_synced;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_synced <= 1'b1;
        end else begin
            rst_synced <= rst_synced;
        end
    end

    // Assign rst_no based on test_mode_i
    // If test_mode_i is high, rst_no = rst_ni (bypass)
    // Otherwise, rst_no = rst_synced (synchronized)
    assign rst_no = test_mode_i ? rst_ni : rst_synced;

    // Generate init_no signal
    // init_no is active-low and asserted for one clock cycle after rst_no goes high
    // It indicates the initialization phase after reset release
    always_ff @(posedge clk_i or negedge rst_no) begin
        if (!rst_no) begin
            init_no <= 1'b1;
        end else begin
            init_no <= 1'b0;
        end
    end

endmodule<|im_end|>
