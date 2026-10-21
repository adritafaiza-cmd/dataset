```verilog
module sync_wedge #(
    parameter STAGES = 2
)(
    input  wire clk_i,
    input  wire rst_ni,
    input  wire en_i,
    input  wire serial_i,
    output wire r_edge_o,
    output wire f_edge_o,
    output wire serial_o
);

    // Internal clock domain signals
    logic [STAGES-1:0] sync_cnt;
    logic [STAGES-1:0] sync_cnt_next;
    logic serial_sync;
    logic serial_sync_valid;
    logic r_edge_det;
    logic f_edge_det;

    // Counter for synchronization delay
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            sync_cnt <= '0;
        else
            sync_cnt <= sync_cnt_next;
    end

    // Counter logic: increment until STAGES, then reset
    always_comb begin
        sync_cnt_next = sync_cnt;
        if (sync_cnt == STAGES - 1)
            sync_cnt_next = '0;
        else
            sync_cnt_next = sync_cnt + 1;
    end

    // Synchronize the input bit
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            serial_sync <= 1'b0;
        else if (sync_cnt == STAGES - 1)
            serial_sync <= serial_i;
        else
            serial_sync <= serial_sync;
    end

    // Valid flag indicates when the bit has been fully synchronized
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            serial_sync_valid <= 1'b0;
        else if (sync_cnt == STAGES - 1)
            serial_sync_valid <= 1'b1;
        else
            serial_sync_valid <= 1'b0;
    end

    // Output the synchronized bit
    assign serial_o = serial_sync;

    // Edge detection logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_det <= 1'b0;
            f_edge_det <= 1'b0;
        end
        else if (en_i && serial_sync_valid) begin
            if (serial_sync == 1'b1 && serial_sync_valid) begin
                // Rising edge detection
                r_edge_det <= 1'b1;
            end
            else if (serial_sync == 1'b0 && serial_sync_valid) begin
                // Falling edge detection
                f_edge_det <= 1'b1;
            end
        end
        else begin
            r_edge_det <= 1'b0;
            f_edge_det <= 1'b0;
        end
    end

    // Output edge detection signals
    assign r_edge_o = r_edge_det;
    assign f_edge_o = f_edge_det;

endmodule
```<|im_end|>
