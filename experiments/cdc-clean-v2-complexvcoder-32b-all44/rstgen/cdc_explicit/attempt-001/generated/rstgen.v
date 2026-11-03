module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic rst_sync_1;
    logic rst_sync_2;
    logic [1:0] init_cnt;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_1 <= 1'b1;
            rst_sync_2 <= 1'b1;
        end else begin
            rst_sync_1 <= test_mode_i ? rst_ni : rst_sync_1;
            rst_sync_2 <= test_mode_i ? rst_ni : rst_sync_1;
        end
    end

    always_ff @(posedge clk_i or negedge rst_sync_2) begin
        if (!rst_sync_2) begin
            init_cnt <= 2'b00;
        end else begin
            init_cnt <= init_cnt + 1;
        end
    end

    assign rst_no = ~rst_sync_2;
    assign init_no = ~(init_cnt == 2'b11);

endmodule
