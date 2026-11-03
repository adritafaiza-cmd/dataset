module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam AW = LOG_DEPTH;

    // Source domain state
    reg  [ADDR_WIDTH-1:0]  src_addr_r;
    reg  [DATA_WIDTH-1:0]  src_wdata_r;
    reg  [DATA_WIDTH/8-1:0] src_strb_r;
    reg  [2:0]             src_pprot_r;
    reg                    src_pwrite_r;
    reg                    src_valid_r;
    reg                    src_busy_r;

    // Destination domain state
    reg  [ADDR_WIDTH-1:0]  dst_addr_r;
    reg  [DATA_WIDTH-1:0]  dst_wdata_r;
    reg  [DATA_WIDTH/8-1:0] dst_strb_r;
    reg  [2:0]             dst_pprot_r;
    reg                    dst_pwrite_r;
    reg                    dst_valid_r;
    reg                    dst_busy_r;

    // Response path: dst -> src
    reg  [DATA_WIDTH-1:0]  resp_data_r;
    reg                    resp_err_r;
    reg                    resp_valid_r;

    // Synchronization signals
    // src_valid -> dst: 2-flop sync
    reg [1:0] src_valid_sync;
    // dst_valid -> src: 2-flop sync
    reg [1:0] dst_valid_sync;
    // src_busy -> dst: 2-flop sync
    reg [1:0] src_busy_sync;
    // dst_busy -> src: 2-flop sync
    reg [1:0] dst_busy_sync;

    // Data synchronization: use handshake-based approach
    // For multi-bit data, we use a simple approach:
    // Data is written to a register in src domain, then synchronized
    // using a valid/ready handshake to ensure coherence.

    // Actually, for a single outstanding transaction, we can use a simpler approach:
    // The data is stable in the source domain while the transaction is in flight.
    // We synchronize the data using a 2-flop synchronizer for each bit, but this
    // is not safe for multi-bit data. Instead, we use a handshake.

    // Let's use a different architecture:
    // 1. Source captures the APB request when src_psel & src_penable & src_pready
    // 2. Source asserts src_valid (synchronized to dst)
    // 3. Destination sees src_valid, captures the data (which is stable in src domain)
    //    But wait, the data is in src domain. We need to transfer it safely.

    // Better approach: Use a FIFO-like structure with handshake.
    // Since we only have one outstanding transaction, we can use a simple
    // valid/ready handshake with data held stable.

    // Let me reconsider. The key insight is:
    // - Data must be stable in the source domain while being transferred
    // - We can use a 2-phase handshake: src asserts valid, dst acknowledges
    // - Data is captured by dst when it sees valid, and since data is stable
    //   in src domain, we need to ensure dst samples it correctly.

    // For multi-bit data crossing CDC, the standard approach is to use
    // a synchronizer for each bit, but this can cause metastability issues
    // if bits arrive at different times. The safe approach is to use
    // a handshake where data is held stable until acknowledged.

    // Architecture:
    // 1. src_pready_o is asserted when src is not busy
    // 2. When src_psel & src_penable & src_pready, capture the request
    // 3. Assert src_valid (synced to dst)
    // 4. dst sees src_valid, captures data (data is stable in src domain)
    //    But we need to transfer data safely. Use a 2-flop sync for data?
    //    No, that's not safe for multi-bit.

    // Let's use a different approach: transfer data using a handshake
    // where the data is held in the source domain and the destination
    // reads it through synchronizers. Since the data is stable, we can
    // use a 2-flop synchronizer for each bit, and the valid signal
    // ensures we only sample when data is stable.

    // Actually, the safest approach for multi-bit data is to use a
    // Gray-coded pointer or a handshake. For a single transaction,
    // we can use the following:
    // - Data is held stable in src domain
    // - src_valid is synchronized to dst
    // - When dst sees src_valid, it samples the data through 2-flop
    //   synchronizers. Since data is stable, this is safe.

    // Let's implement this.

    // Data synchronizers (2-flop for each bit)
    reg [DATA_WIDTH-1:0]  wdata_sync1, wdata_sync2;
    reg [ADDR_WIDTH-1:0]  addr_sync1, addr_sync2;
    reg [DATA_WIDTH/8-1:0] strb_sync1, strb_sync2;
    reg [2:0]             pprot_sync1, pprot_sync2;
    reg                   pwrite_sync1, pwrite_sync2;

    // Response data synchronizers (dst -> src)
    reg [DATA_WIDTH-1:0]  rdata_sync1, rdata_sync2;
    reg                   rerr_sync1, rerr_sync2;

    // Source domain logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_addr_r   <= {ADDR_WIDTH{1'b0}};
            src_wdata_r  <= {DATA_WIDTH{1'b0}};
            src_strb_r   <= {(DATA_WIDTH/8){1'b0}};
            src_pprot_r  <= 3'b000;
            src_pwrite_r <= 1'b0;
            src_valid_r  <= 1'b0;
            src_busy_r   <= 1'b0;
            resp_data_r  <= {DATA_WIDTH{1'b0}};
            resp_err_r   <= 1'b0;
            resp_valid_r <= 1'b0;
        end else begin
            // Capture request when APB access phase completes
            if (src_psel_i & src_penable_i & src_pready_o) begin
                src_addr_r   <= src_paddr_i;
                src_wdata_r  <= src_pwdata_i;
                src_strb_r   <= src_pstrb_i;
                src_pprot_r  <= src_pprot_i;
                src_pwrite_r <= src_pwrite_i;
                src_valid_r  <= 1'b1;
                src_busy_r   <= 1'b1;
            end

            // Clear valid when destination acknowledges
            if (dst_valid_sync[1] & src_valid_r) begin
                src_valid_r <= 1'b0;
            end

            // Clear busy when response is received
            if (resp_valid_r) begin
                src_busy_r   <= 1'b0;
                resp_valid_r <= 1'b0;
            end

            // Capture response from destination
            if (dst_valid_sync[1] & ~src_valid_r) begin
                resp_data_r  <= rdata_sync2;
                resp_err_r   <= rerr_sync2;
                resp_valid_r <= 1'b1;
            end
        end
    end

    // Source outputs
    assign src_pready_o  = ~src_busy_r;
    assign src_prdata_o  = resp_data_r;
    assign src_pslverr_o = resp_err_r;

    // Synchronizers: src -> dst
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_valid_sync <= 2'b00;
            src_busy_sync  <= 2'b00;
            wdata_sync1    <= {DATA_WIDTH{1'b0}};
            wdata_sync2    <= {DATA_WIDTH{1'b0}};
            addr_sync1     <= {ADDR_WIDTH{1'b0}};
            addr_sync2     <= {ADDR_WIDTH{1'b0}};
            strb_sync1     <= {(DATA_WIDTH/8){1'b0}};
            strb_sync2     <= {(DATA_WIDTH/8){1'b0}};
            pprot_sync1    <= 3'b000;
            pprot_sync2    <= 3'b000;
            pwrite_sync1   <= 1'b0;
            pwrite_sync2   <= 1'b0;
        end else begin
            src_valid_sync <= {src_valid_sync[0], src_valid_r};
            src_busy_sync  <= {src_busy_sync[0], src_busy_r};
            wdata_sync1    <= src_wdata_r;
            wdata_sync2    <= wdata_sync1;
            addr_sync1     <= src_addr_r;
            addr_sync2     <= addr_sync1;
            strb_sync1     <= src_strb_r;
            strb_sync2     <= strb_sync1;
            pprot_sync1    <= src_pprot_r;
            pprot_sync2    <= pprot_sync1;
            pwrite_sync1   <= src_pwrite_r;
            pwrite_sync2   <= pwrite_sync1;
        end
    end

    // Synchronizers: dst -> src
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            dst_valid_sync <= 2'b00;
            dst_busy_sync  <= 2'b00;
            rdata_sync1    <= {DATA_WIDTH{1'b0}};
            rdata_sync2    <= {DATA_WIDTH{1'b0}};
            rerr_sync1     <= 1'b0;
            rerr_sync2     <= 1'b0;
        end else begin
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_r};
            dst_busy_sync  <= {dst_busy_sync[0], dst_busy_r};
            rdata_sync1    <= dst_prdata_i;
            rdata_sync2    <= rdata_sync1;
            rerr_sync1     <= dst_pslverr_i;
            rerr_sync2     <= rerr_sync1;
        end
    end

    // Destination domain logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_addr_r   <= {ADDR_WIDTH{1'b0}};
            dst_wdata_r  <= {DATA_WIDTH{1'b0}};
            dst_strb_r   <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_r  <= 3'b000;
            dst_pwrite_r <= 1'b0;
            dst_valid_r  <= 1'b0;
            dst_busy_r   <= 1'b0;
        end else begin
            // When source valid is seen, capture data and start APB transfer
            if (src_valid_sync[1] & ~dst_valid_r) begin
                dst_addr_r   <= addr_sync2;
                dst_wdata_r  <= wdata_sync2;
                dst_strb_r   <= strb_sync2;
                dst_pprot_r  <= pprot_sync2;
                dst_pwrite_r <= pwrite_sync2;
                dst_valid_r  <= 1'b1;
                dst_busy_r   <= 1'b1;
            end

            // When APB transfer completes, clear valid
            if (dst_valid_r & dst_pready_i) begin
                dst_valid_r <= 1'b0;
                dst_busy_r  <= 1'b0;
            end
        end
    end

    // Destination outputs
    assign dst_psel_o   = dst_valid_r;
    assign dst_penable_o = dst_valid_r & dst_pready_i;
    assign dst_pwrite_o = dst_pwrite_r;
    assign dst_paddr_o  = dst_addr_r;
    assign dst_pwdata_o = dst_wdata_r;
    assign dst_pstrb_o  = dst_strb_r;
    assign dst_pprot_o  = dst_pprot_r;

endmodule
