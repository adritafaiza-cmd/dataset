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
    reg [ADDR_WIDTH:0]             wptr, rptr, wptr_sync, rptr_sync;
    reg [ADDR_WIDTH:0]             wptr_gray, rptr_gray, wptr_sync_gray, rptr_sync_gray;
    reg [SYNC_STAGES-1:0]          wptr_sync_pipe, rptr_sync_pipe;
    reg [SYNC_STAGES-1:0]          wptr_gray_sync_pipe, rptr_gray_sync_pipe;
    reg                            wfull_int, rempty_int;
    reg                            winc_d, rinc_d;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wfull_int <= 0;
            winc_d <= 0;
        end else if (winc && ~wfull_int) begin
            wptr <= wptr + 1;
            wptr_gray <= (wptr[ADDR_WIDTH-1:1] << 1) | wptr[0];
            winc_d <= 1;
        end else begin
            winc_d <= 0;
        end
    end

    always @(posedge wclk) begin
        if (winc && ~wfull_int) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rempty_int <= 1;
            rinc_d <= 0;
        end else if (rinc && ~rempty_int) begin
            rptr <= rptr + 1;
            rptr_gray <= (rptr[ADDR_WIDTH-1:1] << 1) | rptr[0];
            rinc_d <= 1;
        end else begin
            rinc_d <= 0;
        end
    end

    always @(posedge rclk) begin
        if (rinc && ~rempty_int) begin
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
        end
    end

    always @(posedge wclk) begin
        wptr_sync_pipe[0] <= wptr[ADDR_WIDTH];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_sync_pipe[i] <= wptr_sync_pipe[i-1];
        end
        wptr_sync <= {wptr_sync_pipe[SYNC_STAGES-1], wptr[ADDR_WIDTH-1:0]};
    end

    always @(posedge rclk) begin
        rptr_sync_pipe[0] <= rptr[ADDR_WIDTH];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_sync_pipe[i] <= rptr_sync_pipe[i-1];
        end
        rptr_sync <= {rptr_sync_pipe[SYNC_STAGES-1], rptr[ADDR_WIDTH-1:0]};
    end

    always @(posedge wclk) begin
        wptr_gray_sync_pipe[0] <= wptr_gray[ADDR_WIDTH];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            wptr_gray_sync_pipe[i] <= wptr_gray_sync_pipe[i-1];
        end
        wptr_sync_gray <= {wptr_gray_sync_pipe[SYNC_STAGES-1], wptr_gray[ADDR_WIDTH-1:0]};
    end

    always @(posedge rclk) begin
        rptr_gray_sync_pipe[0] <= rptr_gray[ADDR_WIDTH];
        for (int i = 1; i < SYNC_STAGES; i++) begin
            rptr_gray_sync_pipe[i] <= rptr_gray_sync_pipe[i-1];
        end
        rptr_sync_gray <= {rptr_gray_sync_pipe[SYNC_STAGES-1], rptr_gray[ADDR_WIDTH-1:0]};
    end

    always @(posedge wclk) begin
        if (wptr_sync_gray == (rptr_sync_gray + 1)) begin
            wfull_int <= 1;
        end else if (wptr_sync_gray == rptr_sync_gray) begin
            wfull_int <= 0;
        end
    end

    always @(posedge rclk) begin
        if (rptr_sync_gray == wptr_sync_gray) begin
            rempty_int <= 1;
        end else begin
            rempty_int <= 0;
        end
    end

    assign wfull = wfull_int;
    assign waddr = wptr;
    assign rdata = mem[rptr[ADDR_WIDTH-1:0]];
    assign rempty = rempty_int;
    assign raddr = rptr;

endmodule
