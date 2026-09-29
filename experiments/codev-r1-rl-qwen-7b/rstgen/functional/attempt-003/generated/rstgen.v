module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    reg sync_0, sync_1;
    reg rst_no_prev;

    // Synchronization flip-flops
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= 1'b1;
            sync_1 <= sync_0;
        end
    end

    // Assign synchronized reset (active low)
    assign rst_no = test_mode_i ? rst_ni : (sync_0 & sync_1);

    // Edge detection for init_no
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_no_prev <= 1'b0;
        end else begin
            rst_no_prev <= rst_no;
        end
    end

    assign init_no = (rst_no == 1'b1) && (rst_no_prev == 1'b0);

endmodule
