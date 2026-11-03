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

    // Internal signals
    wire synced_serial;
    reg  d1;
    reg  d2;

    // Instantiate the sync_cell module for synchronization
    sync_cell #(.STAGES(STAGES)) sync_cell_inst (
        .clk(clk_i),
        .rst_ni(rst_ni),
        .data_in(serial_i),
        .data_out(synced_serial)
    );

    // Assign the synchronized signal to the output
    assign serial_o = synced_serial;

    // Edge detection logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            d1 <= 1'b0;
            d2 <= 1'b0;
        end else begin
            d1 <= synced_serial;
            d2 <= d1;
        end
    end

    // Detect rising and falling edges
    assign r_edge_o = en_i & (d1 & ~d2);
    assign f_edge_o = en_i & (~d1 & d2);

endmodule

// Single-stage synchronizer cell
module sync_cell #(
    parameter STAGES = 2
)(
    input  clk,
    input  rst_ni,
    input  data_in,
    output data_out
);

    reg [STAGES-1:0] sync_reg;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {STAGES{1'b0}};
        end else begin
            sync_reg[0] <= data_in;
            if (STAGES > 1) begin
                sync_reg[1:STAGES-1] <= sync_reg[0:STAGES-2];
            end
        end
    end

    assign data_out = sync_reg[STAGES-1];

endmodule
