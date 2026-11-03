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

    // Instantiate sync_fifo
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_fifo_inst (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wdata(wdata),
        .wfull(wfull),
        .waddr(waddr),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc),
        .rdata(rdata),
        .rempty(rempty),
        .raddr(raddr)
    );

endmodule

module sync_fifo #(
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

    // Write and Read Gray Counters
    gray_counter #(
        .WIDTH(ADDR_WIDTH+1)
    ) wgray_counter (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .gray(wgray)
    );

    gray_counter #(
        .WIDTH(ADDR_WIDTH+1)
    ) rgray_counter (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .gray(rgray)
    );

    // Convert Gray to Binary
    binary_counter #(
        .WIDTH(ADDR_WIDTH+1)
    ) wbin_counter (
        .gray(wgray),
        .bin(wbin)
    );

    binary_counter #(
        .WIDTH(ADDR_WIDTH+1)
    ) rbin_counter (
        .gray(rgray),
        .bin(rbin)
    );

    // Synchronize Pointers
    sync_register #(
        .WIDTH(ADDR_WIDTH+1),
        .STAGES(SYNC_STAGES)
    ) sync_rptr_wclk (
        .clk(wclk),
        .rst_n(wrst_n),
        .data(rbin),
        .synced(sync_rptr)
    );

    sync_register #(
        .WIDTH(ADDR_WIDTH+1),
        .STAGES(SYNC_STAGES)
    ) sync_wptr_rclk (
        .clk(rclk),
        .rst_n(rrst_n),
        .data(wbin),
        .synced(sync_wptr)
    );

    // FIFO Memory
    fifo_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_memory_inst (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .waddr(wbin),
        .wen(winc),
        .wdata(wdata),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .raddr(rbin),
        .rptr_wclk(sync_rptr),
        .wptr_rclk(sync_wptr),
        .rdata(rdata),
        .wfull(wfull),
        .rempty(rempty)
    );

    // Assign outputs
    assign waddr = wbin;
    assign raddr = rbin;

endmodule

module fifo_memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire [ADDR_WIDTH:0]     waddr,
    input  wire                    wen,
    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire [ADDR_WIDTH:0]     raddr,
    input  wire [ADDR_WIDTH:0]     rptr_wclk,
    input  wire [ADDR_WIDTH:0]     wptr_rclk,
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire                    wfull,
    output wire                    rempty
);

    // Memory array
    reg [DATA_WIDTH-1:0] memory [0:(2**ADDR_WIDTH)-1];

    // Full and Empty flags
    reg wfull_reg;
    reg rempty_reg;

    // Write Operation
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull_reg <= 1'b0;
            memory <= '{default: 0};
        end else if (wen && !wfull_reg) begin
            memory[waddr] <= wdata;
        end
    end

    // Read Operation
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty_reg <= 1'b1;
            rdata <= 0;
        end else begin
            rdata <= memory[raddr];
        end
    end

    // Full and Empty Detection
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wfull_reg <= 1'b0;
        else
            wfull_reg <= (wptr_rclk == {~rptr_wclk[ADDR_WIDTH], rptr_wclk[ADDR_WIDTH-1:0]});
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rempty_reg <= 1'b1;
        else
            rempty_reg <= (rptr_wclk == {~wptr_rclk[ADDR_WIDTH], wptr_rclk[ADDR_WIDTH-1:0]});
    end

    assign wfull = wfull_reg;
    assign rempty = rempty_reg;

endmodule

module gray_counter #(
    parameter WIDTH = 5
)(
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output wire [WIDTH-1:0] gray
);

    reg [WIDTH-1:0] bin_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_reg <= 0;
        else if (inc)
            bin_reg <= bin_reg + 1;
    end

    assign gray = bin_reg ^ (bin_reg >> 1);

endmodule

module binary_counter #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] gray,
    output wire [WIDTH-1:0] bin
);

    assign bin = gray ^ (gray >> 1) ^ (gray >> 2) ^ (gray >> 3) ^ (gray >> 4);

endmodule

module sync_register #(
    parameter WIDTH = 5,
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] data,
    output wire [WIDTH-1:0] synced
);

    reg [WIDTH-1:0] sync_reg [0:STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < STAGES; i = i + 1)
                sync_reg[i] <= 0;
        end else begin
            sync_reg[0] <= data;
            for (int i = 1; i < STAGES; i = i + 1)
                sync_reg[i] <= sync_reg[i-1];
        end
    end

    assign synced = sync_reg[STAGES-1];

endmodule
