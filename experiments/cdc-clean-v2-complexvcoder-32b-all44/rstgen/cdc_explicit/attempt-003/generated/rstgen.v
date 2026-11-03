module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal signals for reset synchronization and initialization
    logic sync_rst_1;
    logic sync_rst_2;
    logic [1:0] init_counter;

    // Synchronize the reset signal using two flip-flops
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_rst_1 <= 1'b1;
            sync_rst_2 <= 1'b1;
        end else begin
            sync_rst_1 <= 1'b0;
            sync_rst_2 <= sync_rst_1;
        end
    end

    // Assign rst_no based on test_mode_i and synchronized reset
    assign rst_no = test_mode_i ? rst_ni : sync_rst_2;

    // Initialize the init_no signal after reset release
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_counter <= 2'b00;
            init_no <= 1'b0;
        end else if (init_counter < 2'b11) begin
            init_counter <= init_counter + 1'b1;
        end else begin
            init_no <= 1'b1;
        end
    end

endmodule
