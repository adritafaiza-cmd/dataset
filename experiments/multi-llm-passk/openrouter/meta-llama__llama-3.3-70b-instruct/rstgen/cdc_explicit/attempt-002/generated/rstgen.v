module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

logic rst_sync_n;
logic rst_sync_n_q;
logic init_sync_n;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        rst_sync_n <= 1'b0;
        rst_sync_n_q <= 1'b0;
        init_sync_n <= 1'b0;
    end else begin
        if (test_mode_i) begin
            rst_sync_n <= 1'b1;
            rst_sync_n_q <= 1'b1;
        end else begin
            rst_sync_n_q <= rst_sync_n;
            if (rst_sync_n) begin
                init_sync_n <= 1'b1;
            end else begin
                init_sync_n <= 1'b0;
            end
            if (rst_ni) begin
                rst_sync_n <= 1'b1;
            end
        end
    end
end

assign rst_no = ~rst_sync_n_q;
assign init_no = init_sync_n;

endmodule
