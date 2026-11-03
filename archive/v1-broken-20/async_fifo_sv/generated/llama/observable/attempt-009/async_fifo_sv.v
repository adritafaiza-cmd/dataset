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

    reg [DATA_WIDTH-1:0]           mem [2**ADDR_WIDTH-1:0];
    reg [ADDR_WIDTH-1:0]           wptr;
    reg [ADDR_WIDTH-1:0]           rptr;
    reg [ADDR_WIDTH:0]             wcnt;
    reg [ADDR_WIDTH:0]             rcnt;
    reg [ADDR_WIDTH:0]             sync_wcnt [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH:0]             sync_rcnt [SYNC_STAGES-1:0];

    assign wfull = (wcnt == (2**ADDR_WIDTH)-1);
    assign rempty = (rcnt == 0);

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wcnt <= 0;
        end else if (winc && ~wfull) begin
            mem[wptr] <= wdata;
            wptr <= (wptr + 1) % (2**ADDR_WIDTH);
            wcnt <= wcnt + 1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rcnt <= 0;
            rdata <= 0;
        end else if (rinc && ~rempty) begin
            rdata <= mem[rptr];
            rptr <= (rptr + 1) % (2**ADDR_WIDTH);
            rcnt <= rcnt - 1;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            sync_wcnt[0] <= 0;
        end else begin
            sync_wcnt[0] <= wcnt;
        end
    end

    always @(posedge rclk) begin
        for (int i = 0; i < SYNC_STAGES-1; i++) begin
            sync_wcnt[i+1] <= sync_wcnt[i];
        end
        waddr <= sync_wcnt[SYNC_STAGES-1];
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            sync_rcnt[0] <= 0;
        end else begin
            sync_rcnt[0] <= rcnt;
        end
    end

    always @(posedge wclk) begin
        for (int i = 0; i < SYNC_STAGES-1; i++) begin
            sync_rcnt[i+1] <= sync_rcnt[i];
        end
        raddr <= sync_rcnt[SYNC_STAGES-1];
    end

endmodule
