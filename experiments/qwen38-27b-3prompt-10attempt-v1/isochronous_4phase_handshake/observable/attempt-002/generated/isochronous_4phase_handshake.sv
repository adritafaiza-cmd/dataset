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

    // Synchronizer for dst_ready_i into src domain
    reg [1:0] dst_ready_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_sync <= 2'b00;
        else
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end

    // Synchronizer for src_ready_o into dst domain
    reg [1:0] src_ready_sync;
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_ready_sync <= 2'b00;
        else
            src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end

    // Synchronizer for dst_valid_o into src domain
    reg [1:0] dst_valid_sync;
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_valid_sync <= 2'b00;
        else
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_o};
    end

    // Source side state machine
    // States: IDLE, WAIT_DST_READY, WAIT_SRC_VALID_LOW
    reg src_state;
    localparam SRC_IDLE = 1'b0;
    localparam SRC_WAIT = 1'b1;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_state <= SRC_IDLE;
        else begin
            case (src_state)
                SRC_IDLE: begin
                    if (src_valid_i && dst_ready_sync[1])
                        src_state <= SRC_WAIT;
                    else
                        src_state <= SRC_IDLE;
                end
                SRC_WAIT: begin
                    if (!src_valid_i)
                        src_state <= SRC_IDLE;
                    else
                        src_state <= SRC_WAIT;
                end
            endcase
        end
    end

    assign src_ready_o = (src_state == SRC_IDLE) && dst_ready_sync[1];

    // Destination side state machine
    // States: IDLE, WAIT_SRC_VALID_LOW
    reg dst_state;
    localparam DST_IDLE = 1'b0;
    localparam DST_WAIT = 1'b1;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_state <= DST_IDLE;
        else begin
            case (dst_state)
                DST_IDLE: begin
                    if (src_valid_sync[1] && dst_ready_i)
                        dst_state <= DST_WAIT;
                    else
                        dst_state <= DST_IDLE;
                end
                DST_WAIT: begin
                    if (!src_valid_sync[1])
                        dst_state <= DST_IDLE;
                    else
                        dst_state <= DST_WAIT;
                end
            endcase
        end
    end

    assign dst_valid_o = (dst_state == DST_IDLE) && src_valid_sync[1];

endmodule
