module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output reg [WIDTH-1:0] dst_data_o
);

    // Source domain state: 0 = empty, 1 = full
    reg src_state;
    // Destination domain state: 0 = empty, 1 = full
    reg dst_state;
    // Data storage for the single slot in the 2-deep buffer
    // We use two registers to simulate depth 2 by toggling state,
    // but logically we only need one storage element if we treat the
    // "2-deep" requirement as a specific implementation constraint for
    // absorbing jitter. However, a standard 2-deep FIFO requires 2 storage elements.
    // Given the "related clocks" and "short rate mismatch" context, a 2-deep
    // buffer implies we can hold 2 beats.
    // Let's implement a proper 2-deep FIFO using two storage registers.
    reg [WIDTH-1:0] data_0;
    reg [WIDTH-1:0] data_1;

    // Synchronous logic for Source Domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state <= 1'b0;
            data_0    <= 0;
            data_1    <= 0;
        end else begin
            case (src_state)
                1'b0: begin
                    if (src_valid_i) begin
                        src_state <= 1'b1;
                        data_0    <= src_data_i;
                    end
                end
                1'b1: begin
                    if (src_valid_i) begin
                        src_state <= 1'b2;
                        data_1    <= src_data_i;
                    end
                end
                1'b2: begin
                    if (src_valid_i) begin
                        src_state <= 1'b1; // Wrap around to 1 (effectively shifting)
                        data_0    <= src_data_i;
                    end
                end
            endcase
        end
    end

    // Synchronous logic for Destination Domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state <= 1'b0;
            dst_valid_o <= 1'b0;
            dst_data_o <= 0;
        end else begin
            case (dst_state)
                1'b0: begin
                    if (dst_ready_i) begin
                        dst_state <= 1'b1;
                        dst_valid_o <= 1'b1;
                        dst_data_o <= data_0;
                    end
                end
                1'b1: begin
                    if (dst_ready_i) begin
                        dst_state <= 1'b2;
                        dst_valid_o <= 1'b1;
                        dst_data_o <= data_1;
                    end
                end
                1'b2: begin
                    if (dst_ready_i) begin
                        dst_state <= 1'b1; // Wrap around
                        dst_valid_o <= 1'b1;
                        dst_data_o <= data_0;
                    end
                end
            endcase
        end
    end

    // Handshake logic
    always @(*) begin
        src_ready_o = (src_state == 1'b0) ? 1'b1 : 1'b0;
    end

endmodule<|im_end|>
