module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic rst_sync_1;
    logic rst_sync_2;
    logic rst_sync;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_1 <= 1'b1;
            rst_sync_2 <= 1'b1;
        end else begin
            rst_sync_1 <= 1'b0;
            rst_sync_2 <= rst_sync_1;
        end
    end

    assign rst_sync = test_mode_i ? rst_ni : rst_sync_2;

    always_ff @(posedge clk_i or negedge rst_sync) begin
        if (!rst_sync) begin
            rst_no  <= 1'b1;
            init_no <= 1'b1;
        end else begin
            rst_no  <= 1'b0;
            init_no <= 1'b0;
        end
    end

    always_ff @(posedge clk_i) begin
        if (!rst_no) begin
            init_no <= 1'b1;
        end else begin
            init_no <= 1'b0;
        end
    end

endmodule
