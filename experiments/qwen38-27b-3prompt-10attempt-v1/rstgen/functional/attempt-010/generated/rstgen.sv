module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic [2:0] rst_sync;
    logic init_cnt_en;
    logic [1:0] init_cnt;

    // Synchronize reset
    always_ff @(posedge clk_i) begin
        if (test_mode_i) begin
            rst_sync <= 3'b111;
        end else begin
            rst_sync <= {rst_sync[1:0], rst_ni};
        end
    end

    assign rst_no = rst_sync[2];

    // Init counter: counts for a few cycles after reset release
    always_ff @(posedge clk_i) begin
        if (!rst_no) begin
            init_cnt <= 2'b00;
        end else if (init_cnt != 2'b11) begin
            init_cnt <= init_cnt + 1'b1;
        end
    end

    assign init_no = (init_cnt == 2'b11);

endmodule
