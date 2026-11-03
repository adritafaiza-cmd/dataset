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

    wire [ADDR_WIDTH:0] gray_wptr, gray_rptr, gray_wptr_rsync, gray_rptr_wsync;
    wire [ADDR_WIDTH:0] bin_wptr, bin_rptr;

    sync_fifo_ctrl write_ctrl (
        .clk       (wclk),
        .rst_n     (wrst_n),
        .inc       (winc),
        .full      (wfull),
        .addr      (waddr),
        .gray_ptr  (gray_wptr),
        .bin_ptr   (bin_wptr)
    );

    sync_fifo_ctrl read_ctrl (
        .clk       (rclk),
        .rst_n     (rrst_n),
        .inc       (rinc),
        .full      (rempty),
        .addr      (raddr),
        .gray_ptr  (gray_rptr),
        .bin_ptr   (bin_rptr)
    );

    gray_counter gray_counter_w (
        .bin       (bin_wptr),
        .gray      (gray_wptr)
    );

    gray_counter gray_counter_r (
        .bin       (bin_rptr),
        .gray      (gray_rptr)
    );

    binary_counter binary_counter_w (
        .gray      (gray_wptr),
        .bin       (bin_wptr)
    );

    binary_counter binary_counter_r (
        .gray      (gray_rptr),
        .bin       (bin_rptr)
    );

    fifo_memory fifo_mem (
        .wclk      (wclk),
        .wrst_n    (wrst_n),
        .winc      (winc),
        .wdata     (wdata),
        .gray_wptr (gray_wptr),
        .gray_rptr (gray_rptr_wsync),
        .rdata     (rdata)
    );

    sync_bits sync_wptr (
        .src_clk   (wclk),
        .dst_clk   (rclk),
        .bits      (gray_wptr),
        .sync_bits (gray_wptr_rsync)
    );

    sync_bits sync_rptr (
        .src_clk   (rclk),
        .dst_clk   (wclk),
        .bits      (gray_rptr),
        .sync_bits (gray_rptr_wsync)
    );

endmodule

module sync_fifo_ctrl (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    inc,
    output wire                    full,
    output wire [ADDR_WIDTH:0]     addr,
    output wire [ADDR_WIDTH:0]     gray_ptr,
    input  wire [ADDR_WIDTH:0]     bin_ptr
);

    reg [ADDR_WIDTH:0] addr_reg;
    reg [ADDR_WIDTH:0] gray_ptr_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= 0;
            gray_ptr_reg <= 0;
        end else begin
            if (inc) begin
                addr_reg <= addr_reg + 1;
                gray_ptr_reg <= (addr_reg + 1) ^ ((addr_reg + 1) >> 1);
            end
        end
    end

    assign full = (gray_ptr_reg == {bin_ptr[ADDR_WIDTH-1:0], ~bin_ptr[ADDR_WIDTH]});
    assign addr = addr_reg;
    assign gray_ptr = gray_ptr_reg;

endmodule

module gray_counter (
    input  wire [ADDR_WIDTH:0]     bin,
    output wire [ADDR_WIDTH:0]     gray
);

    assign gray = bin ^ (bin >> 1);

endmodule

module binary_counter (
    input  wire [ADDR_WIDTH:0]     gray,
    output wire [ADDR_WIDTH:0]     bin
);

    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        begin
            gray_to_bin = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH - 1; i >= 0; i = i - 1) begin
                gray_to_bin[i] = gray_to_bin[i + 1] ^ gray[i];
            end
        end
    endfunction

    assign bin = gray_to_bin(gray);

endmodule

module fifo_memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire [ADDR_WIDTH:0]     gray_wptr,
    input  wire [ADDR_WIDTH:0]     gray_rptr,
    output wire [DATA_WIDTH-1:0]   rdata
);

    reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];
    reg [ADDR_WIDTH:0] waddr_reg;
    reg [ADDR_WIDTH:0] raddr_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            waddr_reg <= 0;
        end else if (winc) begin
            waddr_reg <= gray_to_bin(gray_wptr);
            mem[waddr_reg] <= wdata;
        end
    end

    always @(posedge rclk or negedge wrst_n) begin
        if (!wrst_n) begin
            raddr_reg <= 0;
        end else if (rinc) begin
            raddr_reg <= gray_to_bin(gray_rptr);
        end
    end

    assign rdata = mem[raddr_reg];

    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        integer i;
        begin
            gray_to_bin = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH - 1; i >= 0; i = i - 1) begin
                gray_to_bin[i] = gray_to_bin[i + 1] ^ gray[i];
            end
        end
    endfunction

endmodule

module sync_bits #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                    src_clk,
    input  wire                    dst_clk,
    input  wire [ADDR_WIDTH:0]     bits,
    output reg  [ADDR_WIDTH:0]     sync_bits
);

    reg [ADDR_WIDTH:0] sync_bits_reg [SYNC_STAGES-1:0];

    always @(posedge src_clk) begin
        sync_bits_reg[0] <= bits;
        for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
            sync_bits_reg[i] <= sync_bits_reg[i-1];
        end
    end

    always @(posedge dst_clk) begin
        sync_bits <= sync_bits_reg[SYNC_STAGES-1];
    end

endmodule
