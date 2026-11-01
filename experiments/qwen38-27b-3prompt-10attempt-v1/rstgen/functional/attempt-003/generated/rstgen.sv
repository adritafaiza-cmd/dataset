module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic [1:0] sync_rst;
    logic init_cnt_en;
    logic [1:0] init_cnt;

    // Synchronize the asynchronous reset
    always_ff @(posedge clk_i) begin
        sync_rst[0] <= rst_ni;
        sync_rst[1] <= sync_rst[0];
    end

    // In test mode, bypass synchronization
    assign rst_no = test_mode_i ? rst_ni : sync_rst[1];

    // Initialization counter: counts for a few cycles after reset release
    // init_no is low during initialization, high after
    // Use a 2-bit counter to give a few cycles of initialization
    always_ff @(posedge clk_i) begin
        if (!rst_no) begin
            init_cnt <= 2'b00;
        end
        else begin
            if (init_cnt != 2'b11)
                init_cnt <= init_cnt + 1'b1;
        end
    end

    // init_no is high when initialization is complete
    assign init_no = (init_cnt == 2'b11);

endmodule
