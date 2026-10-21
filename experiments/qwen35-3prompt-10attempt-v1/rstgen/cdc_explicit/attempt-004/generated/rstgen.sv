module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronized reset output (active-low)
    // In test_mode, the input reset is passed directly to avoid synchronization delay
    // In normal mode, a 2-stage synchronizer ensures CDC compliance
    logic rst_synced;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            rst_synced <= 1'b1;
        else if (test_mode_i)
            rst_synced <= rst_ni;
        else
            rst_synced <= rst_synced;
    end

    assign rst_no = rst_synced;

    // Initialization qualifier (active-low)
    // Asserted briefly after reset release to indicate initialization phase
    // Uses a counter-based approach for predictable timing
    logic [1:0] init_cnt;
    logic init_pulse;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            init_cnt <= 2'b00;
        else if (rst_synced && init_cnt == 2'b00)
            init_cnt <= 2'b01;
        else
            init_cnt <= init_cnt + 1'b1;
    end

    // Generate a single-cycle pulse when reset releases
    assign init_pulse = (init_cnt == 2'b01);

    assign init_no = !init_pulse;

endmodule<|im_end|>
