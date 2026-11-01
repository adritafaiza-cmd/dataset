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

    // Initialization qualifier: active for a few cycles after reset release
    // Use a counter that starts when reset is released
    logic [3:0] init_cnt;
    logic init_done;

    always_ff @(posedge clk_i) begin
        if (!rst_no) begin
            init_cnt  <= 4'd0;
            init_done <= 1'b0;
        end else begin
            if (!init_done) begin
                if (init_cnt == 4'd15) begin
                    init_done <= 1'b1;
                end else begin
                    init_cnt <= init_cnt + 4'd1;
                end
            end
        end
    end

    // init_no is high when initialization is complete
    assign init_no = init_done;

    // In test mode, bypass synchronization
    assign rst_no = test_mode_i ? rst_ni : sync_rst_n[2];

endmodule
