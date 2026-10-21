module sync_wedge #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output r_edge_o,
    output f_edge_o,
    output serial_o
);

    // Internal registers for synchronization
    reg [STAGES-1:0] sync_reg;
    reg [STAGES-1:0] prev_reg;

    // Synchronization logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_reg <= {STAGES{1'b0}};
        else
            sync_reg <= {sync_reg[STAGES-2:0], serial_i};
    end

    // Edge detection logic on synchronized data
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            prev_reg <= {STAGES{1'b0}};
            r_edge_o  <= 1'b0;
            f_edge_o  <= 1'b0;
            serial_o  <= 1'b0;
        end
        else begin
            // Update previous stage for edge comparison
            prev_reg <= sync_reg;
            
            // Detect rising edge (0 -> 1)
            r_edge_o <= (sync_reg[STAGES-1] == 1'b0) && (sync_reg[STAGES-2] == 1'b1);
            
            // Detect falling edge (1 -> 0)
            f_edge_o <= (sync_reg[STAGES-1] == 1'b1) && (sync_reg[STAGES-2] == 1'b0);
            
            // Output synchronized bit
            serial_o <= sync_reg[STAGES-1];
        end
    end

endmodule<|im_end|>
