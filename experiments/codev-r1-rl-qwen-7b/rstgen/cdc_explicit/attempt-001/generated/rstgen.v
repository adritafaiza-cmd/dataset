module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    reg [1:0] rst_sync;
    reg init_reg;

    // Synchronizer process
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync <= 2'b00;
        end else begin
            rst_sync[0] <= 1'b1;
            rst_sync[1] <= rst_sync[0];
        end
    end

    // Output logic with test_mode_i
    assign rst_no = test_mode_i ? rst_ni : rst_sync[1];

    // init_no generation
    always @(posedge clk_i or negedge rst_no) begin
        if (!rst_no) begin
            init_reg <= 1'b0;
        end else begin
            init_reg <= 1'b1;
        end
    end

    assign init_no = init_reg;

endmodule
