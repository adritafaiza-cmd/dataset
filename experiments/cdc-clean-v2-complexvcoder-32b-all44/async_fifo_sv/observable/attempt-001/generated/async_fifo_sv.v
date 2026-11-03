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

    wire [ADDR_WIDTH:0] w_gray_code;
    wire [ADDR_WIDTH:0] r_gray_code;
    reg  [ADDR_WIDTH:0] waddr_reg;
    reg  [ADDR_WIDTH:0] raddr_reg;
    wire [ADDR_WIDTH:0] r_gray_code_sync;
    wire [ADDR_WIDTH:0] w_gray_code_sync;
    wire [ADDR_WIDTH:0] raddr_sync_bin;
    wire [ADDR_WIDTH:0] waddr_sync_bin;
    wire wfull_raw;
    wire rempty_raw;

    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_memory (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .waddr(waddr_reg),
        .wdata(wdata),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .raddr(raddr_reg),
        .rdata(rdata)
    );

    gray_counter #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) w_gray_counter (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .gray_code(w_gray_code)
    );

    gray_counter #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) r_gray_counter (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .gray_code(r_gray_code)
    );

    gray_to_bin #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) w_gray_to_bin (
        .gray_code(w_gray_code),
        .bin_code(waddr_reg)
    );

    gray_to_bin #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) r_gray_to_bin (
        .gray_code(r_gray_code),
        .bin_code(raddr_reg)
    );

    sync_register #(
        .WIDTH(ADDR_WIDTH+1),
        .SYNC_STAGES(SYNC_STAGES)
    ) raddr_sync (
        .clk(wclk),
        .rst_n(wrst_n),
        .d(r_gray_code),
        .q(r_gray_code_sync)
    );

    sync_register #(
        .WIDTH(ADDR_WIDTH+1),
        .SYNC_STAGES(SYNC_STAGES)
    ) waddr_sync (
        .clk(rclk),
        .rst_n(rrst_n),
        .d(w_gray_code),
        .q(w_gray_code_sync)
    );

    gray_to_bin #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) raddr_sync_to_bin (
        .gray_code(r_gray_code_sync),
        .bin_code(raddr_sync_bin)
    );

    gray_to_bin #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) waddr_sync_to_bin (
        .gray_code(w_gray_code_sync),
        .bin_code(waddr_sync_bin)
    );

    assign wfull_raw = (waddr_sync_bin + 1) == raddr_reg;
    assign rempty_raw = waddr_reg == raddr_sync_bin;

    reg wfull_reg;
    reg rempty_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull_reg <= 1'b0;
        end else begin
            wfull_reg <= wfull_raw;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty_reg <= 1'b1;
        end else begin
            rempty_reg <= rempty_raw;
        end
    end

    assign wfull = wfull_reg;
    assign rempty = rempty_reg;
    assign waddr = waddr_reg;
    assign raddr = raddr_reg;

endmodule

module fifo_mem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire [ADDR_WIDTH:0]     waddr,
    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire [ADDR_WIDTH:0]     raddr,
    output wire [DATA_WIDTH-1:0]   rdata
);

    reg [DATA_WIDTH-1:0] mem [0:(2**(ADDR_WIDTH+1))-1];

    always @(posedge wclk) begin
        if (wrst_n && winc) begin
            mem[waddr] <= wdata;
        end
    end

    always @(posedge rclk) begin
        if (rrst_n) begin
            rdata <= mem[raddr];
        end
    end

endmodule

module gray_counter #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    inc,
    output wire [ADDR_WIDTH:0]     gray_code
);

    reg [ADDR_WIDTH:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
        end else if (inc) begin
            counter <= counter + 1;
        end
    end

    assign gray_code = (counter >> 1) ^ counter;

endmodule

module gray_to_bin #(
    parameter ADDR_WIDTH = 4
)(
    input  wire [ADDR_WIDTH:0]     gray_code,
    output wire [ADDR_WIDTH:0]     bin_code
);

    wire [ADDR_WIDTH:0] bin_code_int;

    assign bin_code_int[ADDR_WIDTH] = gray_code[ADDR_WIDTH];
    genvar i;
    generate
        for (i = ADDR_WIDTH-1; i >= 0; i = i - 1) begin: gen_gray_to_bin
            assign bin_code_int[i] = bin_code_int[i+1] ^ gray_code[i];
        end
    endgenerate

    assign bin_code = bin_code_int;

endmodule

module sync_register #(
    parameter WIDTH = 1,
    parameter SYNC_STAGES = 2
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [WIDTH-1:0]        d,
    output reg  [WIDTH-1:0]        q
);

    reg [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 0;
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= 0;
            end
        end else begin
            sync_reg[0] <= d;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
            q <= sync_reg[SYNC_STAGES-1];
        end
    end

endmodule
