module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic rst_sync;
    logic init_qualifier;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync <= 1'b1;
            init_qualifier <= 1'b0;
        end else begin
            if (!test_mode_i) begin
                rst_sync <= rst_ni;
            end
            if (!rst_sync) begin
                init_qualifier <= 1'b1;
            end else if (init_qualifier) begin
                init_qualifier <= 1'b0;
            end
        end
    end

    assign rst_no = test_mode_i ? rst_ni : rst_sync;
    assign init_no = init_qualifier;

endmodule
