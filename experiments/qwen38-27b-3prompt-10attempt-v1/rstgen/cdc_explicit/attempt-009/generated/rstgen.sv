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
    assign rst_no = sync_rst_n[2];

    // Initialization qualifier: high for a few cycles after reset release
    // Use a counter to generate a short pulse after reset is deasserted
    logic [1:0] init_cnt;
    logic init_pulse;

    always_ff @(posedge clk_i) begin
        if (!rst_no) begin
            init_cnt <= 2'd0;
        end else begin
            if (init_cnt != 2'd3) begin
                init_cnt <= init_cnt + 2'd1;
            end
        end
    end

    assign init_pulse = (init_cnt == 2'd3);

    // init_no is active-low: low during initialization, high after
    // We want init_no to be low for a short period after reset release
    // Let's use a different approach: init_no is low for the first few cycles after reset release
    logic init_no_reg;

    always_ff @(posedge clk_i) begin
        if (!rst_no) begin
            init_no_reg <= 1'b0;
        end else begin
            if (init_cnt == 2'd0) begin
                init_no_reg <= 1'b0;
            end else if (init_cnt == 2'd3) begin
                init_no_reg <= 1'b1;
            end
        end
    end

    assign init_no = init_no_reg;

    // test_mode_i bypasses synchronization
    // When test_mode_i is high, rst_no follows rst_ni directly (asynchronous)
    // But we need to be careful: the requirement says "bypasses synchronization for scan/test"
    // This means in test mode, the reset is not synchronized, it's direct
    // However, for CDC safety, we should still handle this carefully
    // The typical approach: in test mode, use the raw reset directly
    // But this creates an asynchronous reset path. For scan/test, this is acceptable
    // as test mode is a special mode where timing constraints are relaxed

    // Let's restructure: use a mux to select between synchronized and direct reset
    // But we need to ensure that when switching between modes, there's no glitch
    // A common approach: in test mode, rst_no = rst_ni (direct)
    // In normal mode, rst_no = sync_rst_n[2]

    // However, the output rst_no is already assigned. Let's fix this.
    // We need to make rst_no conditional on test_mode_i

    // Let's redo the design properly

endmodule

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

    // Synchronized reset output (normal mode)
    logic rst_no_sync;
    assign rst_no_sync = sync_rst_n[2];

    // In test mode, bypass synchronization: use rst_ni directly
    // In normal mode, use synchronized reset
    assign rst_no = test_mode_i ? rst_ni : rst_no_sync;

    // Initialization qualifier: short pulse after reset release
    // Count cycles after reset is deasserted
    logic [1:0] init_cnt;

    always_ff @(posedge clk_i) begin
        if (!rst_no) begin
            init_cnt <= 2'd0;
        end else begin
            if (init_cnt != 2'd3) begin
                init_cnt <= init_cnt + 2'd1;
            end
        end
    end

    // init_no is active-low: low during initialization period after reset release
    // High after initialization is complete
    logic init_no_reg;

    always_ff @(posedge clk_i) begin
        if (!rst_no) begin
            init_no_reg <= 1'b0;
        end else begin
            if (init_cnt == 2'd3) begin
                init_no_reg <= 1'b1;
            end
        end
    end

    assign init_no = init_no_reg;

endmodule
