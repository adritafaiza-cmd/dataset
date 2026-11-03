module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic sync_rst;
    logic init_qualifier;
    logic sync_rst_reg1;
    logic sync_rst_reg2;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_rst_reg1 <= 1'b1;
            sync_rst_reg2 <= 1'b1;
        end else begin
            sync_rst_reg1 <= test_mode_i ? rst_ni : sync_rst_reg1;
            sync_rst_reg2 <= test_mode_i ? rst_ni : sync_rst_reg1;
        end
    end

    assign sync_rst = test_mode_i ? rst_ni : sync_rst_reg2;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_no <= 1'b0;
            init_no <= 1'b1;
        end else begin
            rst_no <= sync_rst;
            init_no <= ~sync_rst | init_qualifier;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_qualifier <= 1'b1;
        end else begin
            init_qualifier <= 1'b0;
        end
    end

endmodule
