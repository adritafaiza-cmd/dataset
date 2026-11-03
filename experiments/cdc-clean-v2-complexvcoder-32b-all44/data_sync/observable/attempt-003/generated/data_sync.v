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

    wire [DWIDTH-1:0] synced_din_0;
    wire [DWIDTH-1:0] synced_din_1;

    sync_stage #(.DWIDTH(DWIDTH)) sync_stage_inst_0 (
        .clk(clk),
        .rstn(rstn),
        .din(din),
        .dout(synced_din_0)
    );

    sync_stage #(.DWIDTH(DWIDTH)) sync_stage_inst_1 (
        .clk(clk),
        .rstn(rstn),
        .din(synced_din_0),
        .dout(synced_din_1)
    );

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            dout <= synced_din_1;
            dready_o <= dready_i;
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

    reg [DWIDTH-1:0] reg_din;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            reg_din <= {DWIDTH{1'b0}};
            dout <= {DWIDTH{1'b0}};
        end else begin
            reg_din <= din;
            dout <= reg_din;
        end
    end

endmodule
