module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    logic rst_sync1;
    logic rst_sync2;
    logic [1:0] init_cnt;

    // Asynchronous reset for rst_sync1
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync1 <= 1'b0;
        end else begin
            rst_sync1 <= 1'b1;
        end
    end

    // Synchronous reset for rst_sync2
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_sync2 <= 1'b0;
        end else begin
            rst_sync2 <= rst_sync1;
        end
    end

    // Synchronous reset for rst_no
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rst_no <= 1'b0;
        end else begin
            rst_no <= rst_sync2;
        end
    end

    // Bypass synchronization in test mode
    assign rst_no = test_mode_i ? rst_ni : rst_no;

    // Initialization counter
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_cnt <= 2'b00;
        end else if (!rst_no) begin
            init_cnt <= 2'b00;
        end else begin
            if (init_cnt < 2'b11) begin
                init_cnt <= init_cnt + 1'b1;
            end
        end
    end

    // init_no logic
    assign init_no = rst_no ? 1'b0 : (init_cnt == 2'b11);

endmodule
