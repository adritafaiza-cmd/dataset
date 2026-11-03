module pulse_sync #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output pulseB_o,
    output busy_o
);

    reg [STAGES-1:0] wr_ptr_gray_sync;
    reg [STAGES-1:0] rd_ptr_gray_sync;
    reg [STAGES-1:0] wr_ptr_gray;
    reg [STAGES-1:0] rd_ptr_gray;
    reg [STAGES-1:0] wr_ptr;
    reg [STAGES-1:0] rd_ptr;
    reg [1<<STAGES-1:0] fifo_mem;
    reg fifo_full;
    reg fifo_empty;

    // Gray code conversion
    function [STAGES-1:0] gray_code;
        input [STAGES-1:0] binary;
        gray_code = binary ^ (binary >> 1);
    endfunction

    // Clock domain A (clk_a)
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else begin
            if (!fifo_full && pulseA_i) begin
                fifo_mem[wr_ptr] <= 1;
                wr_ptr <= wr_ptr + 1;
                wr_ptr_gray <= gray_code(wr_ptr + 1);
            end
        end
    end

    // Sync wr_ptr_gray to clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Clock domain B (clk_b)
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else begin
            if (!fifo_empty && pulseB_o) begin
                fifo_mem[rd_ptr] <= 0;
                rd_ptr <= rd_ptr + 1;
                rd_ptr_gray <= gray_code(rd_ptr + 1);
            end
        end
    end

    // Sync rd_ptr_gray to clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // Full and empty detection
    assign fifo_full = (wr_ptr_gray_sync == (rd_ptr_gray + 1));
    assign fifo_empty = (wr_ptr_gray == rd_ptr_gray_sync);

    // Output assignments
    assign pulseB_o = fifo_mem[rd_ptr];
    assign busy_o = fifo_full;

endmodule
