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

    // Internal signals
    reg [1:0] src_phase;
    reg [1:0] dst_phase;
    reg [1:0] src_phase_sync [0:1];
    reg [1:0] dst_phase_sync [0:1];

    // src_clk_i domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_phase <= 2'b00;
        end else begin
            src_phase <= src_phase + 1;
        end
    end

    // dst_clk_i domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_phase <= 2'b00;
        end else begin
            dst_phase <= dst_phase + 1;
        end
    end

    // Two-stage synchronizer for src_phase to dst_clk_i
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_phase_sync[0] <= 2'b00;
            src_phase_sync[1] <= 2'b00;
        end else begin
            src_phase_sync[0] <= src_phase;
            src_phase_sync[1] <= src_phase_sync[0];
        end
    end

    // Two-stage synchronizer for dst_phase to src_clk_i
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_phase_sync[0] <= 2'b00;
            dst_phase_sync[1] <= 2'b00;
        end else begin
            dst_phase_sync[0] <= dst_phase;
            dst_phase_sync[1] <= dst_phase_sync[0];
        end
    end

    // src_ready_o logic
    assign src_ready_o = (src_phase_sync[1] == (src_phase + 1) % 4) && src_valid_i;

    // dst_valid_o logic
    assign dst_valid_o = (dst_phase_sync[1] == (dst_phase + 1) % 4) && dst_ready_i;

endmodule
