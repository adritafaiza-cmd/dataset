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

    // Synchronizer for src_valid_i into dst domain
    reg [1:0] src_valid_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_valid_sync <= 2'b00;
        else
            src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
    wire src_valid_dst = src_valid_sync[1];

    // Synchronizer for dst_ready_i into src domain
    reg [1:0] dst_ready_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_sync <= 2'b00;
        else
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
    wire dst_ready_src = dst_ready_sync[1];

    // Synchronizer for src_ready_o into dst domain
    reg [1:0] src_ready_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_ready_sync <= 2'b00;
        else
            src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
    wire src_ready_dst = src_ready_sync[1];

    // Synchronizer for dst_valid_o into src domain
    reg [1:0] dst_valid_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_valid_sync <= 2'b00;
        else
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_o};
    end
    wire dst_valid_src = dst_valid_sync[1];

    // Source side state machine
    // States: IDLE, WAIT_READY, WAIT_ACK
    localparam SRC_IDLE      = 2'b00;
    localparam SRC_WAIT_RDY  = 2'b01;
    localparam SRC_WAIT_ACK  = 2'b10;

    reg [1:0] src_state;
    reg       src_ready_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state     <= SRC_IDLE;
            src_ready_reg <= 1'b0;
        end else begin
            case (src_state)
                SRC_IDLE: begin
                    if (src_valid_i) begin
                        src_state     <= SRC_WAIT_RDY;
                        src_ready_reg <= 1'b1;
                    end else begin
                        src_state     <= SRC_IDLE;
                        src_ready_reg <= 1'b0;
                    end
                end
                SRC_WAIT_RDY: begin
                    if (dst_ready_src) begin
                        src_state     <= SRC_WAIT_ACK;
                        src_ready_reg <= 1'b0;
                    end else begin
                        src_state     <= SRC_WAIT_RDY;
                        src_ready_reg <= 1'b1;
                    end
                end
                SRC_WAIT_ACK: begin
                    if (!dst_valid_src) begin
                        src_state     <= SRC_IDLE;
                        src_ready_reg <= 1'b0;
                    end else begin
                        src_state     <= SRC_WAIT_ACK;
                        src_ready_reg <= 1'b0;
                    end
                end
                default: begin
                    src_state     <= SRC_IDLE;
                    src_ready_reg <= 1'b0;
                end
            endcase
        end
    end

    assign src_ready_o = src_ready_reg;

    // Destination side state machine
    // States: IDLE, WAIT_VALID, WAIT_ACK
    localparam DST_IDLE      = 2'b00;
    localparam DST_WAIT_VAL  = 2'b01;
    localparam DST_WAIT_ACK  = 2'b10;

    reg [1:0] dst_state;
    reg       dst_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state     <= DST_IDLE;
            dst_valid_reg <= 1'b0;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    if (src_valid_dst) begin
                        dst_state     <= DST_WAIT_VAL;
                        dst_valid_reg <= 1'b1;
                    end else begin
                        dst_state     <= DST_IDLE;
                        dst_valid_reg <= 1'b0;
                    end
                end
                DST_WAIT_VAL: begin
                    if (dst_ready_i) begin
                        dst_state     <= DST_WAIT_ACK;
                        dst_valid_reg <= 1'b0;
                    end else begin
                        dst_state     <= DST_WAIT_VAL;
                        dst_valid_reg <= 1'b1;
                    end
                end
                DST_WAIT_ACK: begin
                    if (!src_ready_dst) begin
                        dst_state     <= DST_IDLE;
                        dst_valid_reg <= 1'b0;
                    end else begin
                        dst_state     <= DST_WAIT_ACK;
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
