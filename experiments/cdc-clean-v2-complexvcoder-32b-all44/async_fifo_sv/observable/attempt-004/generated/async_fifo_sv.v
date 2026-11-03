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
    reg [ADDR_WIDTH:0] waddr_reg;
    reg [ADDR_WIDTH:0] raddr_reg;
    reg [ADDR_WIDTH:0] waddr_sync;
    reg [ADDR_WIDTH:0] raddr_sync;
    reg [DATA_WIDTH-1:0] rdata_reg;

    // FIFO memory instance
    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_mem_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .we(winc && !wfull),
        .waddr(waddr_reg[ADDR_WIDTH-1:0]),
        .din(wdata),
        .raddr(raddr_sync[ADDR_WIDTH-1:0]),
        .dout(rdata_reg)
    );

    // Write pointer synchronizer
    sync_reg #(
        .WIDTH(ADDR_WIDTH+1)
    ) wptr_sync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(waddr_reg),
        .dout(waddr_sync)
    );

    // Read pointer synchronizer
    sync_reg #(
        .WIDTH(ADDR_WIDTH+1)
    ) rptr_sync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(raddr_reg),
        .dout(raddr_sync)
    );

    // Write address register
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            waddr_reg <= 0;
        end else if (winc && !wfull) begin
            waddr_reg <= waddr_reg + 1;
        end
    end

    // Read address register
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            raddr_reg <= 0;
        end else if (rinc && !rempty) begin
            raddr_reg <= raddr_reg + 1;
        end
    end

    // Full flag calculation
    assign wfull = (waddr_reg[ADDR_WIDTH:0] + 1) == raddr_sync[ADDR_WIDTH:0];

    // Empty flag calculation
    assign rempty = waddr_sync[ADDR_WIDTH:0] == raddr_reg[ADDR_WIDTH:0];

    // Output assignments
    assign waddr = waddr_reg[ADDR_WIDTH:0];
    assign raddr = raddr_reg[ADDR_WIDTH:0];
    assign rdata = rdata_reg;

endmodule

module fifo_mem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    we,
    input  wire [ADDR_WIDTH-1:0]   waddr,
    input  wire [DATA_WIDTH-1:0]   din,
    input  wire [ADDR_WIDTH-1:0]   raddr,
    output wire [DATA_WIDTH-1:0]   dout
);

    // Memory array
    reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];

    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize memory to 0 or some known value if needed
            for (integer i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
                mem[i] <= 0;
            end
        end else if (we) begin
            mem[waddr] <= din;
        end
    end

    // Read operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 0;
        end else begin
            dout <= mem[raddr];
        end
    end

endmodule

module sync_reg #(
    parameter WIDTH = 1
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [WIDTH-1:0]        din,
    output reg  [WIDTH-1:0]        dout
);

    // Internal registers for synchronization
    reg [WIDTH-1:0] reg1;
    reg [WIDTH-1:0] reg2;

    // Synchronization process
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
