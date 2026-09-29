module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    reg q1, q2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            q1 <= 1'b0;
            q2 <= 1'b0;
        end else begin
            q1 <= 1'b1;
            q2 <= q1;
        end
    end

    assign rst_no = test_mode_i ? rst_ni : q2;
    assign init_no = rst_no;

endmodule
