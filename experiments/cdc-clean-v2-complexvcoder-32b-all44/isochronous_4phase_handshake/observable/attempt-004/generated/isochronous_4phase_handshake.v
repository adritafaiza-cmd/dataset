module isochronous_4phase_handshake (
    input  src_clk_i,
    input  src_rst_ni,
    input  src_valid_i,
    output src_ready_o,
    input  dst_clk_i,
    input  dst_rst_ni,
    output dst_valid_o,
    input  dst_ready_i
);

    reg [1:0] src_phase;
    reg [1:0] dst_phase;
    reg       src_ready_reg;
    reg       dst_valid_reg;
    reg [1:0] src_phase_cross;
    reg [1:0] dst_phase_cross;

    // Source clock domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase     <= 2'b00;
            src_ready_reg <= 1'b0;
        end else begin
            if (src_valid_i && src_ready_reg) begin
                src_phase <= src_phase + 1'b1;
            end
            src_ready_o <= (src_phase_cross == src_phase) && (src_phase != 2'b00);
        end
    end

    // Cross dst_phase to src_phase_cross
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase_cross <= 2'b00;
        end else begin
            src_phase_cross <= dst_phase;
        end
    end

    // Destination clock domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase     <= 2'b00;
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_ready_i && dst_valid_reg) begin
                dst_phase <= dst_phase + 1'b1;
            end
            dst_valid_o <= (dst_phase_cross == dst_phase) && (dst_phase != 2'b00);
        end
    end

    // Cross src_phase to dst_phase_cross
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase_cross <= 2'b00;
        end else begin
            dst_phase_cross <= src_phase;
        end
    end

endmodule
