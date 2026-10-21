```verilog
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

    // Internal registers for the FIFO stages
    // We use a shift-register style pipeline to ensure no bit tearing
    // and to align data with the destination clock domain.
    reg [DWIDTH-1:0] stage_reg [0:STAGES-1];
    reg               stage_valid [0:STAGES-1];
    
    // State for the handshake logic
    reg               ready_pulse;
    reg               data_valid;

    // Synchronous reset logic for all internal registers
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout <= 0;
            dready_o <= 0;
            for (integer i = 0; i < STAGES; i = i + 1) begin
                stage_reg[i] <= 0;
                stage_valid[i] <= 0;
            end
            ready_pulse <= 0;
            data_valid <= 0;
        end
        else begin
            // Shift data through the pipeline
            // Stage 0 receives din when dready_i is asserted
            if (dready_i) begin
                stage_reg[0] <= din;
                stage_valid[0] <= 1'b1;
            end
            else begin
                stage_reg[0] <= stage_reg[0];
                stage_valid[0] <= stage_valid[0];
            end

            // Shift valid signals and data through subsequent stages
            for (integer i = 1; i < STAGES; i = i + 1) begin
                if (stage_valid[i-1]) begin
                    stage_reg[i] <= stage_reg[i-1];
                    stage_valid[i] <= 1'b1;
                end
                else begin
                    stage_reg[i] <= stage_reg[i];
                    stage_valid[i] <= stage_valid[i];
                end
            end

            // The last stage provides the output data
            dout <= stage_reg[STAGES-1];
            
            // Determine if data is valid at the output
            data_valid = stage_valid[STAGES-1];
        end
    end

    // Handshake logic
    // dready_o is asserted when data is valid AND the source is ready
    // We use a single-cycle pulse to indicate data availability
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dready_o <= 0;
        end
        else begin
            // Assert dready_o if we have valid data and the source is ready
            // This ensures the source knows it can write the next value
            if (data_valid && dready_i) begin
                dready_o <= 1'b1;
            end
            else begin
                dready_o <= 0;
            end
        end
    end

endmodule
```<|im_end|>
