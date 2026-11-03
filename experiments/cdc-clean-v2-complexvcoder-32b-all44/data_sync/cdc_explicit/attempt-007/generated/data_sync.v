module data_sync #(
    parameter STAGES = 2,
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    input                  dready_i,
    output reg [DWIDTH-1:0] dout,
    output reg             dready_o
);

    // Internal signals for synchronization stages
    wire [DWIDTH-1:0] sync_stages [STAGES-1:0];

    // Instantiate the first sync stage
    sync_stage #(.DWIDTH(DWIDTH)) sync_stage_inst_0 (
        .clk    (clk),
        .rstn   (rstn),
        .din    (din),
        .dout   (sync_stages[0])
    );

    // Generate the remaining sync stages
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_sync_stages
            sync_stage #(.DWIDTH(DWIDTH)) sync_stage_inst_i (
                .clk    (clk),
                .rstn   (rstn),
                .din    (sync_stages[i-1]),
                .dout   (sync_stages[i])
            );
        end
    endgenerate

    // Assign the final synchronized output
    assign dout = sync_stages[STAGES-1];

    // Synchronize dready_i to dready_o
    reg dready_i_sync;
    reg dready_i_sync2;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dready_i_sync  <= 1'b0;
            dready_i_sync2 <= 1'b0;
            dready_o       <= 1'b0;
        end else begin
            dready_i_sync  <= dready_i;
            dready_i_sync2 <= dready_i_sync;
            dready_o       <= dready_i_sync2;
        end
    end

endmodule

module sync_stage #(
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    output reg [DWIDTH-1:0] dout
);

    // Register to hold synchronized data
    reg [DWIDTH-1:0] reg_din;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            reg_din <= {DWIDTH{1'b0}};
            dout    <= {DWIDTH{1'b0}};
        end else begin
            reg_din <= din;
            dout    <= reg_din;
        end
    end

endmodule
