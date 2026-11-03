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

    // Internal signals
    reg  src_req;
    reg  src_ack;
    reg  dst_req;
    reg  dst_ack;
    reg  src_req_synced;
    reg  src_ack_synced;
    reg  dst_req_synced;
    reg  dst_ack_synced;

    // Synchronization flops for CDC
    reg  src_req_synced_1;
    reg  src_ack_synced_1;
    reg  dst_req_synced_1;
    reg  dst_ack_synced_1;

    // Source clock domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_req <= 0;
            src_ack <= 0;
        end else begin
            // src_req is set when src_valid_i is high and src_ready_o is high
            src_req <= src_valid_i & src_ready_o;

            // src_ack is set when dst_req_synced is high and dst_ack_synced is low
            src_ack <= dst_req_synced & ~dst_ack_synced;
        end
    end

    // Destination clock domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_req <= 0;
            dst_ack <= 0;
        end else begin
            // dst_req is set when src_req_synced is high and src_ack_synced is low
            dst_req <= src_req_synced & ~src_ack_synced;

            // dst_ack is set when src_ack_synced is high
            dst_ack <= src_ack_synced;
        end
    end

    // Synchronization for src_req to dst_clk_i domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_req_synced_1 <= 0;
            src_req_synced   <= 0;
        end else begin
            src_req_synced_1 <= src_req;
            src_req_synced   <= src_req_synced_1;
        end
    end

    // Synchronization for src_ack to dst_clk_i domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ack_synced_1 <= 0;
            src_ack_synced   <= 0;
        end else begin
            src_ack_synced_1 <= src_ack;
            src_ack_synced   <= src_ack_synced_1;
        end
    end

    // Synchronization for dst_req to src_clk_i domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_req_synced_1 <= 0;
            dst_req_synced   <= 0;
        end else begin
            dst_req_synced_1 <= dst_req;
            dst_req_synced   <= dst_req_synced_1;
        end
    end

    // Synchronization for dst_ack to src_clk_i domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ack_synced_1 <= 0;
            dst_ack_synced   <= 0;
        end else begin
            dst_ack_synced_1 <= dst_ack;
            dst_ack_synced   <= dst_ack_synced_1;
        end
    end

    // Output assignments
    assign src_ready_o = ~src_req | ~dst_req_synced;
    assign dst_valid_o = dst_req;

endmodule
