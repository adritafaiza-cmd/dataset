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
    logic [STAGES-1:0] sync_reg;
    logic [STAGES-1:0] sync_reg_next;
    
    // Edge detection registers
    logic [STAGES-1:0] prev_sync;
    logic [STAGES-1:0] prev_sync_next;

    // Synchronize the input serial bit
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_reg <= '{default: 1'b0};
        else
            sync_reg <= sync_reg_next;
    end

    // Synchronize the previous state for edge detection
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            prev_sync <= '{default: 1'b0};
        else
            prev_sync <= prev_sync_next;
    end

    // Combinational logic for next state
    always_comb begin
        sync_reg_next = sync_reg;
        prev_sync_next = prev_sync;

        if (en_i) begin
            sync_reg_next[STAGES-1] = serial_i;
            prev_sync_next[STAGES-1] = sync_reg[STAGES-1];
        end else begin
            // When disabled, hold current state to prevent glitches
            sync_reg_next = sync_reg;
            prev_sync_next = prev_sync;
        end
    end

    // Edge detection logic
    assign r_edge_o = (sync_reg[STAGES-1] && !prev_sync[STAGES-1]) ? 1'b1 : 1'b0;
    assign f_edge_o = (!sync_reg[STAGES-1] && prev_sync[STAGES-1]) ? 1'b1 : 1'b0;

    // Output the synchronized bit
    assign serial_o = sync_reg[STAGES-1];

endmodule<|im_end|>
