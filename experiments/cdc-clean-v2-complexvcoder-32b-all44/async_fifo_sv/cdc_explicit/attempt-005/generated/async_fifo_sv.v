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
    wire [ADDR_WIDTH:0] w_gray, r_gray;
    wire [ADDR_WIDTH:0] w_bin, r_bin;
    wire [ADDR_WIDTH:0] w_gray_sync, r_gray_sync;
    wire [ADDR_WIDTH:0] w_gray_sync_bin, r_gray_sync_bin;
    wire w_full_int, r_empty_int;

    // Write domain logic
    gray_counter w_gray_counter (
        .clk   (wclk),
        .rst_n (wrst_n),
        .inc   (winc),
        .gray  (w_gray)
    );

    gray_to_bin w_gray_to_bin (
        .gray (w_gray),
        .bin  (w_bin)
    );

    sync_stage #(.WIDTH(ADDR_WIDTH+1)) w_gray_sync_stage (
        .clk   (rclk),
        .rst_n (rrst_n),
        .din   (w_gray),
        .dout  (w_gray_sync)
    );

    gray_to_bin w_gray_sync_to_bin (
        .gray (w_gray_sync),
        .bin  (w_gray_sync_bin)
    );

    // Read domain logic
    gray_counter r_gray_counter (
        .clk   (rclk),
        .rst_n (rrst_n),
        .inc   (rinc),
        .gray  (r_gray)
    );

    gray_to_bin r_gray_to_bin (
        .gray (r_gray),
        .bin  (r_bin)
    );

    sync_stage #(.WIDTH(ADDR_WIDTH+1)) r_gray_sync_stage (
        .clk   (wclk),
        .rst_n (wrst_n),
        .din   (r_gray),
        .dout  (r_gray_sync)
    );

    gray_to_bin r_gray_sync_to_bin (
        .gray (r_gray_sync),
        .bin  (r_gray_sync_bin)
    );

    // FIFO memory
    memory #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH+1)) fifo_memory (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .wen    (winc),
        .waddr  (w_bin),
        .wdata  (wdata),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .ren    (rinc),
        .raddr  (r_bin),
        .rdata  (rdata)
    );

    // Full and empty flags
    assign w_full_int  = (w_gray_sync_bin == (w_bin + 1));
    assign r_empty_int = (r_gray_sync_bin == w_gray_sync_bin);

    assign wfull  = w_full_int;
    assign rempty = r_empty_int;

    // Debug outputs
    assign waddr = w_gray;
    assign raddr = r_gray;

endmodule

module gray_counter #(
    parameter ADDR_WIDTH = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output wire [ADDR_WIDTH:0] gray
);

    reg [ADDR_WIDTH:0] count, count_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else if (inc) begin
            count <= count_next;
        end
    end

    assign count_next = count + 1;
    assign gray = count ^ (count >> 1);

endmodule

module gray_to_bin #(
    parameter ADDR_WIDTH = 4
)(
    input  wire [ADDR_WIDTH:0] gray,
    output wire [ADDR_WIDTH:0] bin
);

    reg [ADDR_WIDTH:0] bin_temp;

    always @(*) begin
        bin_temp = gray;
        for (integer i = 1; i <= ADDR_WIDTH; i = i + 1) begin
            bin_temp = bin_temp ^ (gray >> i);
        end
    end

    assign bin = bin_temp;

endmodule

module sync_stage #(
    parameter WIDTH = 5
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] sync_reg1, sync_reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
        end else begin
            sync_reg1 <= din;
            sync_reg2 <= sync_reg1;
        end
    end

    assign dout = sync_reg2;

endmodule

module memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input  wire wclk,
    input  wire wrst_n,
    input  wire wen,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire [DATA_WIDTH-1:0] wdata,
    input  wire rclk,
    input  wire rrst_n,
    input  wire ren,
    input  wire [ADDR_WIDTH-1:0] raddr,
    output wire [DATA_WIDTH-1:0] rdata
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (integer i = 0; i < (1<<ADDR_WIDTH); i = i + 1) begin
                mem[i] <= 0;
            end
        end else if (wen) begin
            mem[waddr] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (ren) begin
            rdata <= mem[raddr];
        end
    end

endmodule
