module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal signals for reset synchronization
    logic rst_sync1;
    logic rst_sync2;
    logic rst_sync3;

    // Internal signal for initialization counter
    logic [1:0] init_counter;

    // Synchronize the reset signal
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync1 <= 1'b1;
            rst_sync2 <= 1'b1;
            rst_sync3 <= 1'b1;
        end else begin
            rst_sync1 <= rst_ni;
            rst_sync2 <= rst_sync1;
            rst_sync3 <= rst_sync2;
        end
    end

    // Assign the final synchronized reset output
    assign rst_no = test_mode_i ? rst_ni : rst_sync3;

    // Initialization counter logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_counter <= 2'b11; // Start with initialization phase
        end else begin
            if (init_counter != 2'b00) begin
                init_counter <= init_counter - 1;
            end
        end
    end

    // Assign the initialization qualifier output
    assign init_no = test_mode_i ? rst_ni : (init_counter != 2'b00);

endmodule
