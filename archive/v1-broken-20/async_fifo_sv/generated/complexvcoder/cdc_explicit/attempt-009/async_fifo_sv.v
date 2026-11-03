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

    localparam FIFO_DEPTH = 1 << ADDR_WIDTH;

    // Internal signals
    reg [DATA_WIDTH-1:0] mem[FIFO_DEPTH-1:0];
    reg [ADDR_WIDTH:0] wptr, rptr;
    reg wfull_int, rempty_int;

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_int <= 0;
        end else begin
            if (winc && !wfull_int) begin
                mem[wptr] <= wdata;
                wptr <= wptr + 1;
                if (wptr == FIFO_DEPTH - 1)
                    wfull_int <= 1;
            end
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rempty_int <= 1;
        end else begin
            if (rinc && !rempty_int) begin
                rptr <= rptr + 1;
                if (rptr == FIFO_DEPTH)
                    rempty_int <= 0;
            end
        end
    end

    // Address outputs
    assign waddr = wptr;
    assign raddr = rptr;

    // Full and empty outputs
    assign wfull = wfull_int;
    assign rempty = rempty_int;

    // Data output
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata <= 0;
        else if (!rempty_int)
            rdata <= mem[rptr];
    end

endmodule
