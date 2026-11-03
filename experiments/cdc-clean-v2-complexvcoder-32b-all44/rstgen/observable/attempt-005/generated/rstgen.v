module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic sync_rst;
    logic sync_init;

    sync_reset sync_reset_inst (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .rst_no   (sync_rst),
        .init_no  (sync_init)
    );

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_no   <= 1'b0;
            init_no  <= 1'b1;
        end else if (test_mode_i) begin
            rst_no   <= rst_ni;
            init_no  <= 1'b0;
        end else begin
            rst_no   <= sync_rst;
            init_no  <= sync_init;
        end
    end

endmodule

module sync_reset (
    input  logic clk_i,
    input  logic rst_ni,
    output logic rst_no,
    output logic init_no
);

    logic rst_sync_1;
    logic rst_sync_2;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync_1 <= 1'b0;
            rst_sync_2 <= 1'b0;
        end else begin
            rst_sync_1 <= 1'b1;
            rst_sync_2 <= rst_sync_1;
        end
    end

    assign rst_no   = rst_sync_2;
    assign init_no  = ~rst_sync_2;

endmodule
