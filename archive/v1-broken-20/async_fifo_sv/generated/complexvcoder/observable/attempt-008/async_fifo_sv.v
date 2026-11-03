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
    localparam ADDR_WIDTH_OUT = ADDR_WIDTH + 1;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wptr, rptr;
    reg wfull_reg, rempty_reg;

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_reg <= 0;
        end else begin
            if (!wfull_reg && winc) begin
                mem[wptr] <= wdata;
                wptr <= wptr + 1;
                wfull_reg <= (wptr == (DEPTH - 1));
            end
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rempty_reg <= 1;
        end else begin
            if (!rempty_reg && rinc) begin
                rptr <= rptr + 1;
                rempty_reg <= (rptr == wptr);
            end
        end
    end

    // Output logic
    assign waddr = {wptr, wfull_reg};
    assign raddr = {rptr, rempty_reg};
    assign wfull = wfull_reg;
    assign rempty = rempty_reg;
    assign rdata = mem[rptr];

endmodule
