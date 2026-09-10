module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

logic rst_sync;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        rst_sync <= 1'b0;
    end else if (test_mode_i) begin
        rst_sync <= 1'b1;
    end else begin
        rst_sync <= rst_ni;
    end
end

assign rst_no = ~rst_sync;

logic [1:0] init_cnt;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        init_cnt <= 2'b00;
    end else if (rst_sync && (init_cnt == 2'b00)) begin
        init_cnt <= init_cnt + 1'b1;
    end else if (init_cnt == 2'b11) begin
        init_cnt <= 2'b11;
    end else begin
        init_cnt <= init_cnt + 1'b1;
    end
end

assign init_no = (init_cnt == 2'b01);

endmodule
