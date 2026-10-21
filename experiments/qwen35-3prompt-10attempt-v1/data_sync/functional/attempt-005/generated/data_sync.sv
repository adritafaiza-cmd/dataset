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

    // Internal stage counter
    localparam STAGE_COUNT = STAGES;
    
    // Array of registers to hold the data at each stage
    reg [DWIDTH-1:0] stage_data [0:STAGE_COUNT-1];
    
    // Array of flags to track if data is valid at each stage
    reg [STAGE_COUNT-1:0] stage_valid;

    // Counter to track the number of valid stages (FIFO depth)
    reg [STAGE_COUNT-1:0] stage_count;

    // Shift register for the valid flags
    reg [STAGE_COUNT-1:0] shift_valid;

    // Logic to handle the handshake and data movement
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout <= 0;
            dready_o <= 0;
            stage_count <= 0;
            stage_valid <= 0;
            shift_valid <= 0;
        end else begin
            // Reset all stage valid flags on reset
            if (stage_count == 0) begin
                stage_valid <= 0;
                shift_valid <= 0;
            end else begin
                // Shift the valid flags down the pipeline
                shift_valid <= stage_valid;
                
                // Update the valid flag for the current stage based on the previous stage's valid flag
                // and the incoming data ready signal
                stage_valid[0] <= dready_i;
                for (integer i = 1; i < STAGE_COUNT; i = i + 1) begin
                    stage_valid[i] <= shift_valid[i-1];
                end
                
                // Update the stage count
                stage_count <= stage_valid[0] ? stage_count + 1 : stage_count - 1;
            end
            
            // Update the output data
            // The output data is the data from the last stage if it is valid
            if (stage_valid[STAGE_COUNT-1]) begin
                dout <= stage_data[STAGE_COUNT-1];
            end else begin
                dout <= 0;
            end
            
            // Update the ready output
            // The output is ready if the last stage has valid data
            dready_o <= stage_valid[STAGE_COUNT-1];
            
            // Update the data in the pipeline
            // Data moves from stage i to stage i+1 if stage i+1 is valid
            for (integer i = STAGE_COUNT-1; i >= 0; i = i - 1) begin
                if (stage_valid[i+1]) begin
                    stage_data[i+1] <= stage_data[i];
                end
            end
        end
    end

endmodule
```<|im_end|>
