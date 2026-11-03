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
    wire [ADDR_WIDTH:0] wr_ptr_gray;
    wire [ADDR_WIDTH:0] rd_ptr_gray;

    // Instantiate sync_fifo_ctrl
    sync_fifo_ctrl #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_fifo_ctrl_inst (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc),
        .wfull(wfull),
        .rempty(rempty),
        .wr_ptr_gray(wr_ptr_gray),
        .rd_ptr_gray(rd_ptr_gray)
    );

    // Instantiate dual_clock_ram
    dual_clock_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dual_clock_ram_inst (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .waddr(wr_ptr_gray),
        .wdata(wdata),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .raddr(rd_ptr_gray),
        .rdata(rdata)
    );

    // Assign debug pointers
    assign waddr = wr_ptr_gray;
    assign raddr = rd_ptr_gray;

endmodule

module sync_fifo_ctrl #(
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire                    rinc,
    output wire                    wfull,
    output wire                    rempty,
    output wire [ADDR_WIDTH:0]     wr_ptr_gray,
    output wire [ADDR_WIDTH:0]     rd_ptr_gray
);

    // Internal signals
    wire [ADDR_WIDTH:0] wr_ptr_gray_sync;
    wire [ADDR_WIDTH:0] rd_ptr_gray_sync;

    // Instantiate gray_counter for write pointer
    gray_counter #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) wr_gray_counter (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .gray_cnt(wr_ptr_gray)
    );

    // Instantiate gray_counter for read pointer
    gray_counter #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) rd_gray_counter (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .gray_cnt(rd_ptr_gray)
    );

    // Instantiate sync_stage for write domain synchronization
    sync_stage #(
        .WIDTH(ADDR_WIDTH+1),
        .STAGES(SYNC_STAGES)
    ) wr_sync_stage_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(wr_ptr_gray),
        .dout(wr_ptr_gray_sync)
    );

    // Instantiate sync_stage for read domain synchronization
    sync_stage #(
        .WIDTH(ADDR_WIDTH+1),
        .STAGES(SYNC_STAGES)
    ) rd_sync_stage_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(rd_ptr_gray),
        .dout(rd_ptr_gray_sync)
    );

    // Detect FIFO full condition
    assign wfull = (wr_ptr_gray_sync == {~rd_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync[ADDR_WIDTH-1:0]});

    // Detect FIFO empty condition
    assign rempty = (wr_ptr_gray == rd_ptr_gray);

endmodule

module gray_counter #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    inc,
    output wire [ADDR_WIDTH:0]     gray_cnt
);

    // Internal signals
    reg [ADDR_WIDTH:0] bin_cnt;
    reg [ADDR_WIDTH:0] next_bin_cnt;
    reg [ADDR_WIDTH:0] gray_cnt_reg;

    // Binary counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_cnt <= '0;
        else if (inc)
            bin_cnt <= next_bin_cnt;
    end

    // Next binary count
    always @(*) begin
        next_bin_cnt = bin_cnt + 1;
    end

    // Convert binary to gray code
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            gray_cnt_reg <= '0;
        else
            gray_cnt_reg <= (bin_cnt ^ next_bin_cnt);
    end

    // Output gray code
    assign gray_cnt = gray_cnt_reg;

endmodule

module sync_stage #(
    parameter WIDTH = 5,
    parameter STAGES = 2
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [WIDTH-1:0]        din,
    output wire [WIDTH-1:0]        dout
);

    // Internal signals
    reg [WIDTH-1:0] sync_reg [STAGES-1:0];

    // Synchronization registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < STAGES; i = i + 1)
                sync_reg[i] <= '0;
        end else begin
            sync_reg[0] <= din;
            for (int i = 1; i < STAGES; i = i + 1)
                sync_reg[i] <= sync_reg[i-1];
        end
    end

    // Output synchronized data
    assign dout = sync_reg[STAGES-1];

endmodule

module dual_clock_ram #(
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

    // Internal signals
    reg [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] rdata_reg;

    // Write operation
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (int i = 0; i < 2**ADDR_WIDTH; i = i + 1)
                ram[i] <= '0;
        end else if (winc) begin
            ram[waddr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Read operation
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata_reg <= '0;
        else
            rdata_reg <= ram[raddr[ADDR_WIDTH-1:0]];
    end

    // Output read data
    assign rdata = rdata_reg;

endmodule
