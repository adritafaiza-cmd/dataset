module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic rst_sync1;
    logic rst_sync2;
    logic init_qualifier;
    logic rst_no_reg;
    logic init_no_reg;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync1 <= 1'b1;
            rst_sync2 <= 1'b1;
        end else begin
            rst_sync1 <= 1'b0;
            rst_sync2 <= rst_sync1;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_no_reg <= 1'b1;
        end else if (test_mode_i) begin
            rst_no_reg <= rst_ni;
        end else begin
            rst_no_reg <= rst_sync2;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_no_reg <= 1'b1;
        end else if (rst_no_reg) begin
            init_no_reg <= 1'b0;
        end else begin
            init_no_reg <= 1'b1;
        end
    end

    assign rst_no = rst_no_reg;
    assign init_no = init_no_reg & ~rst_no_reg;

endmodule
