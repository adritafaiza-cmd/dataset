module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    reg q1, q2;
    reg rst_no_prev;

    // Synchronization process
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            q1 <= 1'b0;
            q2 <= 1'b0;
        end else begin
            q1 <= 1'b1;
            q2 <= q1;
        end
    end

    // Test mode bypass and synchronized reset
    assign rst_no = test_mode_i ? rst_ni : ~(&{q1, q2});

    // Edge detection for rst_no deassertion
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_no_prev <= 1'b0;
        end else begin
            rst_no_prev <= rst_no;
        end
    end

    // Generate init_no pulse after reset release
    assign init_no = (rst_no == 1) && (rst_no_prev == 0);

endmodule
