```verilog
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

    // Synchronizer for src_valid_i to dst domain
    reg src_valid_synced;
    reg src_valid_synced_2;

    // Synchronizer for dst_ready_i to src domain
    reg dst_ready_synced;
    reg dst_ready_synced_2;

    // State machine state encoding
    // 0: IDLE
    // 1: WAIT_SRC (Waiting for src_valid)
    // 2: WAIT_DST (Waiting for dst_ready)
    // 3: DONE (Transfer acknowledged, waiting for next cycle)
    localparam IDLE = 2'b00;
    localparam WAIT_SRC = 2'b01;
    localparam WAIT_DST = 2'b10;
    localparam DONE = 2'b11;

    reg [1:0] state;
    reg src_valid_reg;

    // State register
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            state <= IDLE;
        else
            state <= state;
    end

    // State logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_valid_reg <= 1'b0;
        else
            src_valid_reg <= src_valid_i;
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_valid_synced <= 1'b0;
        else
            src_valid_synced <= src_valid_reg;
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_valid_synced_2 <= 1'b0;
        else
            src_valid_synced_2 <= src_valid_synced;
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_synced <= 1'b0;
        else
            dst_ready_synced <= dst_ready_i;
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_synced_2 <= 1'b0;
        else
            dst_ready_synced_2 <= dst_ready_synced;
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            state <= IDLE;
        else
            case (state)
                IDLE: begin
                    if (src_valid_synced_2)
                        state <= WAIT_SRC;
                    else
                        state <= IDLE;
                end
                WAIT_SRC: begin
                    if (src_valid_synced_2)
                        state <= WAIT_DST;
                    else
                        state <= WAIT_SRC;
                end
                WAIT_DST: begin
                    if (dst_ready_synced_2)
                        state <= DONE;
                    else
                        state <= WAIT_DST;
                end
                DONE: begin
                    if (dst_ready_synced_2)
                        state <= IDLE;
                    else
                        state <= DONE;
                end
                default: state <= IDLE;
            endcase
    end

    // Output logic
    assign src_ready_o = (state == WAIT_SRC) || (state == WAIT_DST) || (state == DONE);
    assign dst_valid_o = (state == WAIT_DST);

endmodule
```<|im_end|>
