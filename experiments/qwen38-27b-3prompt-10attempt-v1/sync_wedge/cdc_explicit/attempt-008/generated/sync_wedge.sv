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

    localparam SYNC_DEPTH = (STAGES < 2) ? 2 : STAGES;

    reg [SYNC_DEPTH-1:0] sync_reg;
    reg                  sync_prev;
    reg                  r_edge_int;
    reg                  f_edge_int;

    // Synchronize the asynchronous input
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {SYNC_DEPTH{1'b0}};
        end else begin
            sync_reg <= {sync_reg[SYNC_DEPTH-2:0], serial_i};
        end
    end

    assign serial_o = sync_reg[SYNC_DEPTH-1];

    // Track previous synchronized value for edge detection
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_prev <= 1'b0;
        end else begin
            sync_prev <= serial_o;
        end
    end

    // Edge detection
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_int <= 1'b0;
            f_edge_int <= 1'b0;
        end else begin
            r_edge_int <= (serial_o == 1'b1) && (sync_prev == 1'b0);
            f_edge_int <= (serial_o == 1'b0) && (sync_prev == 1'b1);
        end
    end

    // Gated outputs
    assign r_edge_o = r_edge_int & en_i;
    assign f_edge_o = f_edge_int & en_i;

endmodule
