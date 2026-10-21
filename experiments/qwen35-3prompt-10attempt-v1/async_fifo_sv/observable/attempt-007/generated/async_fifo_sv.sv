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
    localparam FULL_THRESHOLD = (FIFO_DEPTH - 1);
    localparam EMPTY_THRESHOLD = 0;

    // Write side registers
    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] wptr_next;
    reg [ADDR_WIDTH-1:0] wfull_reg;
    reg [ADDR_WIDTH-1:0] wgray;
    reg [ADDR_WIDTH-1:0] wgray_next;

    // Read side registers
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] rptr_next;
    reg [ADDR_WIDTH-1:0] rempty_reg;
    reg [ADDR_WIDTH-1:0] rgray;
    reg [ADDR_WIDTH-1:1] rgray_next;
    reg [DATA_WIDTH-1:0] rdata_reg;

    // FIFO Memory
    reg [DATA_WIDTH-1:0] mem [FIFO_DEPTH-1:0];

    // Write Address (Gray encoded for stability)
    assign waddr = {1'b0, wgray};

    // Read Address (Gray encoded for stability)
    assign raddr = {1'b0, rgray};

    // Write Logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= '0;
            wfull_reg <= '0;
            wgray <= '0;
        end else begin
            wptr_next <= wptr;
            wgray_next <= wptr_next;
            wfull_reg <= wfull_reg;
        end
    end

    // Full Flag Logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull <= '0;
        end else begin
            wfull <= wfull_reg;
        end
    end

    // Write Pointer Update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= '0;
        end else if (winc && !wfull) begin
            wptr <= wptr + 1;
        end
    end

    // Write Data and Gray Pointer Update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wgray <= '0;
            mem[wptr] <= '0;
        end else if (winc && !wfull) begin
            wgray <= wgray_next;
            mem[wptr] <= wdata;
        end
    end

    // Read Logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= '0;
            rempty_reg <= '0;
            rgray <= '0;
            rdata_reg <= '0;
        end else begin
            rptr_next <= rptr;
            rgray_next <= rptr_next;
            rempty_reg <= rempty_reg;
            rdata_reg <= rdata_reg;
        end
    end

    // Empty Flag Logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty <= '1;
        end else begin
            rempty <= rempty_reg;
        end
    end

    // Read Pointer Update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= '0;
        end else if (rinc && !rempty_reg) begin
            rptr <= rptr + 1;
        end
    end

    // Read Data and Gray Pointer Update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rgray <= '0;
            rdata_reg <= '0;
        end else if (rinc && !rempty_reg) begin
            rgray <= rgray_next;
            rdata_reg <= mem[rptr];
        end
    end

    // Clock Domain Crossing: Write Pointer to Read Side (Gray Encoded)
    wire [ADDR_WIDTH-1:0] wgray_synced;
    wire [ADDR_WIDTH-1:0] wgray_synced_1;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wgray_synced <= '0;
            wgray_synced_1 <= '0;
        end else begin
            wgray_synced <= wgray;
            wgray_synced_1 <= wgray_synced;
        end
    end

    // Clock Domain Crossing: Read Pointer to Write Side (Gray Encoded)
    wire [ADDR_WIDTH-1:0] rgray_synced;
    wire [ADDR_WIDTH-1:0] rgray_synced_1;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rgray_synced <= '0;
            rgray_synced_1 <= '0;
        end else begin
            rgray_synced <= rgray;
            rgray_synced_1 <= rgray_synced;
        end
    end

    // Full Flag Synchronization (Write Side to Read Side)
    wire [ADDR_WIDTH-1:0] wfull_synced;
    wire [ADDR_WIDTH-1:0] wfull_synced_1;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wfull_synced <= '0;
            wfull_synced_1 <= '0;
        end else begin
            wfull_synced <= wfull;
            wfull_synced_1 <= wfull_synced;
        end
    end

    // Empty Flag Synchronization (Read Side to Write Side)
    wire [ADDR_WIDTH-1:0] rempty_synced;
    wire [ADDR_WIDTH-1:0] rempty_synced_1;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rempty_synced <= '1;
            rempty_synced_1 <= '1;
        end else begin
            rempty_synced <= rempty;
            rempty_synced_1 <= rempty_synced;
        end
    end

    // Full Logic on Write Side using Synchronized Empty Flag
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull <= '0;
        end else begin
            // Full if write pointer equals read pointer (after sync)
            wfull <= (wptr == rgray_synced_1);
        end
    end

    // Empty Logic on Read Side using Synchronized Full Flag
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty <= '1;
        end else begin
            // Empty if read pointer equals write pointer (after sync)
            rempty <= (rptr == wgray_synced_1);
        end
    end

endmodule
```<|im_end|>
