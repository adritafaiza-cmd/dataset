module sync_wedge #(
    parameter STAGES = 2
)(
    input  wire clk_i,
    input  wire rst_ni,
    input  wire en_i,
    input  wire serial_i,
    output reg  r_edge_o,
    output reg  f_edge_o,
    output reg  serial_o
);

    // Synchronized data register
    reg [STAGES-1:0] sync_data;

    // Edge detection registers
    reg [STAGES-1:0] prev_data;
    reg [STAGES-1:0] curr_data;

    // Synchronize serial_i to clk_i
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_data <= '{default: 1'b0};
            prev_data <= '{default: 1'b0};
            curr_data <= '{default: 1'b0};
            r_edge_o   <= 1'b0;
            f_edge_o   <= 1'b0;
            serial_o   <= 1'b0;
        end else begin
            sync_data <= serial_i;
            serial_o  <= sync_data[STAGES-1];
        end
    end

    // Detect rising edge (0 -> 1)
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_o <= 1'b0;
        end else begin
            // Check if previous stage was 0 and current stage is 1
            if (sync_data[STAGES-1] && !sync_data[STAGES-2]) begin
                r_edge_o <= 1'b1;
            end else begin
                r_edge_o <= 1'b0;
            end
        end
    end

    // Detect falling edge (1 -> 0)
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            f_edge_o <= 1'b0;
        end else begin
            // Check if previous stage was 1 and current stage is 0
            if (!sync_data[STAGES-1] && sync_data[STAGES-2]) begin
                f_edge_o <= 1'b1;
            end else begin
                f_edge_o <= 1'b0;
            end
        end
    end

endmodule<|im_end|>
