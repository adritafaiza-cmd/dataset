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

    // Use a minimum of 2 stages for safe synchronization
    localparam SYNC_STAGES = (STAGES < 2) ? 2 : STAGES;

    // Synchronizer chain for the ready signal
    reg [SYNC_STAGES-1:0] ready_sync;

    // Latch the data when the synchronized ready indicates a new value
    reg [DWIDTH-1:0] data_latch;
    reg              data_valid;

    // Synchronize the ready signal
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            ready_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            ready_sync[0] <= dready_i;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                ready_sync[i] <= ready_sync[i-1];
            end
        end
    end

    // Detect rising edge of the synchronized ready signal
    wire ready_sync_rise = ready_sync[SYNC_STAGES-1] & ~ready_sync[SYNC_STAGES-2];

    // Latch data on rising edge of synchronized ready
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            data_latch <= {DWIDTH{1'b0}};
            data_valid <= 1'b0;
        end else begin
            if (ready_sync_rise) begin
                data_latch <= din;
                data_valid <= 1'b1;
            end
        end
    end

    // Output the latched data and pulse dready_o
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout     <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            if (data_valid) begin
                dout     <= data_latch;
                dready_o <= 1'b1;
                data_valid <= 1'b0;
            end else begin
                dready_o <= 1'b0;
            end
        end
    end

endmodule
