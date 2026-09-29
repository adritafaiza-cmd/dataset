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

    // Source domain signals
    reg src_valid_reg;
    reg [1:0] src_state;

    localparam SRC_IDLE = 2'd0,
               SRC_ASSERT = 2'd1,
               SRC_WAIT = 2'd2,
               SRC_DEASSERT = 2'd3;

    // Synchronize dst_ready_i to src_clk
    reg dst_ready_sync1, dst_ready_sync;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync1 <= 0;
            dst_ready_sync <= 0;
        end else begin
            dst_ready_sync1 <= dst_ready_i;
            dst_ready_sync <= dst_ready_sync1;
        end
    end

    // Source state machine
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_reg <= 0;
            src_state <= SRC_IDLE;
        end else begin
            case (src_state)
                SRC_IDLE: begin
                    if (src_valid_i) begin
                        src_valid_reg <= 1;
                        src_state <= SRC_ASSERT;
                    end else begin
                        src_valid_reg <= 0;
                    end
                end
                SRC_ASSERT: begin
                    if (dst_ready_sync) begin
                        src_valid_reg <= 0;
                        src_state <= SRC_WAIT;
                    end
                end
                SRC_WAIT: begin
                    if (!dst_ready_sync) begin
                        src_state <= SRC_DEASSERT;
                    end
                end
                SRC_DEASSERT: begin
                    if (src_valid_i) begin
                        src_valid_reg <= 1;
                        src_state <= SRC_ASSERT;
                    end else begin
                        src_state <= SRC_IDLE;
                    end
                end
            endcase
        end
    end

    assign src_ready_o = (src_state == SRC_IDLE);

    // Destination domain signals
    reg src_valid_sync1, src_valid_sync;
    reg dst_valid_reg;
    reg [1:0] dst_state;

    localparam DST_IDLE = 2'd0,
               DST_ASSERT = 2'd1,
               DST_WAIT = 2'd2,
               DST_DEASSERT = 2'd3;

    // Synchronize src_valid_reg to dst_clk
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync1 <= 0;
            src_valid_sync <= 0;
        end else begin
            src_valid_sync1 <= src_valid_reg;
            src_valid_sync <= src_valid_sync1;
        end
    end

    // Destination state machine
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 0;
            dst_state <= DST_IDLE;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    if (src_valid_sync) begin
                        dst_valid_reg <= 1;
                        dst_state <= DST_ASSERT;
                    end
                end
                DST_ASSERT: begin
                    if (dst_ready_i) begin
                        dst_valid_reg <= 0;
                        dst_state <= DST_WAIT;
                    end
                end
                DST_WAIT: begin
                    if (!src_valid_sync) begin
                        dst_valid_reg <= 0;
                        dst_state <= DST_DEASSERT;
                    end
                end
                DST_DEASSERT: begin
                    if (src_valid_sync == 0) begin
                        dst_valid_reg <= 0;
                        dst_state <= DST_IDLE;
                    end
                end
            endcase
        end
    end

    assign dst_valid_o = dst_valid_reg;

endmodule
