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

    localparam FIFO_SIZE = 1 << ADDR_WIDTH;

    reg [DATA_WIDTH-1:0] mem [0:FIFO_SIZE-1];
    reg [ADDR_WIDTH:0] write_addr_reg, read_addr_reg;
    reg fifo_full_reg, fifo_empty_reg;

    // Write domain
    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_sync_write (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .data(wdata),
        .full(wfull),
        .addr(waddr)
    );

    fifo_logic #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_logic_write (
        .clk(wclk),
        .rst_n(wrst_n),
        .addr(write_addr_reg),
        .full(fifo_full_reg)
    );

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            write_addr_reg <= 0;
            fifo_full_reg <= 0;
        end else begin
            if (!wfull && winc) begin
                mem[write_addr_reg] <= wdata;
                write_addr_reg <= write_addr_reg + 1;
                if (write_addr_reg == FIFO_SIZE - 1) begin
                    fifo_full_reg <= 1;
                end
            end
        end
    end

    // Read domain
    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_sync_read (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .rempty(rempty),
        .addr(raddr)
    );

    fifo_logic #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_logic_read (
        .clk(rclk),
        .rst_n(rrst_n),
        .addr(read_addr_reg),
        .empty(fifo_empty_reg)
    );

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            read_addr_reg <= 0;
            fifo_empty_reg <= 1;
        end else begin
            if (!rempty && rinc) begin
                rdata <= mem[read_addr_reg];
                read_addr_reg <= read_addr_reg + 1;
                if (read_addr_reg == FIFO_SIZE - 1) begin
                    fifo_empty_reg <= 0;
                end
            end
        end
    end

endmodule

module fifo_sync #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    inc,
    input  wire [DATA_WIDTH-1:0]   data,
    output wire                    full,
    output wire [ADDR_WIDTH:0]     addr
);

    reg [ADDR_WIDTH:0] addr_reg;

    generate
        if (SYNC_STAGES == 0) begin : no_sync
            assign addr = addr_reg;
            assign full = 0;
        end else begin : sync
            reg [ADDR_WIDTH:0] addr_sync[0:SYNC_STAGES-1];
            reg full_sync[0:SYNC_STAGES-1];

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    addr_sync <= {SYNC_STAGES{0}};
                    full_sync <= {SYNC_STAGES{0}};
                end else begin
                    addr_sync[0] <= addr_reg;
                    full_sync[0] <= 0;
                    for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                        addr_sync[i] <= addr_sync[i-1];
                        full_sync[i] <= full_sync[i-1];
                    end
                    addr_reg <= addr_reg + inc;
                    if (addr_reg == (1 << ADDR_WIDTH) - 1) begin
                        full_sync[SYNC_STAGES-1] <= 1;
                    end
                end
            end

            assign addr = addr_sync[SYNC_STAGES-1];
            assign full = full_sync[SYNC_STAGES-1];
        end
    endgenerate

endmodule

module fifo_logic #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [ADDR_WIDTH:0]     addr,
    output wire                    full,
    output wire                    empty
);

    reg [ADDR_WIDTH:0] head_reg, tail_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head_reg <= 0;
            tail_reg <= 0;
        end else begin
            head_reg <= addr;
        end
    end

    assign full = (head_reg == tail_reg) && (addr == (1 << ADDR_WIDTH) - 1);
    assign empty = (head_reg == tail_reg) && (addr == 0);

endmodule
