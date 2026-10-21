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

    // Synchronous FIFO/Buffer implementation using dual-port registers
    // Stage 1: Capture incoming data when dready_i is asserted
    // Stage 2+: Shift data through pipeline to ensure clock domain stability
    // Output stage: Present data and pulse dready_o on the next clock edge

    reg [DWIDTH-1:0] stage_data [STAGES-1:0];
    reg [STAGES-1:0] valid;
    reg [STAGES-1:0] ready;

    // Reset logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout <= 0;
            dready_o <= 0;
            valid <= 0;
            ready <= 0;
        end else begin
            // Shift valid/ready signals through the pipeline
            for (integer i = STAGES-1; i > 0; i = i - 1) begin
                valid[i] <= valid[i-1];
                ready[i] <= ready[i-1];
            end
            // Last stage ready is driven by dready_i
            ready[0] <= dready_i;
        end
    end

    // Data capture logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (integer i = 0; i < STAGES; i = i + 1) begin
                stage_data[i] <= 0;
            end
        end else begin
            // Capture data only at the first stage when valid[0] is high
            // and ready[0] is high (meaning dready_i is high)
            if (valid[0] && ready[0]) begin
                stage_data[0] <= din;
            end
            // Shift data through the pipeline
            for (integer i = 1; i < STAGES; i = i + 1) begin
                if (valid[i-1]) begin
                    stage_data[i] <= stage_data[i-1];
                end
            end
        end
    end

    // Output logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout <= 0;
            dready_o <= 0;
        end else begin
            // Output the data from the last stage if it is valid
            if (valid[STAGES-1]) begin
                dout <= stage_data[STAGES-1];
                // Pulse dready_o only if the previous stage was ready
                // This ensures we don't output when the source isn't ready
                if (ready[STAGES-2]) begin
                    dready_o <= 1;
                end else begin
                    dready_o <= 0;
                end
            end else begin
                dout <= 0;
                dready_o <= 0;
            end
        end
    end

endmodule<|im_end|>
