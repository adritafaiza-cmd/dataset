module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic [1:0] rst_sync_ff;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            rst_sync_ff <= 2'b00;
        else
            rst_sync_ff <= {rst_sync_ff[0], 1'b1};
    end

    assign rst_no  = test_mode_i ? 1'b1 : rst_sync_ff[1];
    assign init_no = test_mode_i ? 1'b1 : rst_sync_ff[1];

endmodule
