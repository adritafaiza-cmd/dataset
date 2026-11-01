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

    // Ensure STAGES is at least 2 for safe multi-bit synchronization
    localparam SAFE_STAGES = (STAGES < 2) ? 2 : STAGES;

    // Synchronizer flip-flops for the handshake signal
    reg [SAFE_STAGES-1:0] sync_ff;

    // Latch to capture din when dready_i is high
    reg [DWIDTH-1:0] din_latched;
    reg               din_valid;

    // Synchronizer for the valid signal
    reg [SAFE_STAGES-1:0] valid_sync_ff;

    // Output registers
    reg [DWIDTH-1:0] dout_reg;
    reg               dready_o_reg;

    // Synchronize dready_i
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            sync_ff <= {SAFE_STAGES{1'b0}};
        else
            sync_ff <= {sync_ff[SAFE_STAGES-2:0], dready_i};
    end

    // Synchronize the valid signal (indicates new data is available)
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            valid_sync_ff <= {SAFE_STAGES{1'b0}};
        else
            valid_sync_ff <= {valid_sync_ff[SAFE_STAGES-2:0], din_valid};
    end

    // Latch din when dready_i is high
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            din_latched <= {DWIDTH{1'b0}};
            din_valid   <= 1'b0;
        end else begin
            if (dready_i) begin
                din_latched <= din;
                din_valid   <= 1'b1;
            end else if (valid_sync_ff[SAFE_STAGES-1]) begin
                // Data has been consumed, clear valid
                din_valid <= 1'b0;
            end
        end
    end

    // Output stage: present dout and pulse dready_o when synchronized valid is high
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout_reg     <= {DWIDTH{1'b0}};
            dready_o_reg <= 1'b0;
        end else begin
            if (valid_sync_ff[SAFE_STAGES-1]) begin
                dout_reg     <= din_latched;
                dready_o_reg <= 1'b1;
            end else begin
                dready_o_reg <= 1'b0;
            end
        end
    end

    assign dout     = dout_reg;
    assign dready_o = dready_o_reg;

endmodule
