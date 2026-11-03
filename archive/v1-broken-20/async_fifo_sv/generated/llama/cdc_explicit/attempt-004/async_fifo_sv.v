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
    reg [ADDR_WIDTH:0]  wcnt;
    reg [ADDR_WIDTH:0]  rcnt;
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] rdata_reg;

    assign wfull = (wcnt == (2**ADDR_WIDTH-1));
    assign rempty = (wcnt == 0);
    assign waddr = {1'b0, wptr};
    assign raddr = {1'b0, rptr};

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wcnt <= 0;
        end else if (winc && ~wfull) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            wcnt <= wcnt + 1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rcnt <= 0;
            rdata_reg <= 0;
        end else if (rinc && ~rempty) begin
            rdata_reg <= mem[rptr];
            rptr <= rptr + 1;
            rcnt <= rcnt + 1;
        end
    end

    assign rdata = rdata_reg;

    // CDC for wcnt
    reg [SYNC_STAGES-1:0] wcnt_sync;
    always @(posedge rclk) begin
        wcnt_sync[0] <= wcnt;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wcnt_sync[i] <= wcnt_sync[i-1];
        end
    end
    assign rcnt <= wcnt_sync[SYNC_STAGES-1];

    // CDC for rptr
    reg [SYNC_STAGES-1:0] rptr_sync;
    always @(posedge wclk) begin
        rptr_sync[0] <= rptr;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync[i] <= rptr_sync[i-1];
        end
    end
    assign wptr <= rptr_sync[SYNC_STAGES-1];

endmodule
