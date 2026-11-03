module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal signals for synchronization and initialization
    logic rst_sync1;
    logic rst_sync2;
    logic rst_bypass;
    logic init_bypass;
    logic rst_no_prev;

    // Synchronizer flip-flops
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync1 <= 1'b1;
            rst_sync2 <= 1'b1;
        end else begin
            rst_sync1 <= rst_ni;
            rst_sync2 <= rst_sync1;
        end
    end

    // Bypass synchronization in test mode
    assign rst_bypass = test_mode_i ? rst_ni : rst_sync2;

    // Active-low reset output
    assign rst_no = rst_bypass;

    // Previous value of rst_no for init_no generation
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_no_prev <= 1'b0;
        end else begin
            rst_no_prev <= rst_no;
        end
    end

    // Initialization qualifier
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_no <= 1'b0;
        end else begin
            init_no <= (rst_no_prev == 1'b0) && (rst_no == 1'b1);
        end
    end

endmodule
