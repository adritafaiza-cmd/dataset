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

    // Declare synchronization arrays
    reg [DWIDTH-1:0] data_sync_chain [0:STAGES-1];
    reg dready_sync_chain [0:STAGES-1];

    // First stage
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            data_sync_chain[0] <= 0;
            dready_sync_chain[0] <= 0;
        end else begin
            if (dready_i) begin
                data_sync_chain[0] <= din;
                dready_sync_chain[0] <= 1;
            end else begin
                dready_sync_chain[0] <= 0;
            end
        end
    end

    // Generate the rest of the stages
    generate
        genvar i;
        for (i = 1; i < STAGES; i = i + 1) begin : gen_sync
            always @(posedge clk or negedge rstn) begin
                if (!rstn) begin
                    data_sync_chain[i] <= 0;
                    dready_sync_chain[i] <= 0;
                end else begin
                    data_sync_chain[i] <= data_sync_chain[i-1];
                    dready_sync_chain[i] <= dready_sync_chain[i-1];
                end
            end
        end
    endgenerate

    // Assign outputs from the last stage
    always @(*) begin
        dout = data_sync_chain[STAGES-1];
        dready_o = dready_sync_chain[STAGES-1];
    end

endmodule
