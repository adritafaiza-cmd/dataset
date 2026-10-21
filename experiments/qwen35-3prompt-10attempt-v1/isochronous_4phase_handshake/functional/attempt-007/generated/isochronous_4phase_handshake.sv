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

    reg src_state;
    reg dst_state;
    reg src_valid_reg;
    reg dst_valid_reg;
    reg dst_ready_reg;

    // State encoding: 0=Idle, 1=WaitValid, 2=WaitReady, 3=WaitValidAck, 4=WaitReadyAck
    // Source Domain States
    // 0: Idle (src_ready_o = 0)
    // 1: Waiting for dst_valid_o (src_ready_o = 1)
    // 2: Waiting for dst_ready_i (src_ready_o = 0)
    // 3: Waiting for dst_valid_o again (src_ready_o = 1)
    // 4: Waiting for dst_ready_i again (src_ready_o = 0)

    // Destination Domain States
    // 0: Idle (dst_valid_o = 0)
    // 1: Waiting for src_ready_o (dst_valid_o = 1)
    // 2: Waiting for src_valid_i (dst_valid_o = 0)
    // 3: Waiting for src_ready_o again (dst_valid_o = 1)
    // 4: Waiting for src_valid_i again (dst_valid_o = 0)

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state <= 0;
            src_valid_reg <= 0;
            src_ready_o <= 0;
        end else begin
            case (src_state)
                0: begin // Idle
                    src_ready_o <= 0;
                    if (src_valid_i)
                        src_state <= 1;
                end
                1: begin // Wait for dst_valid_o
                    src_ready_o <= 1;
                    if (src_valid_i && dst_valid_o)
                        src_state <= 2;
                end
                2: begin // Wait for dst_ready_i
                    src_ready_o <= 0;
                    if (dst_ready_i)
                        src_state <= 3;
                end
                3: begin // Wait for dst_valid_o again
                    src_ready_o <= 1;
                    if (dst_valid_o)
                        src_state <= 4;
                end
                4: begin // Wait for dst_ready_i again
                    src_ready_o <= 0;
                    if (dst_ready_i)
                        src_state <= 0; // Complete handshake
                end
                default: begin
                    src_state <= 0;
                    src_ready_o <= 0;
                end
            endcase
        end
    end

    // Synchronize dst_ready_i to src domain for state machine
    reg dst_ready_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_sync <= 0;
        else
            dst_ready_sync <= dst_ready_i;
    end

    // Synchronize dst_valid_o to src domain for state machine
    reg dst_valid_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_valid_sync <= 0;
        else
            dst_valid_sync <= dst_valid_o;
    end

    // Update state machine with synchronized signals
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state <= 0;
            src_valid_reg <= 0;
            src_ready_o <= 0;
        end else begin
            case (src_state)
                0: begin
                    src_ready_o <= 0;
                    if (src_valid_i)
                        src_state <= 1;
                end
                1: begin
                    src_ready_o <= 1;
                    if (src_valid_i && dst_valid_sync)
                        src_state <= 2;
                end
                2: begin
                    src_ready_o <= 0;
                    if (dst_ready_sync)
                        src_state <= 3;
                end
                3: begin
                    src_ready_o <= 1;
                    if (dst_valid_sync)
                        src_state <= 4;
                end
                4: begin
                    src_ready_o <= 0;
                    if (dst_ready_sync)
                        src_state <= 0;
                end
                default: begin
                    src_state <= 0;
                    src_ready_o <= 0;
                end
            endcase
        end
    end

    // Destination Domain State Machine
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state <= 0;
            dst_valid_reg <= 0;
            dst_valid_o <= 0;
        end else begin
            case (dst_state)
                0: begin // Idle
                    dst_valid_o <= 0;
                    if (dst_ready_i)
                        dst_state <= 1;
                end
                1: begin // Wait for src_ready_o
                    dst_valid_o <= 1;
                    if (dst_ready_i && src_ready_o)
                        dst_state <= 2;
                end
                2: begin // Wait for src_valid_i
                    dst_valid_o <= 0;
                    if (src_valid_i)
                        dst_state <= 3;
                end
                3: begin // Wait for src_ready_o again
                    dst_valid_o <= 1;
                    if (src_ready_o)
                        dst_state <= 4;
                end
                4: begin // Wait for src_valid_i again
                    dst_valid_o <= 0;
                    if (src_valid_i)
                        dst_state <= 0; // Complete handshake
                end
                default: begin
                    dst_state <= 0;
                    dst_valid_o <= 0;
                end
            endcase
        end
    end

    // Synchronize src_valid_i to dst domain for state machine
    reg src_valid_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_valid_sync <= 0;
        else
            src_valid_sync <= src_valid_i;
    end

    // Update destination state machine with synchronized signals
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state <= 0;
            dst_valid_reg <= 0;
            dst_valid_o <= 0;
        end else begin
            case (dst_state)
                0: begin
                    dst_valid_o <= 0;
                    if (dst_ready_i)
                        dst_state <= 1;
                end
                1: begin
                    dst_valid_o <= 1;
                    if (dst_ready_i && src_valid_sync)
                        dst_state <= 2;
                end
                2: begin
                    dst_valid_o <= 0;
                    if (src_valid_sync)
                        dst_state <= 3;
                end
                3: begin
                    dst_valid_o <= 1;
                    if (src_valid_sync)
                        dst_state <= 4;
                end
                4: begin
                    dst_valid_o <= 0;
                    if (src_valid_sync)
                        dst_state <= 0;
                end
                default: begin
                    dst_state <= 0;
                    dst_valid_o <= 0;
                end
            endcase
        end
    end

endmodule<|im_end|>
