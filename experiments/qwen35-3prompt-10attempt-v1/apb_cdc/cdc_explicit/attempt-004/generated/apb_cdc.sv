```verilog
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
    localparam VALID_WIDTH = 1;
    localparam DATA_WIDTH_LOG = $clog2(DATA_WIDTH);

    // ------------------------------------------------------------------
    // CDC Strategy:
    // 1. Source Side: Capture incoming APB signals on src_pclk_i.
    //    Use a 2-stage synchronizer for async signals (sel, en, wr, addr, data, strb, prot).
    //    Use a 2-stage synchronizer for the handshake signal (dst_pready_i) to detect completion.
    //    Use a 2-stage synchronizer for the return data/error signals.
    // 2. Destination Side: Capture outgoing APB signals on dst_pclk_i.
    //    Use a 2-stage synchronizer for the handshake signal (dst_pready_i) to detect completion.
    //    Use a 2-stage synchronizer for the return data/error signals.
    // 3. Reset Domain Crossing: Use a 2-stage synchronizer for reset signals.
    // 4. FIFO: A simple 1-deep FIFO (or shift register) is sufficient to hold the transaction
    //    while the destination completes the transfer. Since LOG_DEPTH=1, we use a single register
    //    to store the captured transaction and a valid flag.
    // ------------------------------------------------------------------

    // ------------------------------------------------------------------
    // Synchronizers
    // ------------------------------------------------------------------

    // Source Clock Domain Synchronizers
    wire src_psel_synced;
    wire src_penable_synced;
    wire src_pwrite_synced;
    wire [ADDR_WIDTH-1:0] src_paddr_synced;
    wire [DATA_WIDTH-1:0] src_pwdata_synced;
    wire [DATA_WIDTH/8-1:0] src_pstrb_synced;
    wire [2:0] src_pprot_synced;
    wire src_pready_dst_synced;
    wire [DATA_WIDTH-1:0] dst_prdata_src_synced;
    wire dst_pslverr_src_synced;

    // Destination Clock Domain Synchronizers
    wire dst_psel_synced;
    wire dst_penable_synced;
    wire dst_pwrite_synced;
    wire [ADDR_WIDTH-1:0] dst_paddr_synced;
    wire [DATA_WIDTH-1:0] dst_pwdata_synced;
    wire [DATA_WIDTH/8-1:0] dst_pstrb_synced;
    wire [2:0] dst_pprot_synced;
    wire dst_pready_src_synced;
    wire [DATA_WIDTH-1:0] src_prdata_dst_synced;
    wire src_pslverr_dst_synced;

    // Reset Synchronizers
    wire src_reset_synced;
    wire dst_reset_synced;

    // ------------------------------------------------------------------
    // Synchronizer Logic
    // ------------------------------------------------------------------

    // Source Domain Synchronizers (Input from src, Output to dst logic)
    assign src_psel_synced = src_psel_i[0] ? src_psel_i[1] : 1'b0;
    assign src_penable_synced = src_penable_i[0] ? src_penable_i[1] : 1'b0;
    assign src_pwrite_synced = src_pwrite_i[0] ? src_pwrite_i[1] : 1'b0;
    assign src_paddr_synced = src_paddr_i[0] ? src_paddr_i[1] : 8'h0;
    assign src_pwdata_synced = src_pwdata_i[0] ? src_pwdata_i[1] : 32'h0;
    assign src_pstrb_synced = src_pstrb_i[0] ? src_pstrb_i[1] : 1'b0;
    assign src_pprot_synced = src_pprot_i[0] ? src_pprot_i[1] : 3'b0;

    // Destination Domain Synchronizers (Input from dst, Output to src logic)
    assign dst_psel_synced = dst_psel_i[0] ? dst_psel_i[1] : 1'b0;
    assign dst_penable_synced = dst_penable_i[0] ? dst_penable_i[1] : 1'b0;
    assign dst_pwrite_synced = dst_pwrite_i[0] ? dst_pwrite_i[1] : 1'b0;
    assign dst_paddr_synced = dst_paddr_i[0] ? dst_paddr_i[1] : 8'h0;
    assign dst_pwdata_synced = dst_pwdata_i[0] ? dst_pwdata_i[1] : 32'h0;
    assign dst_pstrb_synced = dst_pstrb_i[0] ? dst_pstrb_i[1] : 1'b0;
    assign dst_pprot_synced = dst_pprot_i[0] ? dst_pprot_i[1] : 3'b0;

    // Handshake Synchronizers
    assign src_pready_dst_synced = dst_pready_i[0] ? dst_pready_i[1] : 1'b0;
    assign dst_pready_src_synced = src_pready_i[0] ? src_pready_i[1] : 1'b0;

    // Data Synchronizers
    assign dst_prdata_src_synced = dst_prdata_i[0] ? dst_prdata_i[1] : 32'h0;
    assign src_prdata_dst_synced = src_prdata_i[0] ? src_prdata_i[1] : 32'h0;

    // Reset Synchronizers
    assign src_reset_synced = src_preset_ni[0] ? src_preset_ni[1] : 1'b1;
    assign dst_reset_synced = dst_preset_ni[0] ? dst_preset_ni[1] : 1'b1;

    // ------------------------------------------------------------------
    // Internal State Machine and FIFO
    // ------------------------------------------------------------------

    // State: IDLE, CAPTURE, FORWARD, WAIT_READY
    // Since we only need to hold one transaction, a simple register-based FIFO with depth 1 is enough.
    // We capture the transaction when sel is high, then forward it.
    // We wait for dst_pready to complete the transaction.

    reg [LOG_DEPTH-1:0] fifo_addr;
    reg valid;
    reg src_psel_reg;
    reg src_penable_reg;
    reg src_pwrite_reg;
    reg [ADDR_WIDTH-1:0] fifo_paddr;
    reg [DATA_WIDTH-1:0] fifo_pwdata;
    reg [DATA_WIDTH/8-1:0] fifo_pstrb;
    reg [2:0] fifo_pprot;

    // Output registers for destination
    reg dst_psel_out;
    reg dst_penable_out;
    reg dst_pwrite_out;
    reg [ADDR_WIDTH-1:0] dst_paddr_out;
    reg [DATA_WIDTH-1:0] dst_pwdata_out;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_out;
    reg [2:0] dst_pprot_out;

    // Output registers for source
    reg src_pready_out;
    reg [DATA_WIDTH-1:0] src_prdata_out;
    reg src_pslverr_out;

    // ------------------------------------------------------------------
    // Source Side Logic
    // ------------------------------------------------------------------

    // Capture transaction on src_pclk_i
    always @(posedge src_pclk_i or negedge src_reset_synced) begin
        if (!src_reset_synced) begin
            valid <= 1'b0;
            src_psel_reg <= 1'b0;
            src_penable_reg <= 1'b0;
            src_pwrite_reg <= 1'b0;
            fifo_paddr <= 8'h0;
            fifo_pwdata <= 32'h0;
            fifo_pstrb <= 1'b0;
            fifo_pprot <= 3'b0;
        end else begin
            // Capture new transaction if sel is asserted and we are not already capturing
            // Note: APB protocol requires sel to be stable for at least 2 cycles.
            // We capture on the first cycle of sel being high.
            if (src_psel_synced && !src_psel_reg) begin
                valid <= 1'b1;
                src_psel_reg <= 1'b1;
                src_penable_reg <= src_penable_synced;
                src_pwrite_reg <= src_pwrite_synced;
                fifo_paddr <= src_paddr_synced;
                fifo_pwdata <= src_pwdata_synced;
                fifo_pstrb <= src_pstrb_synced;
                fifo_pprot <= src_pprot_synced;
            end else if (src_psel_synced && src_psel_reg) begin
                // Update fields if sel is still high (for multi-cycle transactions)
                src_penable_reg <= src_penable_synced;
                src_pwrite_reg <= src_pwrite_synced;
                fifo_paddr <= src_paddr_synced;
                fifo_pwdata <= src_pwdata_synced;
                fifo_pstrb <= src_pstrb_synced;
                fifo_pprot <= src_pprot_synced;
            end else begin
                // Transaction complete or idle
                src_psel_reg <= 1'b0;
                valid <= 1'b0;
            end
        end
    end

    // Drive destination signals
    always @(posedge src_pclk_i or negedge src_reset_synced) begin
        if (!src_reset_synced) begin
            dst_psel_out <= 1'b0;
            dst_penable_out <= 1'b0;
            dst_pwrite_out <= 1'b0;
            dst_paddr_out <= 8'h0;
            dst_pwdata_out <= 32'h0;
            dst_pstrb_out <= 1'b0;
            dst_pprot_out <= 3'b0;
        end else begin
            if (valid) begin
                dst_psel_out <= 1'b1;
                dst_penable_out <= src_penable_reg;
                dst_pwrite_out <= src_pwrite_reg;
                dst_paddr_out <= fifo_paddr;
                dst_pwdata_out <= fifo_pwdata;
                dst_pstrb_out <= fifo_pstrb;
                dst_pprot_out <= fifo_pprot;
            end else begin
                dst_psel_out <= 1'b0;
                dst_penable_out <= 1'b0;
                dst_pwrite_out <= 1'b0;
                dst_paddr_out <= 8'h0;
                dst_pwdata_out <= 32'h0;
                dst_pstrb_out <= 1'b0;
                dst_pprot_out <= 3'b0;
            end
        end
    end

    // Drive source response signals
    always @(posedge src_pclk_i or negedge src_reset_synced) begin
        if (!src_reset_synced) begin
            src_pready_out <= 1'b0;
            src_prdata_out <= 32'h0;
            src_pslverr_out <= 1'b0;
        end else begin
            if (valid) begin
                // Wait for destination to be ready
                if (src_pready_dst_synced) begin
                    // Transaction complete
                    valid <= 1'b0;
                    src_pready_out <= 1'b1;
                    src_prdata_out <= dst_prdata_src_synced;
                    src_pslverr_out <= dst_pslverr_src_synced;
                end else begin
                    // Still waiting
                    src_pready_out <= 1'b0;
                    src_prdata_out <= 32'h0;
                    src_pslverr_out <= 1'b0;
                end
            end else begin
                src_pready_out <= 1'b0;
                src_prdata_out <= 32'h0;
                src_pslverr_out <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Destination Side Logic
    // ------------------------------------------------------------------

    // Capture transaction on dst_pclk_i
    always @(posedge dst_pclk_i or negedge dst_reset_synced) begin
        if (!dst_reset_synced) begin
            valid <= 1'b0;
            dst_psel_reg <= 1'b0;
            dst_penable_reg <= 1'b0;
            dst_pwrite_reg <= 1'b0;
            dst_paddr_reg <= 8'h0;
            dst_pwdata_reg <= 32'h0;
            dst_pstrb_reg <= 1'b0;
            dst_pprot_reg <= 3'b0;
        end else begin
            if (dst_psel_synced && !dst_psel_reg) begin
                valid <= 1'b1;
                dst_psel_reg <= 1'b1;
                dst_penable_reg <= dst_penable_synced;
                dst_pwrite_reg <= dst_pwrite_synced;
                dst_paddr_reg <= dst_paddr_synced;
                dst_pwdata_reg <= dst_pwdata_synced;
                dst_pstrb_reg <= dst_pstrb_synced;
                dst_pprot_reg <= dst_pprot_synced;
            end else if (dst_psel_synced && dst_psel_reg) begin
                dst_penable_reg <= dst_penable_synced;
                dst_pwrite_reg <= dst_pwrite_synced;
                dst_paddr_reg <= dst_paddr_synced;
                dst_pwdata_reg <= dst_pwdata_synced;
                dst_pstrb_reg <= dst_pstrb_synced;
                dst_pprot_reg <= dst_pprot_synced;
            end else begin
                dst_psel_reg <= 1'b0;
                valid <= 1'b0;
            end
        end
    end

    // Drive source response signals
    always @(posedge dst_pclk_i or negedge dst_reset_synced) begin
        if (!dst_reset_synced) begin
            src_pready_out <= 1'b0;
            src_prdata_out <= 32'h0;
            src_pslverr_out <= 1'b0;
        end else begin
            if (valid) begin
                if (dst_pready_src_synced) begin
                    valid <= 1'b0;
                    src_pready_out <= 1'b1;
                    src_prdata_out <= src_prdata_dst_synced;
                    src_pslverr_out <= src_pslverr_dst_synced;
                end else begin
                    src_pready_out <= 1'b0;
                    src_prdata_out <= 32'h0;
                    src_pslverr_out <= 1'b0;
                end
            end else begin
                src_pready_out <= 1'b0;
                src_prdata_out <= 32'h0;
                src_pslverr_out <= 1'b0;
            end
        end
    end

    // Drive destination signals
    always @(posedge dst_pclk_i or negedge dst_reset_synced) begin
        if (!dst_reset_synced) begin
            dst_psel_out <= 1'b0;
            dst_penable_out <= 1'b0;
            dst_pwrite_out <= 1'b0;
            dst_paddr_out <= 8'h0;
            dst_pwdata_out <= 32'h0;
            dst_pstrb_out <= 1'b0;
            dst_pprot_out <= 3'b0;
        end else begin
            if (valid) begin
                dst_psel_out <= 1'b1;
                dst_penable_out <= dst_penable_reg;
                dst_pwrite_out <= dst_pwrite_reg;
                dst_paddr_out <= dst_paddr_reg;
                dst_pwdata_out <= dst_pwdata_reg;
                dst_pstrb_out <= dst_pstrb_reg;
                dst_pprot_out <= dst_pprot_reg;
            end else begin
                dst_psel_out <= 1'b0;
                dst_penable_out <= 1'b0;
                dst_pwrite_out <= 1'b0;
                dst_paddr_out <= 8'h0;
                dst_pwdata_out <= 32'h0;
                dst_pstrb_out <= 1'b0;
                dst_pprot_out <= 3'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // Output Assignments
    // ------------------------------------------------------------------

    assign src_pready_o = src_pready_out;
    assign src_prdata_o = src_prdata_out;
    assign src_pslverr_o = src_pslverr_out;
    assign dst_psel_o = dst_psel_out;
    assign dst_penable_o = dst_penable_out;
    assign dst_pwrite_o = dst_pwrite_out;
    assign dst_paddr_o = dst_paddr_out;
    assign dst_pwdata_o = dst_pwdata_out;
    assign dst_pstrb_o = dst_pstrb_out;
    assign dst_pprot_o = dst_pprot_out;

endmodule
```<|im_end|>
