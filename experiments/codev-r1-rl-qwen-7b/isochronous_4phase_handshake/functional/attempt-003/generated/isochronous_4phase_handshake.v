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

// Destination domain signals
reg dst_valid_reg;
reg dst_ready_reg;

// Synchronization registers
reg dst_ready_sync1, dst_ready_sync2;
reg src_valid_sync1, src_valid_sync2;

// Source domain logic
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b0;
    end else begin
        // Phase 1: Assert valid, deassert ready
        if (src_valid_i && !src_ready_reg) begin
            src_valid_reg <= 1'b1;
            src_ready_reg <= 1'b0;
        end
        // Phase 3: Deassert valid, assert ready
        else if (dst_ready_sync2 && src_valid_reg) begin
            src_valid_reg <= 1'b0;
            src_ready_reg <= 1'b1;
        end
    end
end

// Destination domain logic
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        dst_valid_reg <= 1'b0;
        dst_ready_reg <= 1'b0;
    end else begin
        // Phase 2: Assert ready when valid is high
        if (src_valid_sync2 && !dst_ready_reg) begin
            dst_ready_reg <= 1'b1;
        end
        // Phase 4: Deassert ready when valid is low
        else if (!src_valid_sync2 && dst_ready_sync2) begin
            dst_ready_reg <= 1'b0;
        end
    end
end

// Synchronize ready to source domain
always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
        dst_ready_sync1 <= 1'b0;
        dst_ready_sync2 <= 1'b0;
    end else begin
        dst_ready_sync1 <= dst_ready_reg;
        dst_ready_sync2 <= dst_ready_sync1;
    end
end

// Synchronize valid to destination domain
always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
        src_valid_sync1 <= 1'b0;
        src_valid_sync2 <= 1'b0;
    end else begin
        src_valid_sync1 <= src_valid_reg;
        src_valid_sync2 <= src_valid_sync1;
    end
end

// Assign outputs
assign src_ready_o = src_ready_reg;
assign dst_valid_o = dst_valid_reg;

endmodule
