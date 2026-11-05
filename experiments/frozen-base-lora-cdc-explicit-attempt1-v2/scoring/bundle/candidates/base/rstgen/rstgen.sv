module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronization chain for reset release
    logic sync_rst_n [2:0];

    always_ff @(posedge clk_i) begin
        sync_rst_n[0] <= rst_ni;
        sync_rst_n[1] <= sync_rst_n[0];
        sync_rst_n[2] <= sync_rst_n[1];
    end

    // Synchronized reset output
    // When test_mode_i is high, bypass synchronization and use rst_ni directly
    assign rst_no = test_mode_i ? rst_ni : sync_rst_n[2];

    // init_no: short initialization qualifier after reset release
    // init_no is high for a few cycles after rst_no goes high (reset released)
    // Use a counter to generate a short pulse after reset release
    logic [1:0] init_cnt;
    logic init_no_reg;

    always_ff @(posedge clk_i) begin
        if (!rst_no) begin
            init_cnt    <= 2'd0;
            init_no_reg <= 1'b0;
        end else begin
            if (init_cnt < 2'd3) begin
                init_cnt    <= init_cnt + 2'd1;
                init_no_reg <= 1'b1;
            end else begin
                init_cnt    <= 2'd0;
                init_no_reg <= 1'b0;
            end
        end
    end

    assign init_no = init_no_reg;

endmodule
