module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronization chain for reset release
    logic sync_rst_n [1:0];

    // Synchronize the asynchronous reset input
    always_ff @(posedge clk_i) begin
        sync_rst_n[0] <= rst_ni;
        sync_rst_n[1] <= sync_rst_n[0];
    end

    // Synchronized reset output
    // In test mode, bypass synchronization
    assign rst_no = test_mode_i ? rst_ni : sync_rst_n[1];

    // Initialization qualifier: pulse high for a few cycles after reset release
    // Use a small counter to generate init_no
    logic [1:0] init_cnt;
    logic init_cnt_done;

    always_ff @(posedge clk_i) begin
        if (rst_no) begin
            init_cnt <= 2'd0;
        end else if (init_cnt < 2'd3) begin
            init_cnt <= init_cnt + 1'b1;
        end
    end

    assign init_cnt_done = (init_cnt == 2'd3);

    // init_no is active-low: low during initialization, high after
    // When reset is asserted, init_no should be low
    // After reset release, init_no stays low for a few cycles then goes high
    assign init_no = rst_no ? 1'b0 : init_cnt_done;

endmodule
