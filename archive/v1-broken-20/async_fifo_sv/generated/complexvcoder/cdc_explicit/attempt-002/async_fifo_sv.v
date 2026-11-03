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
    wire [ADDR_WIDTH:0] wp_out;
    wire [ADDR_WIDTH:0] rp_out;
    wire [DATA_WIDTH-1:0] fm_wdata;
    wire [DATA_WIDTH-1:0] fm_rdata;
    wire wp_full;
    wire rp_empty;

    // Write pointer
    write_ptr #(.ADDR_WIDTH(ADDR_WIDTH)) wp (
        .clk(wclk),
        .rst_n(wrst_n),
        .incr(winc),
        .full(wp_full),
        .out(wp_out)
    );

    // Read pointer
    read_ptr #(.ADDR_WIDTH(ADDR_WIDTH)) rp (
        .clk(rclk),
        .rst_n(rrst_n),
        .incr(rinc),
        .empty(rp_empty),
        .out(rp_out)
    );

    // FIFO memory
    fifo_memory #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) fm (
        .clk(wclk),
        .rst_n(wrst_n),
        .waddr(wp_out),
        .wdata(wdata),
        .raddr(rp_out),
        .rdata(fm_rdata)
    );

    // Full detector
    full_detector #(.ADDR_WIDTH(ADDR_WIDTH)) fd (
        .clk(wclk),
        .rst_n(wrst_n),
        .waddr(wp_out),
        .out(wfull)
    );

    // Empty detector
    empty_detector #(.ADDR_WIDTH(ADDR_WIDTH)) ed (
        .clk(rclk),
        .rst_n(rrst_n),
        .raddr(rp_out),
        .out(rempty)
    );

    // Assign outputs
    assign waddr = wp_out;
    assign raddr = rp_out;
    assign rdata = fm_rdata;

endmodule

module write_ptr #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    incr,
    input  wire                    full,
    output reg [ADDR_WIDTH:0]     out
);

    reg [ADDR_WIDTH:0] wp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wp <= 0;
        end else if (!full && incr) begin
            wp <= wp + 1;
        end
    end

    assign out = wp;

endmodule

module read_ptr #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    incr,
    input  wire                    empty,
    output reg [ADDR_WIDTH:0]     out
);

    reg [ADDR_WIDTH:0] rp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rp <= 0;
        end else if (!empty && incr) begin
            rp <= rp + 1;
        end
    end

    assign out = rp;

endmodule

module fifo_memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [ADDR_WIDTH:0]     waddr,
    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire [ADDR_WIDTH:0]     raddr,
    output reg [DATA_WIDTH-1:0]   rdata
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem <= '{default:0};
        end else begin
            if (waddr < (1<<ADDR_WIDTH)) begin
                mem[waddr] <= wdata;
            end
        end
    end

    assign rdata = mem[raddr];

endmodule

module full_detector #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [ADDR_WIDTH:0]     waddr,
    output reg                    out
);

    reg [ADDR_WIDTH:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else if (waddr < (1<<ADDR_WIDTH)) begin
            count <= waddr + 1;
        end
    end

    assign out = (count == (1<<ADDR_WIDTH));

endmodule

module empty_detector #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [ADDR_WIDTH:0]     raddr,
    output reg                    out
);

    reg [ADDR_WIDTH:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= (1<<ADDR_WIDTH) - 1;
        end else if (raddr < (1<<ADDR_WIDTH)) begin
            count <= count - 1;
        end
    end

    assign out = (count == 0);

endmodule
