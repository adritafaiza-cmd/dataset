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
reg [2:0] src_state;
reg src_valid_reg;
reg src_ready_reg;
reg dst_ready_sync1, dst_ready_sync2;

// Destination domain signals
reg dst_valid_reg;
reg src_valid_sync1, src_valid_sync2;

// Source domain states
localparam SRC_IDLE        = 3'd0,
           SRC_VALID       = 3'd1,
           SRC_VALID_READY = 3'd2,
           SRC_DEASSERT    = 3'd3,
           SRC_WAIT_READY  = 3'd4;

// Destination domain states
localparam DST_IDLE = 1'd0,
           DST_VALID = 1'd1;

// Source domain logic
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_state <= SRC_IDLE;
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b0;
        dst_ready_sync1 <= 1'b0;
        dst_ready_sync2 <= 1'b0;
    end else begin
        dst_ready_sync1 <= dst_ready_i;
        dst_ready_sync2 <= dst_ready_sync1;

        case (src_state)
            SRC_IDLE: begin
                if (src_valid_i) begin
                    src_valid_reg <= 1'b1;
                    src_state <= SRC_VALID;
                end
            end
            SRC_VALID: begin
                if (dst_ready_sync2) begin
                    src_ready_reg <= 1'b1;
                    src_state <= SRC_VALID_READY;
                end
            end
            SRC_VALID_READY: begin
                src_valid_reg <= 1'b0;
                src_state <= SRC_DEASSERT;
            end
            SRC_DEASSERT: begin
                src_ready_reg <= 1'b0;
                src_state <= SRC_WAIT_READY;
            end
            SRC_WAIT_READY: begin
                if (!dst_ready_sync2) begin
                    src_state <= SRC_IDLE;
                end
            end
            default: src_state <= SRC_IDLE;
        endcase
    end
end

assign src_ready_o = src_ready_reg;

// Destination domain logic
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_valid_reg <= 1'b0;
        src_valid_sync1 <= 1'b0;
        src_valid_sync2 <= 1'b0;
    end else begin
        src_valid_sync1 <= src_valid_reg;
        src_valid_sync2 <= src_valid_sync1;

        if (src_valid_sync2) begin
            dst_valid_reg <= 1'b1;
        end else if (dst_valid_reg && dst_ready_i) begin
            dst_valid_reg <= 1'b0;
        end
    end
end

assign dst_valid_o = dst_valid_reg;

endmodule
