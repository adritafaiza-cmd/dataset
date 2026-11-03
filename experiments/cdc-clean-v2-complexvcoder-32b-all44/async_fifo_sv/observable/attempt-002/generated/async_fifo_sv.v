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
    reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];
    reg [ADDR_WIDTH:0] wptr, wptr_next, wptr_gray, wptr_gray_sync;
    reg [ADDR_WIDTH:0] rptr, rptr_next, rptr_gray, rptr_gray_sync;
    reg wfull_int, rempty_int;

    // Write side logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wptr_gray_sync <= 0;
            wfull_int <= 1;
            wptr_next <= 0;
            for (integer i = 0; i < (2**ADDR_WIDTH); i = i + 1) begin
                mem[i] <= 0;
            end
        end else begin
            wptr_next <= wptr + 1;
            wptr_gray <= wptr ^ (wptr >> 1);
            if (winc && !wfull_int) begin
                mem[wptr] <= wdata;
                wptr <= wptr_next;
            end
            wfull_int <= (wptr_next == rptr_gray_sync);
        end
    end

    // Read side logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rptr_gray_sync <= 0;
            rempty_int <= 1;
            rptr_next <= 0;
        end else begin
            rptr_next <= rptr + 1;
            rptr_gray <= rptr ^ (rptr >> 1);
            if (rinc && !rempty_int) begin
                rptr <= rptr_next;
            end
            rempty_int <= (wptr_gray_sync == rptr);
        end
    end

    // Synchronization of read pointer to write domain
    sync_register #(.DATA_WIDTH(ADDR_WIDTH+1)) sync_rptr_gray (
        .din(rptr_gray),
        .dout(rptr_gray_sync),
        .clk(wclk),
        .rst_n(wrst_n)
    );

    // Synchronization of write pointer to read domain
    sync_register #(.DATA_WIDTH(ADDR_WIDTH+1)) sync_wptr_gray (
        .din(wptr_gray),
        .dout(wptr_gray_sync),
        .clk(rclk),
        .rst_n(rrst_n)
    );

    // Outputs
    assign wfull = wfull_int;
    assign waddr = wptr;
    assign rdata = mem[rptr];
    assign rempty = rempty_int;
    assign raddr = rptr;

endmodule

module sync_register #(
    parameter DATA_WIDTH = 9
)(
    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] dout,
    input  wire                  clk,
    input  wire                  rst_n
);

    reg [DATA_WIDTH-1:0] reg1, reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg1 <= 0;
            reg2 <= 0;
            dout <= 0;
        end else begin
            reg1 <= din;
            reg2 <= reg1;
            dout <= reg2;
        end
    end

endmodule
