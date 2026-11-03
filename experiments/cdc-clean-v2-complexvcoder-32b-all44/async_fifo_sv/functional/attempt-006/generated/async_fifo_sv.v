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

    // Internal signals
    wire [ADDR_WIDTH:0] wptr;
    wire [ADDR_WIDTH:0] rptr;
    wire [ADDR_WIDTH:0] rptr_w;
    wire [ADDR_WIDTH:0] wptr_r;
    wire full;
    wire empty;
    wire [DATA_WIDTH-1:0] mem [2**(ADDR_WIDTH)-1:0];

    // Core logic for the asynchronous FIFO
    async_fifo_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_core (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wdata(wdata),
        .wfull(wfull),
        .waddr(waddr),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc),
        .rdata(rdata),
        .rempty(rempty),
        .raddr(raddr),
        .wptr(wptr),
        .rptr(rptr),
        .rptr_w(rptr_w),
        .wptr_r(wptr_r),
        .full(full),
        .empty(empty),
        .mem(mem)
    );

endmodule

module async_fifo_core #(
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
    output wire [ADDR_WIDTH:0]     raddr,
    output wire [ADDR_WIDTH:0]     wptr,
    output wire [ADDR_WIDTH:0]     rptr,
    input  wire [ADDR_WIDTH:0]     rptr_w,
    input  wire [ADDR_WIDTH:0]     wptr_r,
    output wire                    full,
    output wire                    empty,
    inout  wire [DATA_WIDTH-1:0]   mem [2**(ADDR_WIDTH)-1:0]
);

    // Internal signals
    reg [ADDR_WIDTH:0] wptr_reg;
    reg [ADDR_WIDTH:0] rptr_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_reg <= 0;
        end else if (winc && !full) begin
            wptr_reg <= wptr_reg + 1;
        end
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_reg <= 0;
        end else if (rinc && !empty) begin
            rptr_reg <= rptr_reg + 1;
        end
    end

    // Write data to memory
    always @(posedge wclk) begin
        if (winc && !full) begin
            mem[wptr_reg[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Read data from memory
    always @(posedge rclk) begin
        if (rinc && !empty) begin
            rdata_reg <= mem[rptr_reg[ADDR_WIDTH-1:0]];
        end
    end

    // Full flag logic
    assign full = (wptr_reg + 1) == rptr_w;

    // Empty flag logic
    assign empty = wptr_r == rptr_reg;

    // Output assignments
    assign waddr = wptr_reg;
    assign raddr = rptr_reg;
    assign rdata = rdata_reg;

    // Synchronize write pointer to read domain
    sync_fifo #(
        .DATA_WIDTH(ADDR_WIDTH+1),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_fifo_w2r (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .din(wptr_reg),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .dout(rptr_w)
    );

    // Synchronize read pointer to write domain
    sync_fifo #(
        .DATA_WIDTH(ADDR_WIDTH+1),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_fifo_r2w (
        .wclk(rclk),
        .wrst_n(rrst_n),
        .din(rptr_reg),
        .rclk(wclk),
        .rrst_n(wrst_n),
        .dout(wptr_r)
    );

endmodule

module sync_fifo #(
    parameter DATA_WIDTH = 5,
    parameter SYNC_STAGES = 2
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire [DATA_WIDTH-1:0]   din,
    input  wire                    rclk,
    input  wire                    rrst_n,
    output reg [DATA_WIDTH-1:0]    dout
);

    // Internal signals
    reg [DATA_WIDTH-1:0] sync_reg [SYNC_STAGES-1:0];

    // Synchronize din to read domain rclk using a series of flip-flops
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            dout <= 0;
            sync_reg <= 0;
        end else begin
            sync_reg[0] <= din;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
            dout <= sync_reg[SYNC_STAGES-1];
        end
    end

endmodule
