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

    reg [ADDR_WIDTH-1:0] wptr;
    reg [ADDR_WIDTH-1:0] rptr;
    reg [ADDR_WIDTH:0]   waddr_reg;
    reg [ADDR_WIDTH:0]   raddr_reg;
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    reg [SYNC_STAGES-1:0] wptr_sync;
    reg [SYNC_STAGES-1:0] rptr_sync;
    reg [SYNC_STAGES-1:0] wfull_sync;
    reg [SYNC_STAGES-1:0] rempty_sync;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            waddr_reg <= 0;
            wfull_sync <= 0;
        end else if (winc && ~wfull_sync[SYNC_STAGES-1]) begin
            wptr <= wptr + 1;
            waddr_reg <= waddr_reg + 1;
            mem[wptr] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            raddr_reg <= 0;
            rempty_sync <= 1;
        end else if (rinc && ~rempty_sync[SYNC_STAGES-1]) begin
            rptr <= rptr + 1;
            raddr_reg <= raddr_reg + 1;
        end
    end

    always @(posedge wclk) begin
        wptr_sync[0] <= wptr;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    always @(posedge rclk) begin
        rptr_sync[0] <= rptr;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    always @(posedge wclk) begin
        wfull_sync[0] <= (waddr_reg == (2**ADDR_WIDTH-1));
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wfull_sync[i] <= wfull_sync[i-1];
        end
    end

    always @(posedge rclk) begin
        rempty_sync[0] <= (raddr_reg == waddr_reg);
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rempty_sync[i] <= rempty_sync[i-1];
        end
    end

    assign wfull = wfull_sync[SYNC_STAGES-1];
    assign waddr = waddr_reg;
    assign rdata = mem[rptr_sync[SYNC_STAGES-1]];
    assign rempty = rempty_sync[SYNC_STAGES-1];
    assign raddr = raddr_reg;

endmodule
