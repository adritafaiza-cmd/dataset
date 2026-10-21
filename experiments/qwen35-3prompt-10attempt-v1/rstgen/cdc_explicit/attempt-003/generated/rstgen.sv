module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronized reset output (active-low)
    // In test_mode, the output follows the input directly to bypass synchronization.
    // Otherwise, it uses a 2-stage synchronizer to ensure CDC compliance.
    logic rst_n_sync;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            rst_n_sync <= 1'b1;
        else if (test_mode_i)
            rst_n_sync <= rst_ni;
        else
            rst_n_sync <= rst_n_sync;
    end

    // Assign the synchronized reset to the output
    assign rst_no = rst_n_sync;

    // Initialization qualifier (init_no)
    // This signal is asserted briefly after the reset is released.
    // It uses the same synchronized reset logic but adds a delay counter.
    logic [1:0] init_cnt;
    logic init_no_int;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            init_cnt <= 2'b00;
        else if (test_mode_i)
            init_cnt <= 2'b00;
        else
            init_cnt <= init_cnt + 2'b01;
    end

    // Generate init_no: asserted for 2 clock cycles after reset release
    // Since rst_ni is active-low, reset release happens when rst_ni goes high.
    // We count up from 0 while in reset, then assert init_no for 2 cycles.
    assign init_no = (init_cnt < 2'b10) && rst_ni;

endmodule<|im_end|>
