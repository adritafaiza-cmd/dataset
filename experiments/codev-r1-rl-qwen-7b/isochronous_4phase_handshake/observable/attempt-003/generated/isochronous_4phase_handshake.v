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
    reg src_ready_reg;
    reg [2:0] state;
    localparam S_IDLE = 0,
               S_PHASE1 = 1,
               S_PHASE2 = 2,
               S_PHASE3 = 3;

    // Synchronize dst_ready_i to src_clk_i
    reg dst_ready_sync1, dst_ready_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync1 <= 1'b0;
            dst_ready_sync <= 1'b0;
        end else begin
            dst_ready_sync1 <= dst_ready_i;
            dst_ready_sync <= dst_ready_sync1;
        end
    end

    // Source state machine
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            state <= S_IDLE;
            src_valid_reg <= 1'b0;
            src_ready_reg <= 1'b1;
        end else begin
            case (state)
                S_IDLE: begin
                    if (src_valid_i && src_ready_reg) begin
                        src_valid_reg <= 1'b1;
                        src_ready_reg <= 1'b0;
                        state <= S_PHASE1;
                    end
                end
                S_PHASE1: begin
                    if (dst_ready_sync) begin
                        src_valid_reg <= 1'b0;
                        state <= S_PHASE2;
                    end
                end
                S_PHASE2: begin
                    if (!dst_ready_sync) begin
                        state <= S_PHASE3;
                    end
                end
                S_PHASE3: begin
                    if (dst_ready_sync) begin
                        src_valid_reg <= 1'b1;
                        state <= S_IDLE;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end

    assign src_ready_o = src_ready_reg;
    wire src_valid_o = src_valid_reg;

    // Destination domain signals
    reg dst_valid_reg;
    reg dst_ready_reg;
    reg [2:0] dst_state;
    localparam DST_IDLE = 0,
               DST_PHASE1 = 1,
               DST_PHASE2 = 2,
               DST_PHASE3 = 3,
               DST_PHASE4 = 4;

    // Synchronize src_valid_o to dst_clk_i
    reg src_valid_sync1, src_valid_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync1 <= 1'b0;
            src_valid_sync <= 1'b0;
        end else begin
            src_valid_sync1 <= src_valid_o;
            src_valid_sync <= src_valid_sync1;
        end
    end

    // Destination state machine
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state <= DST_IDLE;
            dst_valid_reg <= 1'b0;
            dst_ready_reg <= 1'b1;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    if (src_valid_sync && dst_ready_reg) begin
                        dst_valid_reg <= 1'b1;
                        dst_ready_reg <= 1'b0;
                        dst_state <= DST_PHASE1;
                    end
                end
                DST_PHASE1: begin
                    if (dst_ready_reg) begin
                        dst_valid_reg <= 1'b0;
                        dst_state <= DST_PHASE2;
                    end
                end
                DST_PHASE2: begin
                    if (!dst_ready_reg) begin
                        dst_valid_reg <= 1'b1;
                        dst_state <= DST_PHASE3;
                    end
                end
                DST_PHASE3: begin
                    if (dst_ready_reg) begin
                        dst_valid_reg <= 1'b0;
                        dst_state <= DST_PHASE4;
                    end
                end
                DST_PHASE4: begin
                    dst_ready_reg <= 1'b1;
                    dst_state <= DST_IDLE;
                end
                default: dst_state <= DST_IDLE;
            endcase
        end
    end

    assign dst_valid_o = dst_valid_reg;
    assign dst_ready_o = dst_ready_reg;

endmodule
