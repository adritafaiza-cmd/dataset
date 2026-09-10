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
    reg [ADDR_WIDTH:0]  waddr_int;
    reg [ADDR_WIDTH:0]  raddr_int;
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] rdata_int;
    reg                    wfull_int;
    reg                    rempty_int;

    assign wfull = wfull_int;
    assign waddr = waddr_int;
    assign rdata = rdata_int;
    assign rempty = rempty_int;
    assign raddr = raddr_int;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            waddr_int <= 0;
            wfull_int <= 0;
        end else if (winc && ~wfull_int) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            waddr_int <= waddr_int + 1;
            if (wptr == (2**ADDR_WIDTH - 1)) begin
                wfull_int <= 1;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            raddr_int <= 0;
            rempty_int <= 1;
        end else if (rinc && ~rempty_int) begin
            rdata_int <= mem[rptr];
            rptr <= rptr + 1;
            raddr_int <= raddr_int + 1;
            if (rptr == (2**ADDR_WIDTH - 1)) begin
                rempty_int <= 1;
            end
        end
    end

    // CDC for wfull
    reg [SYNC_STAGES-1:0] wfull_sync;
    always @(posedge rclk) begin
        wfull_sync[0] <= wfull_int;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wfull_sync[i] <= wfull_sync[i-1];
        end
    end
    assign rempty_int = (rptr == wptr) && ~wfull_sync[SYNC_STAGES-1];

    // CDC for rempty
    reg [SYNC_STAGES-1:0] rempty_sync;
    always @(posedge wclk) begin
        rempty_sync[0] <= rempty_int;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rempty_sync[i] <= rempty_sync[i-1];
        end
    end
    assign wfull_int = (wptr == rptr) && rempty_sync[SYNC_STAGES-1];

    // CDC for rdata
    reg [DATA_WIDTH-1:0] rdata_sync [SYNC_STAGES-1:0];
    always @(posedge rclk) begin
        rdata_sync[0] <= mem[rptr];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rdata_sync[i] <= rdata_sync[i-1];
        end
    end
    assign rdata_int = rdata_sync[SYNC_STAGES-1];

endmodule
