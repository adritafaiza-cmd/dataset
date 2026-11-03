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

    // Write Domain
    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] wptr_next;
    reg [ADDR_WIDTH-1:0] wptr_gray;
    reg [ADDR_WIDTH-1:0] wptr_gray_next;
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];

    // Read Domain
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH-1:0] rptr_next;
    reg [ADDR_WIDTH-1:0] rptr_gray;
    reg [ADDR_WIDTH-1:0] rptr_gray_next;

    // Synchronization
    reg [SYNC_STAGES-1:0] wptr_sync;
    reg [SYNC_STAGES-1:0] rptr_sync;

    // Flags
    reg wfull_reg;
    reg rempty_reg;

    // Reset
    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wfull_reg <= 0;
        end else if (winc && ~wfull_reg) begin
            wptr <= wptr + 1;
            wptr_gray <= wptr_gray + 1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rempty_reg <= 1;
        end else if (rinc && ~rempty_reg) begin
            rptr <= rptr + 1;
            rptr_gray <= rptr_gray + 1;
        end
    end

    // Synchronization Logic
    always @(posedge wclk) begin
        wptr_sync[0] <= wptr_gray[ADDR_WIDTH-1];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    always @(posedge rclk) begin
        rptr_sync[0] <= rptr_gray[ADDR_WIDTH-1];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    // Gray Code Conversion
    always @(*) begin
        wptr_gray_next = (wptr >> 1) ^ wptr;
        rptr_gray_next = (rptr >> 1) ^ rptr;
    end

    always @(posedge wclk) begin
        wptr_gray <= wptr_gray_next;
    end

    always @(posedge rclk) begin
        rptr_gray <= rptr_gray_next;
    end

    // Full and Empty Flags
    always @(posedge wclk) begin
        if (~wrst_n) begin
            wfull_reg <= 0;
        end else if (winc && (wptr_gray == {ADDR_WIDTH{1'b1}})) begin
            wfull_reg <= 1;
        end else if (~winc && (wptr_gray != {ADDR_WIDTH{1'b1}})) begin
            wfull_reg <= 0;
        end
    end

    always @(posedge rclk) begin
        if (~rrst_n) begin
            rempty_reg <= 1;
        end else if (rinc && (rptr_gray == 0)) begin
            rempty_reg <= 1;
        end else if (~rinc && (rptr_gray != 0)) begin
            rempty_reg <= 0;
        end
    end

    // Memory Write
    always @(posedge wclk) begin
        if (winc && ~wfull_reg) begin
            mem[wptr] <= wdata;
        end
    end

    // Memory Read
    always @(posedge rclk) begin
        if (rinc && ~rempty_reg) begin
            rdata <= mem[rptr];
        end
    end

    // Outputs
    assign wfull = wfull_reg;
    assign waddr = {1'b0, wptr};
    assign rempty = rempty_reg;
    assign raddr = {1'b0, rptr};

endmodule
