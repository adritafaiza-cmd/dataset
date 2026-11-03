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

    wire [ADDR_WIDTH:0] wptr_gray, rptr_gray;
    wire [ADDR_WIDTH:0] wptr_gray_sync, rptr_gray_sync;
    wire [ADDR_WIDTH:0] wptr_gray_sync_r, rptr_gray_sync_w;
    wire [ADDR_WIDTH:0] wptr_bin_sync_r, rptr_bin_sync_w;

    // Gray counters for write and read pointers
    gray_counter #(.WIDTH(ADDR_WIDTH+1))
    gray_wptr (
        .clk   (wclk),
        .rst_n (wrst_n),
        .inc   (winc),
        .gray  (wptr_gray)
    );

    gray_counter #(.WIDTH(ADDR_WIDTH+1))
    gray_rptr (
        .clk   (rclk),
        .rst_n (rrst_n),
        .inc   (rinc),
        .gray  (rptr_gray)
    );

    // Synchronizers for write and read pointers
    sync_stage #(.STAGES(SYNC_STAGES))
    sync_wptr (
        .local  (wptr_gray),
        .remote (wptr_gray_sync)
    );

    sync_stage #(.STAGES(SYNC_STAGES))
    sync_rptr (
        .local  (rptr_gray),
        .remote (rptr_gray_sync)
    );

    // Convert synchronized gray pointers to binary
    gray_to_bin #(.WIDTH(ADDR_WIDTH+1))
    gray_to_bin_wptr (
        .gray (wptr_gray_sync),
        .bin  (wptr_bin_sync_r)
    );

    gray_to_bin #(.WIDTH(ADDR_WIDTH+1))
    gray_to_bin_rptr (
        .gray (rptr_gray_sync),
        .bin  (rptr_bin_sync_w)
    );

    // FIFO memory with full and empty flags
    fifo_memory #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH+1))
    fifo_mem (
        .wclk       (wclk),
        .wrst_n     (wrst_n),
        .winc       (winc),
        .wptr       (wptr_bin_sync_r),
        .wdata      (wdata),
        .wfull      (wfull),
        .waddr      (waddr),
        .rclk       (rclk),
        .rrst_n     (rrst_n),
        .rinc       (rinc),
        .rptr       (rptr_bin_sync_w),
        .rdata      (rdata),
        .rempty     (rempty),
        .raddr      (raddr)
    );

endmodule

// Sync stage module
module sync_stage #(
    parameter STAGES = 2
)(
    input  wire local,
    output wire remote
);
    reg [STAGES-1:0] sync_chain;

    always @(posedge remote or negedge rrst_n) begin
        if (!rrst_n) begin
            sync_chain <= '0;
        end else begin
            sync_chain <= {sync_chain[STAGES-2:0], local};
        end
    end

    assign remote = sync_chain[STAGES-1];
endmodule

// Gray counter module
module gray_counter #(
    parameter WIDTH = 5
)(
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output reg [WIDTH-1:0] gray
);
    reg [WIDTH-1:0] bin;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin  <= '0;
            gray <= '0;
        end else if (inc) begin
            bin  <= bin + 1;
            gray <= bin ^ (bin >> 1);
        end
    end
endmodule

// Gray to binary converter module
module gray_to_bin #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] gray,
    output wire [WIDTH-1:0] bin
);
    integer i;
    assign bin[0] = gray[0];

    generate
        genvar j;
        for (j = 1; j < WIDTH; j = j + 1) begin: gen_gray_to_bin
            assign bin[j] = bin[j-1] ^ gray[j];
        end
    endgenerate
endmodule

// FIFO memory module
module fifo_memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire [ADDR_WIDTH-1:0]   wptr,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output wire                    wfull,
    output wire [ADDR_WIDTH-1:0]   waddr,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire                    rinc,
    input  wire [ADDR_WIDTH-1:0]   rptr,
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire                    rempty,
    output wire [ADDR_WIDTH-1:0]   raddr
);
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
    reg [ADDR_WIDTH:0] waddr_reg, raddr_reg;
    reg [ADDR_WIDTH:0] waddr_gray, raddr_gray;
    reg [ADDR_WIDTH:0] waddr_gray_sync_r, raddr_gray_sync_w;
    reg [ADDR_WIDTH:0] waddr_bin_sync_r, raddr_bin_sync_w;

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            waddr_reg <= '0;
        end else if (winc && !wfull) begin
            waddr_reg <= waddr_reg + 1;
        end
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            raddr_reg <= '0;
        end else if (rinc && !rempty) begin
            raddr_reg <= raddr_reg + 1;
        end
    end

    // Write data into memory
    always @(posedge wclk) begin
        if (winc && !wfull) begin
            mem[waddr_reg] <= wdata;
        end
    end

    // Read data from memory
    always @(posedge rclk) begin
        if (rinc && !rempty) begin
            rdata <= mem[raddr_reg];
        end
    end

    // Gray code conversion for write and read pointers
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            waddr_gray <= '0;
        end else begin
            waddr_gray <= waddr_reg ^ (waddr_reg >> 1);
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            raddr_gray <= '0;
        end else begin
            raddr_gray <= raddr_reg ^ (raddr_reg >> 1);
        end
    end

    // Synchronizers for write and read pointers
    sync_stage #(.STAGES(SYNC_STAGES))
    sync_wptr (
        .local  (waddr_gray),
        .remote (waddr_gray_sync_r)
    );

    sync_stage #(.STAGES(SYNC_STAGES))
    sync_rptr (
        .local  (raddr_gray),
        .remote (raddr_gray_sync_w)
    );

    // Convert synchronized gray pointers to binary
    gray_to_bin #(.WIDTH(ADDR_WIDTH+1))
    gray_to_bin_wptr (
        .gray (waddr_gray_sync_r),
        .bin  (waddr_bin_sync_r)
    );

    gray_to_bin #(.WIDTH(ADDR_WIDTH+1))
    gray_to_bin_rptr (
        .gray (raddr_gray_sync_w),
        .bin  (raddr_bin_sync_w)
    );

    // Full and empty flags
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull <= 1'b0;
        end else begin
            wfull <= (waddr_bin_sync_r == {~raddr_gray_sync_w[ADDR_WIDTH-1:0], raddr_gray_sync_w[ADDR_WIDTH]});
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty <= 1'b1;
        end else begin
            rempty <= (waddr_gray_sync_r == {~raddr_bin_sync_w[ADDR_WIDTH-1:0], raddr_bin_sync_w[ADDR_WIDTH]});
        end
    end

    // Debug outputs
    assign waddr = waddr_reg;
    assign raddr = raddr_reg;
endmodule
