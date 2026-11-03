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
    wire [ADDR_WIDTH:0] wptr, wptr_next, wptr_gray, wptr_gray_sync_w;
    wire [ADDR_WIDTH:0] rptr, rptr_next, rptr_gray, rptr_gray_sync_r;
    wire write_enable, read_enable;
    wire [DATA_WIDTH-1:0] fifo_memory [0:(2**(ADDR_WIDTH+1)-1)];
    wire wfull_logic, rempty_logic;

    // Binary to Gray code conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary code conversion
    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        reg [ADDR_WIDTH:0] bin;
        begin
            bin = gray;
            for (i = ADDR_WIDTH-1; i >= 0; i = i - 1) begin
                bin[i] = bin[i+1] ^ gray[i];
            end
            gray_to_bin = bin;
        end
    endfunction

    // Write Domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (write_enable) begin
            wptr <= wptr_next;
        end
    end

    always @(posedge wclk) begin
        if (write_enable) begin
            fifo_memory[wptr_next] <= wdata;
        end
    end

    assign wptr_gray = bin_to_gray(wptr);
    assign wptr_next = wptr + 1;

    // Read Domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (read_enable) begin
            rptr <= rptr_next;
        end
    end

    assign rptr_gray = bin_to_gray(rptr);
    assign rptr_next = rptr + 1;

    // Synchronization flops
    sync_flop #(.WIDTH(ADDR_WIDTH+1)) sync_rptr_gray_w (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(rptr_gray),
        .dout(wptr_gray_sync_w)
    );

    sync_flop #(.WIDTH(ADDR_WIDTH+1)) sync_wptr_gray_r (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(wptr_gray),
        .dout(rptr_gray_sync_r)
    );

    // Full and Empty Logic
    assign wfull_logic = (wptr_gray + 1) == wptr_gray_sync_w;
    assign rempty_logic = wptr_gray_sync_r == rptr_gray;

    // Write enable and read enable
    assign write_enable = winc && !wfull_logic;
    assign read_enable = rinc && !rempty_logic;

    // Outputs
    assign wfull = wfull_logic;
    assign rempty = rempty_logic;
    assign waddr = wptr_gray;
    assign raddr = rptr_gray;
    assign rdata = fifo_memory[rptr];

endmodule

// Synchronization flop module
module sync_flop #(
    parameter WIDTH = 1
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg <= {SYNC_STAGES{WIDTH{1'b0}}};
        end else begin
            sync_reg[0] <= din;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign dout = sync_reg[SYNC_STAGES-1];

endmodule
