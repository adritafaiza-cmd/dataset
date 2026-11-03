module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic rst_sync1;
    logic rst_sync2;
    logic init_sync;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync1 <= 1'b1;
            rst_sync2 <= 1'b1;
        end else begin
            rst_sync1 <= rst_ni;
            rst_sync2 <= rst_sync1;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_sync <= 1'b1;
        end else begin
            init_sync <= rst_sync2;
        end
    end

    always_comb begin
        if (test_mode_i) begin
            rst_no = rst_ni;
        end else begin
            rst_no = rst_sync2;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_no <= 1'b1;
        end else begin
            init_no <= !rst_sync2 & init_sync;
        end
    end

endmodule
