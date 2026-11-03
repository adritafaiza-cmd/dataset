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
    wire [ASIZE:0] w_gray, r_gray;
    wire [ASIZE:0] w_gray_sync, r_gray_sync;
    wire write_enable;
    wire [ASIZE:0] w_bin, r_bin, w_gray_sync_bin, r_gray_sync_bin;

    // Binary to Gray conversion function
    function [ASIZE:0] binary_gray_to_bin;
        input [ASIZE:0] gray;
        integer i;
        begin
            binary_gray_to_bin = gray[ASIZE];
            for (i = ASIZE-1; i >= 0; i = i - 1) begin
                binary_gray_to_bin = binary_gray_to_bin ^ gray[i];
            end
        end
    endfunction

    // Write Gray Counter
    gray_counter write_gray_counter (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .gray(w_gray)
    );

    // Read Gray Counter
    gray_counter read_gray_counter (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .gray(r_gray)
    );

    // FIFO Memory
    dual_clock_fifo_memory fifo_memory (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .waddr(w_gray),
        .wdata(wdata),
        .wen(write_enable),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .raddr(r_gray),
        .rdata(rdata)
    );

    // Synchronize write gray counter to read domain
    sync_register w_gray_sync_reg (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(w_gray),
        .dout(w_gray_sync)
    );

    // Synchronize read gray counter to write domain
    sync_register r_gray_sync_reg (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(r_gray),
        .dout(r_gray_sync)
    );

    // Convert gray codes to binary
    always @(*) begin
        w_bin = binary_gray_to_bin(w_gray);
        r_bin = binary_gray_to_bin(r_gray);
        w_gray_sync_bin = binary_gray_to_bin(w_gray_sync);
        r_gray_sync_bin = binary_gray_to_bin(r_gray_sync);
    end

    // Write enable logic
    assign write_enable = winc & ~wfull;

    // FIFO full and almost full logic
    assign wfull = (w_gray_sync_bin == (r_bin + 1) & (2**(ASIZE+1) - 1));
    assign awfull = (w_gray_sync_bin == (r_bin + (2**ASIZE - 1)) & (2**(ASIZE+1) - 1));

    // FIFO empty and almost empty logic
    assign rempty = (w_gray_sync_bin == r_bin);
    assign arempty = (w_gray_sync_bin == (r_bin + 1) & (2**(ASIZE+1) - 1));

endmodule

// Gray Counter module
module gray_counter (
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output reg  [ASIZE:0] gray
);

    reg [ASIZE:0] count, next_count;

    // Calculate next count
    always @(*) begin
        next_count = (count + 1) & (2**(ASIZE+1) - 1);
    end

    // Update count on rising edge of clk
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else if (inc) begin
            count <= next_count;
        end
    end

    // Convert count to Gray code
    always @(*) begin
        gray = count ^ (count >> 1);
    end

endmodule

// Dual-clock FIFO Memory module
module dual_clock_fifo_memory (
    input  wire             wclk,
    input  wire             wrst_n,
    input  wire [ASIZE:0]   waddr,
    input  wire [DSIZE-1:0] wdata,
    input  wire             wen,
    input  wire             rclk,
    input  wire             rrst_n,
    input  wire [ASIZE:0]   raddr,
    output wire [DSIZE-1:0] rdata
);

    reg [DSIZE-1:0] memory [0:2**(ASIZE+1)-1];

    // Write operation
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            memory <= '{default:0};
        end else if (wen) begin
            memory[waddr] <= wdata;
        end
    end

    // Read operation
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else begin
            rdata <= memory[raddr];
        end
    end

endmodule

// Synchronization register module
module sync_register (
    input  wire clk,
    input  wire rst_n,
    input  wire [ASIZE:0] din,
    output reg  [ASIZE:0] dout
);

    reg [ASIZE:0] dout_sync;

    // Synchronize input to output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 0;
            dout_sync <= 0;
        end else begin
            dout_sync <= din;
            dout <= dout_sync;
        end
    end

endmodule
