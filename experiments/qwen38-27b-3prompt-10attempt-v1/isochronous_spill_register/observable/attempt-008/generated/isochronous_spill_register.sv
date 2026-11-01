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

    // Source domain state
    reg [WIDTH-1:0] src_reg0;
    reg             src_reg0_valid;
    reg [WIDTH-1:0] src_reg1;
    reg             src_reg1_valid;

    // Destination domain state
    reg [WIDTH-1:0] dst_reg0;
    reg             dst_reg0_valid;
    reg [WIDTH-1:0] dst_reg1;
    reg             dst_reg1_valid;

    // Synchronizers for src_ready (dst -> src)
    reg [1:0] src_ready_sync;
    wire      src_ready_o = src_ready_sync[1];

    // Synchronizers for dst_ready (src -> dst)
    reg [1:0] dst_ready_sync;
    wire      dst_ready = dst_ready_sync[1];

    // Synchronizers for src_reg0_valid (src -> dst)
    reg [1:0] src_reg0_valid_sync;
    wire      src_reg0_valid_d = src_reg0_valid_sync[1];

    // Synchronizers for src_reg1_valid (src -> dst)
    reg [1:0] src_reg1_valid_sync;
    wire      src_reg1_valid_d = src_reg1_valid_sync[1];

    // Synchronizers for dst_reg0_valid (dst -> src)
    reg [1:0] dst_reg0_valid_sync;
    wire      dst_reg0_valid_s = dst_reg0_valid_sync[1];

    // Synchronizers for dst_reg1_valid (dst -> src)
    reg [1:0] dst_reg1_valid_sync;
    wire      dst_reg1_valid_s = dst_reg1_valid_sync[1];

    // Synchronizers for src_data0 (src -> dst)
    reg [WIDTH-1:0] src_data0_sync;
    wire [WIDTH-1:0] src_data0_d = src_data0_sync;

    // Synchronizers for src_data1 (src -> dst)
    reg [WIDTH-1:0] src_data1_sync;
    wire [WIDTH-1:0] src_data1_d = src_data1_sync;

    // Synchronizers for dst_data0 (dst -> src)
    reg [WIDTH-1:0] dst_data0_sync;
    wire [WIDTH-1:0] dst_data0_s = dst_data0_sync;

    // Synchronizers for dst_data1 (dst -> src)
    reg [WIDTH-1:0] dst_data1_sync;
    wire [WIDTH-1:0] dst_data1_s = dst_data1_sync;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_reg0_valid <= 1'b0;
            src_reg1_valid <= 1'b0;
            src_reg0       <= {WIDTH{1'b0}};
            src_reg1       <= {WIDTH{1'b0}};
        end else begin
            // Accept data if valid and ready
            if (src_valid_i && src_ready_o) begin
                if (!src_reg0_valid) begin
                    src_reg0       <= src_data_i;
                    src_reg0_valid <= 1'b1;
                end else if (!src_reg1_valid) begin
                    src_reg1       <= src_data_i;
                    src_reg1_valid <= 1'b1;
                end
            end

            // Release reg0 if dst has consumed it
            if (src_reg0_valid && dst_reg0_valid_s == 1'b0 && dst_reg0_valid_d == 1'b1) begin
                // This is tricky - we need to know when dst has actually consumed
                // Let's use a different approach
            end
        end
    end

    // Let me redesign this more carefully.
    // The key insight: we need to track which slots are occupied in each domain.
    // Since clocks are related, we can use a simple approach with proper synchronization.

    // Actually, let me use a cleaner approach:
    // - Source domain: two registers with valid bits
    // - Destination domain: two registers with valid bits
    // - Synchronize valid bits and data between domains
    // - Use the synchronized valid bits to determine ready/valid

    // Source domain: accept when there's space
    // Destination domain: present when there's data

    // The tricky part is knowing when a slot is free in the other domain.

    // Let me use a different strategy:
    // - src_ready_o is high when at least one slot in src domain is free
    // - dst_valid_o is high when at least one slot in dst domain has data
    // - When src accepts, it writes to the first free slot in src domain
    // - When dst consumes, it reads from the first occupied slot in dst domain
    // - Data moves from src to dst when dst has a free slot and src has data

    // This is getting complex. Let me use a simpler 2-deep FIFO approach
    // with proper clock domain crossing.

    // Reset synchronizers
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_reg0_valid <= 1'b0;
            src_reg1_valid <= 1'b0;
        end else begin
            // Accept new data if valid and there's space
            if (src_valid_i && src_ready_o) begin
                if (!src_reg0_valid) begin
                    src_reg0       <= src_data_i;
                    src_reg0_valid <= 1'b1;
                end else if (!src_reg1_valid) begin
                    src_reg1       <= src_data_i;
                    src_reg1_valid <= 1'b1;
                end
            end

            // Clear src_reg0 when dst has consumed it
            if (src_reg0_valid && !dst_reg0_valid_s) begin
                src_reg0_valid <= 1'b0;
            end

            // Clear src_reg1 when dst has consumed it
            if (src_reg1_valid && !dst_reg1_valid_s) begin
                src_reg1_valid <= 1'b0;
            end
        end
    end

    // Destination domain: present data and clear when consumed
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_reg0_valid <= 1'b0;
            dst_reg1_valid <= 1'b0;
        end else begin
            // Set dst_reg0 when src_reg0 has data and dst_reg0 is empty
            if (!dst_reg0_valid && src_reg0_valid_d) begin
                dst_reg0       <= src_data0_d;
                dst_reg0_valid <= 1'b1;
            end

            // Set dst_reg1 when src_reg1 has data and dst_reg1 is empty
            if (!dst_reg1_valid && src_reg1_valid_d) begin
                dst_reg1       <= src_data1_d;
                dst_reg1_valid <= 1'b1;
            end

            // Clear dst_reg0 when consumed
            if (dst_reg0_valid && dst_ready_i) begin
                dst_reg0_valid <= 1'b0;
            end

            // Clear dst_reg1 when consumed
            if (dst_reg1_valid && dst_ready_i) begin
                dst_reg1_valid <= 1'b0;
            end
        end
    end

    // src_ready_o: high when at least one src slot is free
    assign src_ready_o = !src_reg0_valid || !src_reg1_valid;

    // dst_valid_o: high when at least one dst slot has data
    assign dst_valid_o = dst_reg0_valid || dst_reg1_valid;

    // dst_data_o: output from the first occupied dst slot
    assign dst_data_o = dst_reg0_valid ? dst_reg0 : dst_reg1;

    // Synchronizer for src_ready (dst -> src) - not needed since src_ready is in src domain
    // Actually src_ready_o is generated in src domain, so no sync needed

    // Synchronizer for dst_ready (src -> dst)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ready_sync <= 2'b00;
        end else begin
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
        end
    end

    // Synchronizer for src_reg0_valid (src -> dst)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_reg0_valid_sync <= 2'b00;
        end else begin
            src_reg0_valid_sync <= {src_reg0_valid_sync[0], src_reg0_valid};
        end
    end

    // Synchronizer for src_reg1_valid (src -> dst)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_reg1_valid_sync <= 2'b00;
        end else begin
            src_reg1_valid_sync <= {src_reg1_valid_sync[0], src_reg1_valid};
        end
    end

    // Synchronizer for dst_reg0_valid (dst -> src)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_reg0_valid_sync <= 2'b00;
        end else begin
            dst_reg0_valid_sync <= {dst_reg0_valid_sync[0], dst_reg0_valid};
        end
    end

    // Synchronizer for dst_reg1_valid (dst -> src)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_reg1_valid_sync <= 2'b00;
        end else begin
            dst_reg1_valid_sync <= {dst_reg1_valid_sync[0], dst_reg1_valid};
        end
    end

    // Synchronizer for src_data0 (src -> dst)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_data0_sync <= {WIDTH{1'b0}};
        end else begin
            src_data0_sync <= src_reg0;
        end
    end

    // Synchronizer for src_data1 (src -> dst)
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_data1_sync <= {WIDTH{1'b0}};
        end else begin
            src_data1_sync <= src_reg1;
        end
    end

endmodule
