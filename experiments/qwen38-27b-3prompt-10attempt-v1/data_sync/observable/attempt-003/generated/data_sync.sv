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

    localparam SYNC_STAGES = (STAGES < 2) ? 2 : STAGES;

    reg [SYNC_STAGES-1:0] din_sync;
    reg [SYNC_STAGES-1:0] dready_i_sync;

    integer i;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            din_sync <= {SYNC_STAGES{1'b0}};
            dready_i_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            din_sync <= {din_sync[SYNC_STAGES-2:0], din};
            dready_i_sync <= {dready_i_sync[SYNC_STAGES-2:0], dready_i};
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            dout <= din_sync[SYNC_STAGES-1];
            dready_o <= dready_i_sync[SYNC_STAGES-1];
        end
    end

endmodule
