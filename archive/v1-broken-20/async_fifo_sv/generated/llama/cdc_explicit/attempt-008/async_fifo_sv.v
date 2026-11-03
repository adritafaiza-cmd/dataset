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

    reg [ADDR_WIDTH-1:0] wptr, rptr;
    reg [ADDR_WIDTH:0] wcnt, rcnt;
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    reg [SYNC_STAGES-1:0] wsync, rsync;
    reg wfull_int, rempty_int;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wcnt <= 0;
            wsync <= 0;
            wfull_int <= 0;
        end else if (winc && ~wfull_int) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            wcnt <= wcnt + 1;
            wsync[0] <= 1;
        end else if (~winc) begin
            wsync[0] <= 0;
        end
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wsync[i] <= wsync[i-1];
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rcnt <= 0;
            rsync <= 0;
            rempty_int <= 1;
        end else if (rinc && ~rempty_int) begin
            rptr <= rptr + 1;
            rcnt <= rcnt - 1;
            rsync[0] <= 1;
        end else if (~rinc) begin
            rsync[0] <= 0;
        end
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rsync[i] <= rsync[i-1];
        end
    end

    assign wfull = wfull_int;
    assign rempty = rempty_int;
    assign waddr = {wcnt, wptr};
    assign raddr = {rcnt, rptr};

    always @(posedge wclk) begin
        if (wcnt == (2**ADDR_WIDTH)-1) begin
            wfull_int <= 1;
        end else if (wcnt == rcnt) begin
            wfull_int <= 0;
        end
    end

    always @(posedge rclk) begin
        if (rcnt == 0) begin
            rempty_int <= 1;
        end else if (rcnt == wcnt) begin
            rempty_int <= 0;
        end
    end

    always @(posedge rclk) begin
        if (~rempty_int) begin
            rdata <= mem[rptr];
        end
    end

endmodule
