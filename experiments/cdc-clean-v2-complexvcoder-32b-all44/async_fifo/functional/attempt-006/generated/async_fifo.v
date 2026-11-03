module async_fifo
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        output wire             wfull,
        output wire             awfull,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             rempty,
        output wire             arempty
    );

    // Internal signals
    wire [ASIZE:0] gray_wptr, gray_rptr;
    wire [ASIZE:0] wptr, rptr;
    wire [ASIZE:0] gray_wptr_sync_rclk, gray_rptr_sync_wclk;
    wire wfull_raw, rempty_raw;
    wire wfull_gray, rempty_gray;
    wire wfull_sync, rempty_sync;
    wire awfull_gray, arempty_gray;
    wire awfull_sync, arempty_sync;

    // Write-domain gray counter
    gray_counter gray_counter_w (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc & ~wfull),
        .count(gray_wptr)
    );

    // Read-domain gray counter
    gray_counter gray_counter_r (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc & ~rempty),
        .count(gray_rptr)
    );

    // Write-domain gray to binary converter
    gray_to_bin gray_to_bin_w (
        .gray(gray_wptr),
        .bin(wptr)
    );

    // Read-domain gray to binary converter
    gray_to_bin gray_to_bin_r (
        .gray(gray_rptr),
        .bin(rptr)
    );

    // Write-domain binary to gray converter
    bin_to_gray bin_to_gray_w (
        .bin(wptr),
        .gray(gray_wptr_sync_rclk)
    );

    // Read-domain binary to gray converter
    bin_to_gray bin_to_gray_r (
        .bin(rptr),
        .gray(gray_rptr_sync_wclk)
    );

    // Synchronize gray_rptr to wclk domain
    sync_register sync_register_wclk (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(gray_rptr),
        .dout(gray_rptr_sync_wclk)
    );

    // Synchronize gray_wptr to rclk domain
    sync_register sync_register_rclk (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(gray_wptr),
        .dout(gray_wptr_sync_rclk)
    );

    // Memory for FIFO
    memory memory_inst (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc & ~wfull),
        .waddr(wptr),
        .wdata(wdata),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .raddr(rptr),
        .rdata(rdata)
    );

    // Determine wfull and rempty
    assign wfull_raw = (wptr == {~gray_rptr_sync_wclk[ASIZE], gray_rptr_sync_wclk[ASIZE-1:0]});
    assign rempty_raw = (rptr == {~gray_wptr_sync_rclk[ASIZE], gray_wptr_sync_rclk[ASIZE-1:0]});

    // Gray code version of wfull and rempty
    assign wfull_gray = (gray_wptr == gray_rptr_sync_wclk[ASIZE] ^ {1'b0, gray_rptr_sync_wclk[ASIZE-1:0]});
    assign rempty_gray = (gray_rptr == gray_wptr_sync_rclk[ASIZE] ^ {1'b0, gray_wptr_sync_rclk[ASIZE-1:0]});

    // Synchronize wfull and rempty
    sync_register sync_register_wfull (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wfull_gray),
        .dout(wfull_sync)
    );

    sync_register sync_register_rempty (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rempty_gray),
        .dout(rempty_sync)
    );

    // Determine awfull and arempty
    assign awfull_gray = (gray_wptr == {~gray_rptr_sync_wclk[ASIZE], gray_rptr_sync_wclk[ASIZE-1:0]} + 2);
    assign arempty_gray = (gray_rptr == {~gray_wptr_sync_rclk[ASIZE], gray_wptr_sync_rclk[ASIZE-1:0]} - 2);

    // Synchronize awfull and arempty
    sync_register sync_register_awfull (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(awfull_gray),
        .dout(awfull_sync)
    );

    sync_register sync_register_arempty (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(arempty_gray),
        .dout(arempty_sync)
    );

    // Assign final outputs
    assign wfull = wfull_sync;
    assign awfull = awfull_sync;
    assign rempty = rempty_sync;
    assign arempty = arempty_sync;

endmodule

// Gray code counter
module gray_counter (
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output reg [ASIZE:0] count
);

    reg [ASIZE:0] count_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 0;
        else if (inc)
            count <= count_next;
    end

    always @(*) begin
        count_next = count ^ (count >> 1) + 1;
    end

endmodule

// Convert Gray code to Binary
module gray_to_bin (
    input  wire [ASIZE:0] gray,
    output wire [ASIZE:0] bin
);

    wire [ASIZE:0] bin_int;

    assign bin_int[ASIZE] = gray[ASIZE];
    genvar i;
    generate
        for (i = ASIZE-1; i >= 0; i = i - 1) begin : gen_gray_to_bin
            assign bin_int[i] = bin_int[i+1] ^ gray[i];
        end
    endgenerate

    assign bin = bin_int;

endmodule

// Convert Binary to Gray
module bin_to_gray (
    input  wire [ASIZE:0] bin,
    output wire [ASIZE:0] gray
);

    wire [ASIZE:0] gray_int;

    assign gray_int[ASIZE] = bin[ASIZE];
    genvar i;
    generate
        for (i = ASIZE-1; i >= 0; i = i - 1) begin : gen_bin_to_gray
            assign gray_int[i] = bin[i] ^ bin[i+1];
        end
    endgenerate

    assign gray = gray_int;

endmodule

// Synchronize signal to target clock domain
module sync_register (
    input  wire clk,
    input  wire rst_n,
    input  wire [ASIZE:0] din,
    output reg [ASIZE:0] dout
);

    reg [ASIZE:0] dreg1, dreg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dreg1 <= 0;
            dreg2 <= 0;
        end else begin
            dreg1 <= din;
            dreg2 <= dreg1;
        end
    end

    assign dout = dreg2;

endmodule

// Dual-port memory for FIFO
module memory (
    input  wire wclk,
    input  wire wrst_n,
    input  wire winc,
    input  wire [ASIZE:0] waddr,
    input  wire [DSIZE-1:0] wdata,
    input  wire rclk,
    input  wire rrst_n,
    input  wire [ASIZE:0] raddr,
    output reg [DSIZE-1:0] rdata
);

    reg [DSIZE-1:0] memory_array [0:(2**(ASIZE+1))-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            memory_array <= '{default: 0};
        else if (winc)
            memory_array[waddr] <= wdata;
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata <= 0;
        else
            rdata <= memory_array[raddr];
    end

endmodule
