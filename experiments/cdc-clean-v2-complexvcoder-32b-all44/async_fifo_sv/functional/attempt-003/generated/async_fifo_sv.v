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

    wire [ADDR_WIDTH:0] w_gray, r_gray;
    wire [ADDR_WIDTH:0] w_bin, r_bin;
    wire [ADDR_WIDTH:0] r_bin_to_gray_out;

    // Gray counters for write and read addresses
    gray_counter #(.WIDTH(ADDR_WIDTH+1)) w_gray_counter (
        .clk    (wclk),
        .rst_n  (wrst_n),
        .inc    (winc),
        .gray   (w_gray)
    );

    gray_counter #(.WIDTH(ADDR_WIDTH+1)) r_gray_counter (
        .clk    (rclk),
        .rst_n  (rrst_n),
        .inc    (rinc),
        .gray   (r_gray)
    );

    // Convert write gray code to binary
    gray_to_bin #(.WIDTH(ADDR_WIDTH+1)) w_gray_to_bin (
        .gray   (w_gray),
        .bin    (w_bin)
    );

    // Convert read gray code to binary
    gray_to_bin #(.WIDTH(ADDR_WIDTH+1)) r_gray_to_bin (
        .gray   (r_gray),
        .bin    (r_bin)
    );

    // Convert read binary back to gray code for synchronization
    bin_to_gray #(.WIDTH(ADDR_WIDTH+1)) r_bin_to_gray (
        .bin    (r_bin),
        .gray   (r_bin_to_gray_out)
    );

    // FIFO memory
    fifo_mem #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH+1)
    ) fifo_memory (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .waddr  (w_bin),
        .wdata  (wdata),
        .winc   (winc),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .raddr  (r_bin),
        .rinc   (rinc),
        .rdata  (rdata)
    );

    // Synchronize FIFO flags
    sync_fifo_flags #(
        .WIDTH (ADDR_WIDTH+1),
        .SYNC_STAGES (SYNC_STAGES)
    ) sync_flags (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .w_gray (w_gray),
        .r_gray (r_bin_to_gray_out),
        .wfull  (wfull),
        .rempty (rempty)
    );

    // Assign debug address outputs
    assign waddr = w_bin;
    assign raddr = r_bin;

endmodule

// Gray counter module
module gray_counter #(
    parameter WIDTH = 5
)(
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output wire [WIDTH-1:0] gray
);

    reg [WIDTH-1:0] gray_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_reg <= {WIDTH{1'b0}};
        end else if (inc) begin
            gray_reg <= gray_reg ^ (gray_reg >> 1) ^ 1;
        end
    end

    assign gray = gray_reg;

endmodule

// Gray to binary converter
module gray_to_bin #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] gray,
    output wire [WIDTH-1:0] bin
);

    wire [WIDTH-1:0] shifted_gray;

    assign shifted_gray = {1'b0, gray[WIDTH-2:0]};
    assign bin = gray ^ shifted_gray;

endmodule

// Binary to gray converter
module bin_to_gray #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] bin,
    output wire [WIDTH-1:0] gray
);

    assign gray = bin ^ (bin >> 1);

endmodule

// FIFO memory module
module fifo_mem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input  wire wclk,
    input  wire wrst_n,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire [DATA_WIDTH-1:0] wdata,
    input  wire winc,
    input  wire rclk,
    input  wire rrst_n,
    input  wire [ADDR_WIDTH-1:0] raddr,
    input  wire rinc,
    output wire [DATA_WIDTH-1:0] rdata
);

    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            memory <= '{default:0};
        end else if (winc) begin
            memory[waddr] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (rinc) begin
            rdata <= memory[raddr];
        end
    end

endmodule

// Synchronize FIFO flags module
module sync_fifo_flags #(
    parameter WIDTH = 5,
    parameter SYNC_STAGES = 2
)(
    input  wire wclk,
    input  wire wrst_n,
    input  wire rclk,
    input  wire rrst_n,
    input  wire [WIDTH-1:0] w_gray,
    input  wire [WIDTH-1:0] r_gray,
    output wire wfull,
    output wire rempty
);

    reg [SYNC_STAGES-1:0][WIDTH-1:0] r_gray_sync;
    reg [SYNC_STAGES-1:0][WIDTH-1:0] w_gray_sync;

    // Synchronize r_gray to wclk domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            r_gray_sync <= '{default:0};
        end else begin
            r_gray_sync[0] <= r_gray;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                r_gray_sync[i] <= r_gray_sync[i-1];
            end
        end
    end

    // Synchronize w_gray to rclk domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            w_gray_sync <= '{default:0};
        end else begin
            w_gray_sync[0] <= w_gray;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                w_gray_sync[i] <= w_gray_sync[i-1];
            end
        end
    end

    // Determine wfull and rempty
    wire [WIDTH:0] wptr_bin;
    wire [WIDTH:0] rptr_bin_sync;

    gray_to_bin #(.WIDTH(WIDTH)) w_gray_to_bin (
        .gray   (w_gray),
        .bin    (wptr_bin)
    );

    gray_to_bin #(.WIDTH(WIDTH)) r_gray_to_bin_sync (
        .gray   (r_gray_sync[SYNC_STAGES-1]),
        .bin    (rptr_bin_sync)
    );

    assign wfull = (wptr_bin == {rptr_bin_sync[WIDTH-1:0], ~rptr_bin_sync[WIDTH]});
    assign rempty = (rptr_bin_sync == {wptr_bin[WIDTH-1:0], ~wptr_bin[WIDTH]});

endmodule
