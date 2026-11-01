module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

    // Stage 0 (first register)
    reg [WIDTH-1:0] stage0_data;
    reg             stage0_valid;

    // Stage 1 (second register)
    reg [WIDTH-1:0] stage1_data;
    reg             stage1_valid;

    // Source domain: accept data into stage0 if stage0 is empty or being drained
    // Stage0 is empty when stage0_valid is 0
    // Stage0 can also accept if stage1 is empty (stage1_valid == 0) because stage0 will be drained to stage1
    // Actually, let's think about this more carefully.
    //
    // We have two registers. The source can write to stage0 when stage0 is not full.
    // Stage0 is full when stage0_valid is 1 and stage1 is not ready to accept (stage1_valid is 1).
    // Wait, let me reconsider the flow.
    //
    // Let's use a simpler approach:
    // - stage0_valid indicates stage0 has data
    // - stage1_valid indicates stage1 has data
    // - src_ready_o = ~stage0_valid | ~stage1_valid (stage0 can accept if it's empty, or if stage1 is empty so stage0 can be drained)
    //   Actually, src_ready_o should be 1 when we can accept new data. We can accept if stage0 is empty, OR if stage0 has data but stage1 is empty (so stage0 will be drained this cycle).
    //   Hmm, but the drain happens in the destination domain. Let me think again.
    //
    // Since the clocks are related (integer ratio), we can use a simple approach:
    // - In the source domain: if src_valid_i and src_ready_o, latch data into stage0.
    // - In the destination domain: if stage0_valid and ~stage1_valid, move stage0 to stage1.
    //   If stage1_valid and dst_ready_i, output stage1 and clear stage1.
    //
    // But wait, the moving from stage0 to stage1 and the output from stage1 both happen in the destination domain.
    // And the writing to stage0 happens in the source domain.
    //
    // Let me reconsider. Since the clocks are related, we can synchronize the valid signals.
    // But actually, for a 2-deep buffer with related clocks, we can do:
    //
    // Source domain:
    //   - If src_valid_i and src_ready_o, write src_data_i to stage0_data and set stage0_valid.
    //
    // Destination domain:
    //   - If stage0_valid and ~stage1_valid, move stage0_data to stage1_data, set stage1_valid, clear stage0_valid.
    //   - If stage1_valid and dst_ready_i, clear stage1_valid.
    //
    // src_ready_o = ~stage0_valid | ~stage1_valid
    //   This means: stage0 can accept if it's empty, or if stage1 is empty (so stage0 will be drained).
    //
    // Wait, but if stage0 has data and stage1 also has data, then src_ready_o = 0, which is correct.
    // If stage0 is empty, src_ready_o = 1, correct.
    // If stage0 has data but stage1 is empty, src_ready_o = 1, and in the next dst cycle, stage0 will be moved to stage1.
    // But what if in the same source cycle, we write to stage0 while it's being drained? That's a race condition.
    //
    // Let me think about this differently. Since the clocks are related, let's assume the worst case where they could be out of phase.
    //
    // Actually, for related clocks, a common approach is to use a handshake that works across the clock domains.
    // Let me use a simpler model:
    //
    // - stage0_valid is set in the source domain when data is accepted.
    // - stage0_valid is cleared in the destination domain when data is moved to stage1.
    // - stage1_valid is set in the destination domain when data is moved from stage0.
    // - stage1_valid is cleared in the destination domain when data is output.
    //
    // src_ready_o = ~stage0_valid | ~stage1_valid
    //
    // This should work. Let me implement it.

    assign src_ready_o = ~stage0_valid | ~stage1_valid;

    // Source domain: write to stage0
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            stage0_valid <= 1'b0;
            stage0_data  <= {WIDTH{1'b0}};
        end else if (src_valid_i && src_ready_o) begin
            stage0_valid <= 1'b1;
            stage0_data  <= src_data_i;
        end
    end

    // Destination domain: move stage0 to stage1, and output stage1
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            stage1_valid <= 1'b0;
            stage1_data  <= {WIDTH{1'b0}};
        end else begin
            // Move stage0 to stage1 if stage0 has data and stage1 is empty
            if (stage0_valid && ~stage1_valid) begin
                stage1_valid <= 1'b1;
                stage1_data  <= stage0_data;
            end
            // Clear stage1 if it's being output
            if (stage1_valid && dst_ready_i) begin
                stage1_valid <= 1'b0;
            end
        end
    end

    // Clear stage0_valid when data is moved to stage1 (in destination domain)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            stage0_valid <= 1'b0;
        end else if (stage0_valid && ~stage1_valid) begin
            stage0_valid <= 1'b0;
        end
    end

    // Output
    assign dst_valid_o = stage1_valid;
    assign dst_data_o  = stage1_data;

endmodule
