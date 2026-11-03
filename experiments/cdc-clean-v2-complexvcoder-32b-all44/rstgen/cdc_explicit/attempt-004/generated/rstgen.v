module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Internal signals
    logic sync_rst_n;
    logic rst_no_reg;
    logic init_no_reg;

    // Synchronize rst_ni to clk_i domain unless test_mode_i is high
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_rst_n <= 1'b0;
        end else begin
            sync_rst_n <= test_mode_i ? rst_ni : sync_rst_n;
        end
    end

    // Second stage of synchronization
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_no_reg <= 1'b0;
        end else begin
            rst_no_reg <= test_mode_i ? rst_ni : sync_rst_n;
        end
    end

    // Assign the synchronized reset output
    assign rst_no = rst_no_reg;

    // Initialize init_no_reg to 0 after reset release
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_no_reg <= 1'b0;
        end else if (!rst_no_reg) begin
            init_no_reg <= 1'b1;
        end else begin
            init_no_reg <= 1'b0;
        end
    end

    // Assign the initialization qualifier output
    assign init_no = init_no_reg;

endmodule
