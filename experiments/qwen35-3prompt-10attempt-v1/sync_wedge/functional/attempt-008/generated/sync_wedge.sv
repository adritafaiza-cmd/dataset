module sync_wedge #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output reg r_edge_o,
    output reg f_edge_o,
    output reg serial_o
);

    // Synchronous serial data with edge detection
    // STAGES = 2 provides robust crossing for typical clock domains
    localparam INT_STAGES = STAGES;
    
    reg [INT_STAGES-1:0] sync_reg;
    reg sync_d;
    reg sync_q;
    
    // Internal edge flags
    reg r_edge_int;
    reg f_edge_int;
    
    // Synchronize the input serial bit
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_d <= 1'b0;
        else
            sync_d <= serial_i;
    end
    
    // Shift register chain for synchronization
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_reg <= {INT_STAGES{1'b0}};
        else
            sync_reg <= {sync_reg[INT_STAGES-2:0], sync_d};
    end
    
    // Detect edges on the synchronized data
    // Rising edge: current is 1, previous was 0
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            r_edge_int <= 1'b0;
        else
            r_edge_int <= (sync_reg[INT_STAGES-1] == 1'b0) && (sync_reg[INT_STAGES-2] == 1'b1);
    end
    
    // Falling edge: current is 0, previous was 1
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            f_edge_int <= 1'b0;
        else
            f_edge_int <= (sync_reg[INT_STAGES-1] == 1'b1) && (sync_reg[INT_STAGES-2] == 1'b0);
    end
    
    // Output single-cycle pulses for edges
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_o <= 1'b0;
            f_edge_o <= 1'b0;
            serial_o <= 1'b0;
        end
        else begin
            r_edge_o <= r_edge_int;
            f_edge_o <= f_edge_int;
            serial_o <= sync_reg[INT_STAGES-1];
        end
    end

endmodule<|im_end|>
