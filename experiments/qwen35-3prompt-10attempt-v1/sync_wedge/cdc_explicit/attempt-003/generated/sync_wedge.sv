module sync_wedge #(
    parameter STAGES = 2
)(
    input  wire clk_i,
    input  wire rst_ni,
    input  wire en_i,
    input  wire serial_i,
    output wire r_edge_o,
    output wire f_edge_o,
    output wire serial_o
);

    // Internal registers for synchronization
    reg [STAGES-1:0] sync_reg;
    reg [STAGES-1:0] sync_reg_prev;
    reg sync_r_edge;
    reg sync_f_edge;

    // Synchronize the input serial bit
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_reg <= {STAGES{1'b0}};
        else
            sync_reg <= {sync_reg[STAGES-2:0], serial_i};
    end

    // Synchronize the enable signal
    reg en_sync;
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            en_sync <= 1'b0;
        else
            en_sync <= en_i;
    end

    // Detect edges on the synchronized data
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg_prev <= {STAGES{1'b0}};
            sync_r_edge <= 1'b0;
            sync_f_edge <= 1'b0;
        end else begin
            sync_reg_prev <= sync_reg;
            // Rising edge detection
            sync_r_edge <= (sync_reg[STAGES-1] == 1'b1) && (sync_reg[STAGES-2] == 1'b0);
            // Falling edge detection
            sync_f_edge <= (sync_reg[STAGES-1] == 1'b0) && (sync_reg[STAGES-2] == 1'b1);
        end
    end

    // Generate single-cycle pulses for edge detection
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_o <= 1'b0;
            f_edge_o <= 1'b0;
            serial_o <= 1'b0;
        end else begin
            r_edge_o <= sync_r_edge && en_sync;
            f_edge_o <= sync_f_edge && en_sync;
            serial_o <= sync_reg[STAGES-1];
        end
    end

endmodule<|im_end|>
