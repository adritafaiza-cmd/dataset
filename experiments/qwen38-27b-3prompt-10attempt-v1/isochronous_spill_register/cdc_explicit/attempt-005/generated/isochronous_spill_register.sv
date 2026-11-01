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

    // Source domain: capture data and valid when accepted
    reg [WIDTH-1:0] src_data_reg;
    reg             src_valid_reg;
    reg             src_data_valid; // indicates data is latched and waiting to be sent to dst

    // Destination domain: receive data
    reg [WIDTH-1:0] dst_data_reg;
    reg             dst_valid_reg;

    // Handshake signals
    // src_ready_o: source can send if buffer is empty (no pending data)
    // dst_valid_o: destination has valid data

    // Source domain logic
    // We use a simple 1-deep buffer in source domain, then transfer to dst domain
    // Actually, let's use a 2-deep FIFO-like structure with valid/ready handshake

    // Let's implement a simple 2-entry buffer:
    // Entry 0: source side
    // Entry 1: destination side
    // But since clocks are related, we can use a simple approach:
    // Latch data in src domain, then present to dst domain with proper synchronization

    // For related clocks, we can use a simple register-to-register transfer
    // with valid/ready handshake. The key is to ensure the data is stable
    // when sampled in the destination domain.

    // Architecture:
    // 1. In src domain: if src_valid_i && src_ready_o, latch src_data_i into src_data_reg
    //    and set src_valid_reg = 1
    // 2. src_ready_o = !src_valid_reg (buffer empty)
    // 3. In dst domain: if dst_valid_reg && dst_ready_i, clear dst_valid_reg
    //    dst_valid_o = dst_valid_reg
    //    dst_data_o = dst_data_reg
    // 4. Transfer from src to dst: when src_valid_reg is high and dst is ready to accept
    //    (i.e., dst_valid_reg is low), transfer data

    // Since clocks are related, we can synchronize the valid signal
    // Let's use a 2-stage synchronizer for the valid signal from src to dst

    // Actually, for related clocks with integer ratio, we can use a simpler approach:
    // Use a single register in each domain with a handshake

    // Let me reconsider: a 2-deep spill buffer means we can hold 2 beats
    // Let's implement a 2-entry FIFO with valid/ready

    // Source domain:
    reg [WIDTH-1:0] fifo_data [0:1];
    reg             fifo_valid [0:1];
    reg [1:0]       src_wr_ptr;
    reg [1:0]       dst_rd_ptr;

    // Synchronize dst_rd_ptr to src domain
    reg [1:0] dst_rd_ptr_sync1;
    reg [1:0] dst_rd_ptr_sync2;

    // Synchronize src_wr_ptr to dst domain
    reg [1:0] src_wr_ptr_sync1;
    reg [1:0] src_wr_ptr_sync2;

    // Source domain: write pointer and ready
    wire src_full = (src_wr_ptr == dst_rd_ptr_sync2);
    assign src_ready_o = !src_full;

    // Write to FIFO in src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 2'd0;
            fifo_valid[0] <= 1'b0;
            fifo_valid[1] <= 1'b0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                fifo_data[src_wr_ptr[0]] <= src_data_i;
                fifo_valid[src_wr_ptr[0]] <= 1'b1;
                src_wr_ptr <= src_wr_ptr + 2'd1;
            end
        end
    end

    // Synchronize dst_rd_ptr to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_sync1 <= 2'd0;
            dst_rd_ptr_sync2 <= 2'd0;
        end else begin
            dst_rd_ptr_sync1 <= dst_rd_ptr;
            dst_rd_ptr_sync2 <= dst_rd_ptr_sync1;
        end
    end

    // Destination domain: read pointer and valid
    wire dst_empty = (dst_rd_ptr == src_wr_ptr_sync2);
    assign dst_valid_o = !dst_empty;
    assign dst_data_o = fifo_data[dst_rd_ptr[0]];

    // Read from FIFO in dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 2'd0;
        end else begin
            if (dst_valid_o && dst_ready_i) begin
                fifo_valid[dst_rd_ptr[0]] <= 1'b0;
                dst_rd_ptr <= dst_rd_ptr + 2'd1;
            end
        end
    end

    // Synchronize src_wr_ptr to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_sync1 <= 2'd0;
            src_wr_ptr_sync2 <= 2'd0;
        end else begin
            src_wr_ptr_sync1 <= src_wr_ptr;
            src_wr_ptr_sync2 <= src_wr_ptr_sync1;
        end
    end

endmodule
