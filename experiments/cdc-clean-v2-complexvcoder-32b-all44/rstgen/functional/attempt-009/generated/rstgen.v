module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic sync_rst_n;
    logic rst_no_reg;
    logic init_no_reg;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_rst_n  <= 1'b0;
            rst_no_reg  <= 1'b0;
            init_no_reg <= 1'b0;
        end else begin
            if (test_mode_i) begin
                sync_rst_n <= rst_ni;
            end else begin
                sync_rst_n <= sync_rst_n ? rst_ni : 1'b0; // Synchronize rst_ni to clk_i
            end
            rst_no_reg  <= sync_rst_n;
            init_no_reg <= !rst_no_reg & sync_rst_n; // Assert init_no for one cycle after reset release
        end
    end

    assign rst_no  = rst_no_reg;
    assign init_no = init_no_reg;

endmodule
