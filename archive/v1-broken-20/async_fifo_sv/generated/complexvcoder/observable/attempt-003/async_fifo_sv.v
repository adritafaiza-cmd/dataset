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
    reg [DATA_WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];
    reg [ADDR_WIDTH:0] wptr, rptr;
    reg wfull_sync, rempty_sync;
    reg [ADDR_WIDTH:0] waddr_sync, raddr_sync;

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_sync <= 0;
        end else begin
            if (winc && !wfull_sync) begin
                mem[wptr] <= wdata;
                wptr <= wptr + 1;
                if (wptr == 2**ADDR_WIDTH - 1) begin
                    wfull_sync <= 1;
                end
            end
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rempty_sync <= 1;
        end else begin
            if (rinc && !rempty_sync) begin
                rptr <= rptr + 1;
                if (rptr == 2**ADDR_WIDTH) begin
                    rempty_sync <= 0;
                end
            end
        end
    end

    // Address and data output
    assign waddr = wptr + 1;
    assign raddr = rptr + 1;
    assign wfull = wfull_sync;
    assign rempty = rempty_sync;
    assign rdata = mem[rptr];

    // Sync FFs for flags
    sync_ff #(.WIDTH(1)) sync_wfull (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .din(wfull_sync),
        .dout(wfull)
    );

    sync_ff #(.WIDTH(1)) sync_rempty (
        .wclk(rclk),
        .wrst_n(rrst_n),
        .din(rempty_sync),
        .dout(rempty)
    );

endmodule

module sync_ff #(
    parameter WIDTH = 1
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire [WIDTH-1:0]        din,
    output wire [WIDTH-1:0]        dout
);

    reg [WIDTH-1:0] q;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            q <= {WIDTH{1'b0}};
        end else begin
            q <= din;
        end
    end

    assign dout = q;

endmodule
