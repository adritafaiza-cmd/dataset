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

    localparam DEPTH = 2**ADDR_WIDTH;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wptr, rptr;
    reg wfull_int, rempty_int;

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_int <= 0;
        end else begin
            if (winc && !wfull_int) begin
                mem[wptr] <= wdata;
                wptr <= (wptr + 1) % DEPTH;
                if (wptr == rptr)
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
                rptr <= (rptr + 1) % DEPTH;
                if (wptr == rptr)
                    rempty_int <= 1;
            end
        end
    end

    // Output logic
    assign waddr = wptr;
    assign raddr = rptr;
    assign wfull = wfull_int;
    assign rempty = rempty_int;
    assign rdata = mem[rptr];

endmodule
