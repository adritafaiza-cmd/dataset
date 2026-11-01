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

    // Synchronize src_valid_i to dst_clk domain
    reg [1:0] src_valid_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_valid_sync <= 2'b00;
        else
            src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end

    // Synchronize dst_ready_i to src_clk domain
    reg [1:0] dst_ready_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_sync <= 2'b00;
        else
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end

    // Synchronize src_ready_o to dst_clk domain
    reg [1:0] src_ready_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_ready_sync <= 2'b00;
        else
            src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end

    // Synchronize dst_valid_o to src_clk domain
    reg [1:0] dst_valid_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_valid_sync <= 2'b00;
        else
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_o};
    end

    // Four-phase handshake state machine in src_clk domain
    // States: IDLE, WAIT_READY, WAIT_VALID
    localparam IDLE       = 2'b00;
    localparam WAIT_READY = 2'b01;
    localparam WAIT_VALID = 2'b10;

    reg [1:0] src_state;
    reg       src_ready_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state     <= IDLE;
            src_ready_reg <= 1'b0;
        end else begin
            case (src_state)
                IDLE: begin
                    if (src_valid_i) begin
                        src_state     <= WAIT_READY;
                        src_ready_reg <= 1'b1;
                    end else begin
                        src_state     <= IDLE;
                        src_ready_reg <= 1'b0;
                    end
                end
                WAIT_READY: begin
                    if (dst_ready_sync[1]) begin
                        src_state     <= WAIT_VALID;
                        src_ready_reg <= 1'b0;
                    end else begin
                        src_state     <= WAIT_READY;
                        src_ready_reg <= 1'b1;
                    end
                end
                WAIT_VALID: begin
                    if (!src_valid_i) begin
                        src_state     <= IDLE;
                        src_ready_reg <= 1'b0;
                    end else begin
                        src_state     <= WAIT_VALID;
                        src_ready_reg <= 1'b0;
                    end
                end
                default: begin
                    src_state     <= IDLE;
                    src_ready_reg <= 1'b0;
                end
            endcase
        end
    end

    assign src_ready_o = src_ready_reg;

    // Four-phase handshake state machine in dst_clk domain
    // States: IDLE, WAIT_VALID, WAIT_READY
    localparam DST_IDLE       = 2'b00;
    localparam DST_WAIT_VALID = 2'b01;
    localparam DST_WAIT_READY = 2'b10;

    reg [1:0] dst_state;
    reg       dst_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state     <= DST_IDLE;
            dst_valid_reg <= 1'b0;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    if (src_valid_sync[1]) begin
                        dst_state     <= DST_WAIT_VALID;
                        dst_valid_reg <= 1'b1;
                    end else begin
                        dst_state     <= DST_IDLE;
                        dst_valid_reg <= 1'b0;
                    end
                end
                DST_WAIT_VALID: begin
                    if (dst_ready_i) begin
                        dst_state     <= DST_WAIT_READY;
                        dst_valid_reg <= 1'b0;
                    end else begin
                        dst_state     <= DST_WAIT_VALID;
                        dst_valid_reg <= 1'b1;
                    end
                end
                DST_WAIT_READY: begin
                    if (!src_valid_sync[1]) begin
                        dst_state     <= DST_IDLE;
                        dst_valid_reg <= 1'b0;
                    end else begin
                        dst_state     <= DST_WAIT_READY;
                        dst_valid_reg <= 1'b0;
                    end
                end
                default: begin
                    dst_state     <= DST_IDLE;
                    dst_valid_reg <= 1'b0;
                end
            endcase
        end
    end

    assign dst_valid_o = dst_valid_reg;

endmodule
