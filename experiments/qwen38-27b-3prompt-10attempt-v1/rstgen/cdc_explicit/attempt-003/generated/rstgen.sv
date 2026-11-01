module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronization chain for reset release
    logic [1:0] sync_rst_n;

    always_ff @(posedge clk_i) begin
        sync_rst_n <= {sync_rst_n[0], rst_ni};
    end

    // Synchronized reset output
    assign rst_no = sync_rst_n[1];

    // Initialization qualifier: high for a few cycles after reset release
    // Use a counter to generate a short pulse after reset deassertion
    logic [3:0] init_cnt;
    logic init_done;

    always_ff @(posedge clk_i) begin
        if (!rst_no) begin
            init_cnt <= 4'd0;
        end else if (init_cnt < 4'd15) begin
            init_cnt <= init_cnt + 4'd1;
        end
    end

    assign init_done = (init_cnt == 4'd15);

    // init_no is active-low during initialization, high after
    // When test_mode_i is high, bypass synchronization
    assign init_no = test_mode_i ? 1'b1 : init_done;

endmodule
