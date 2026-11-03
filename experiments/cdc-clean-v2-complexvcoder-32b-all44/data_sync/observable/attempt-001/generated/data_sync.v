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
    wire [DWIDTH-1:0] din_sync_0;
    wire              dready_i_sync_0;
    wire [DWIDTH-1:0] din_sync_1;
    wire              dready_i_sync_1;

    // Instantiate the first synchronization stage
    sync_stage #(.DWIDTH(DWIDTH)) sync_stage_0 (
        .clk       (clk),
        .rstn      (rstn),
        .din       (din),
        .dready_i  (dready_i),
        .dout      (din_sync_0),
        .dready_o  (dready_i_sync_0)
    );

    // Instantiate the second synchronization stage
    sync_stage #(.DWIDTH(DWIDTH)) sync_stage_1 (
        .clk       (clk),
        .rstn      (rstn),
        .din       (din_sync_0),
        .dready_i  (dready_i_sync_0),
        .dout      (din_sync_1),
        .dready_o  (dready_i_sync_1)
    );

    // Final assignment of synchronized output
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout     <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            dout     <= din_sync_1;
            dready_o <= dready_i_sync_1;
        end
    end

endmodule

// Single stage of synchronization
module sync_stage #(
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    input                  dready_i,
    output reg [DWIDTH-1:0] dout,
    output reg             dready_o
);

    // Synchronize input data and ready signal to the local clock domain
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout     <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            dout     <= din;
            dready_o <= dready_i;
        end
    end

endmodule
