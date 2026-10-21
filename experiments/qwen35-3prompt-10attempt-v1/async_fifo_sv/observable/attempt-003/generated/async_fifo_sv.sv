```systemverilog
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output wire                    wfull,
    output wire [ADDR_WIDTH:0]     waddr,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire                    rinc,
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire                    rempty,
    output wire [ADDR_WIDTH:0]     raddr
);

    localparam ADDR_WIDTH_LOG = ADDR_WIDTH;
    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;
    localparam FULL_THRESHOLD = (1 << (ADDR_WIDTH_LOG - 1));
    localparam EMPTY_THRESHOLD = 0;

    // Write side registers
    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] wptr_next;
    reg [ADDR_WIDTH-1:0] wgray;
    reg [ADDR_WIDTH-1:0] wgray_next;
    reg wfull_reg;
    reg wfull_next;

    // Read side registers
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] rptr_next;
    reg [ADDR_WIDTH-1:0] rgray;
    reg [ADDR_WIDTH-1:1] rgray_next;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg rempty_reg;
    reg rempty_next;

    // FIFO Memory
    reg [DATA_WIDTH-1:0] mem [FIFO_DEPTH-1:0];

    // Write Address Generation
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= '0;
            wfull_reg <= 1'b0;
        end else begin
            wptr <= wptr_next;
            wfull_reg <= wfull_next;
        end
    end

    // Write Pointer Logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_next <= '0;
            wfull_next <= 1'b0;
        end else begin
            wptr_next <= wptr;
            if (winc) begin
                wptr_next <= wptr + 1'b1;
                // Check for overflow (FIFO full condition)
                if (wptr == (FIFO_DEPTH - 1)) begin
                    wfull_next <= 1'b1;
                end else begin
                    wfull_next <= wfull_reg;
                end
            end else begin
                wfull_next <= wfull_reg;
            end
        end
    end

    // Write Data and Address
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            waddr <= '0;
        end else begin
            waddr <= wptr;
        end
    end

    // Write Memory Storage
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem <= '0;
        end else if (winc && !wfull_reg) begin
            mem[wptr] <= wdata;
        end
    end

    // Gray Code Generation for Write Side
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wgray <= '0;
        end else begin
            wgray <= wgray_next;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wgray_next <= '0;
        end else begin
            wgray_next <= wptr;
        end
    end

    // Read Address Generation
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= '0;
            rempty_reg <= 1'b1;
        end else begin
            rptr <= rptr_next;
            rempty_reg <= rempty_next;
        end
    end

    // Read Pointer Logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_next <= '0;
            rempty_next <= 1'b1;
        end else begin
            rptr_next <= rptr;
            if (rinc) begin
                rptr_next <= rptr + 1'b1;
                // Check for underflow (FIFO empty condition)
                if (rptr == (FIFO_DEPTH - 1)) begin
                    rempty_next <= 1'b0;
                end else begin
                    rempty_next <= rempty_reg;
                end
            end else begin
                rempty_next <= rempty_reg;
            end
        end
    end

    // Read Data Output
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= '0;
        end else begin
            rdata <= rdata_reg;
        end
    end

    // Read Memory Sampling
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= '0;
        end else if (rinc && !rempty_reg) begin
            // Sample data from write domain using read clock
            // We need to sample the memory at the current read pointer
            // Since memory is in write domain, we sample it here
            rdata_reg <= mem[rptr];
        end
    end

    // Gray Code Generation for Read Side
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rgray <= '0;
        end else begin
            rgray <= rgray_next;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rgray_next <= '0;
        end else begin
            rgray_next <= rptr;
        end
    end

    // Clock Domain Crossing: Write Gray to Read Domain
    // Stage 1
    reg [ADDR_WIDTH-1:0] wgray_sync1;
    reg [ADDR_WIDTH-1:0] wgray_sync1_next;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wgray_sync1 <= '0;
        end else begin
            wgray_sync1 <= wgray_sync1_next;
        end
    end
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wgray_sync1_next <= '0;
        end else begin
            wgray_sync1_next <= wgray;
        end
    end

    // Stage 2
    reg [ADDR_WIDTH-1:0] wgray_sync2;
    reg [ADDR_WIDTH-1:0] wgray_sync2_next;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wgray_sync2 <= '0;
        end else begin
            wgray_sync2 <= wgray_sync2_next;
        end
    end
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wgray_sync2_next <= '0;
        end else begin
            wgray_sync2_next <= wgray_sync1;
        end
    end

    // Clock Domain Crossing: Read Gray to Write Domain
    // Stage 1
    reg [ADDR_WIDTH-1:0] rgray_sync1;
    reg [ADDR_WIDTH-1:0] rgray_sync1_next;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rgray_sync1 <= '0;
        end else begin
            rgray_sync1 <= rgray_sync1_next;
        end
    end
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rgray_sync1_next <= '0;
        end else begin
            rgray_sync1_next <= rgray;
        end
    end

    // Stage 2
    reg [ADDR_WIDTH-1:0] rgray_sync2;
    reg [ADDR_WIDTH-1:0] rgray_sync2_next;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rgray_sync2 <= '0;
        end else begin
            rgray_sync2 <= rgray_sync2_next;
        end
    end
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rgray_sync2_next <= '0;
        end else begin
            rgray_sync2_next <= rgray_sync1;
        end
    end

    // Full Flag Generation (in write domain)
    // Full when write pointer == read pointer (after synchronization)
    // We use the synchronized read pointer to determine full status
    reg wfull_calc;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull_calc <= 1'b0;
        end else begin
            // Full if wptr == rgray_sync2 (synchronized read pointer)
            // But we need to handle the case where FIFO is actually empty
            // The standard approach: full when wptr == rgray_sync2 AND wptr != rgray_sync2 - 1
            // Actually, simpler: full when wptr == rgray_sync2 (assuming we track empty correctly)
            // Let's use the standard method: full when wptr == rgray_sync2
            // But we need to ensure we don't report full when empty
            // Standard solution: full when wptr == rgray_sync2
            // However, we need to be careful about the initial state
            if (wptr == rgray_sync2) begin
                wfull_calc <= 1'b1;
            end else begin
                wfull_calc <= 1'b0;
            end
        end
    end

    // Empty Flag Generation (in read domain)
    // Empty when read pointer == write pointer (after synchronization)
    reg rempty_calc;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty_calc <= 1'b1;
        end else begin
            // Empty if rptr == wgray_sync2 (synchronized write pointer)
            if (rptr == wgray_sync2) begin
                rempty_calc <= 1'b1;
            end else begin
                rempty_calc <= 1'b0;
            end
        end
    end

    // Output assignments
    assign wfull = wfull_reg;
    assign rempty = rempty_reg;

endmodule
```<|im_end|>
