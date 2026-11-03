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

    localparam ADDR_WIDTH_1 = ADDR_WIDTH + 1;

    reg [ADDR_WIDTH:0] wptr, rptr;
    reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH) - 1];
    reg wfull_reg, rempty_reg;

    // Write FIFO logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_reg <= 1'b0;
        end else begin
            if (!wfull_reg && winc) begin
                mem[wptr] <= wdata;
                wptr <= (wptr + 1) % (1 << ADDR_WIDTH);
                if (wptr == rptr) begin
                    wfull_reg <= 1'b1;
                end
            end
        end
    end

    // Read FIFO logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rempty_reg <= 1'b1;
        end else begin
            if (!rempty_reg && rinc) begin
                rptr <= (rptr + 1) % (1 << ADDR_WIDTH);
                if (wptr == rptr) begin
                    rempty_reg <= 1'b1;
                end else begin
                    rempty_reg <= 1'b0;
                end
            end
        end
    end

    // Synchronous outputs
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            waddr <= 0;
        end else begin
            waddr <= wptr;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            raddr <= 0;
        end else begin
            raddr <= rptr;
        end
    end

    // Outputs
    assign wfull = wfull_reg;
    assign rempty = rempty_reg;
    assign rdata = mem[rptr];
endmodule
