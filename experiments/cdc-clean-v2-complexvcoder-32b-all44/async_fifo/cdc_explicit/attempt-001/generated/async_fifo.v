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
    wire [ASIZE-1:0] w_gray_wptr, r_gray_rptr;
    wire [ASIZE-1:0] w_bin_wptr, r_bin_rptr;
    wire [ASIZE-1:0] r_gray_rptr_sync, w_gray_wptr_sync;
    wire [ASIZE-1:0] r_bin_rptr_wclk, w_bin_wptr_rclk;

    // Write Gray Counter
    gray_counter w_gray_counter (
        .clk       (wclk),
        .rst_n     (wrst_n),
        .inc       (winc),
        .gray_count(w_gray_wptr)
    );

    // Read Gray Counter
    gray_counter r_gray_counter (
        .clk       (rclk),
        .rst_n     (rrst_n),
        .inc       (rinc),
        .gray_count(r_gray_rptr)
    );

    // Write Gray to Binary Converter
    gray_to_bin w_gray_to_bin (
        .gray(w_gray_wptr),
        .bin (w_bin_wptr)
    );

    // Read Gray to Binary Converter
    gray_to_bin r_gray_to_bin (
        .gray(r_gray_rptr),
        .bin (r_bin_rptr)
    );

    // Read Gray to Binary Converter for Write Domain
    gray_to_bin r_gray_to_bin_wclk (
        .gray(r_gray_rptr_sync),
        .bin (r_bin_rptr_wclk)
    );

    // Write Gray to Binary Converter for Read Domain
    gray_to_bin w_gray_to_bin_rclk (
        .gray(w_gray_wptr_sync),
        .bin (w_bin_wptr_rclk)
    );

    // Synchronizer for Read Pointer in Write Domain
    sync_register r_gray_sync (
        .din   (r_gray_rptr),
        .clk   (wclk),
        .rst_n (wrst_n),
        .dout  (r_gray_rptr_sync)
    );

    // Synchronizer for Write Pointer in Read Domain
    sync_register w_gray_sync (
        .din   (w_gray_wptr),
        .clk   (rclk),
        .rst_n (rrst_n),
        .dout  (w_gray_wptr_sync)
    );

    // FIFO Memory
    fifo_memory memory (
        .wclk       (wclk),
        .wrst_n     (wrst_n),
        .winc       (winc),
        .wdata      (wdata),
        .wptr       (w_bin_wptr),
        .rclk       (rclk),
        .rrst_n     (rrst_n),
        .rinc       (rinc),
        .rdata      (rdata),
        .rptr       (r_bin_rptr),
        .FALLTHROUGH(FALLTHROUGH),
        .wfull      (wfull),
        .awfull     (awfull),
        .rempty     (rempty),
        .arempty    (arempty)
    );

endmodule

// Gray Counter
module gray_counter (
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output reg  [ASIZE-1:0] gray_count
);

    reg [ASIZE-1:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            gray_count <= 0;
        end else if (inc) begin
            count <= count + 1;
            gray_count <= (count + 1) ^ (count >> 1);
        end
    end

endmodule

// Gray to Binary Converter
module gray_to_bin (
    input  wire [ASIZE-1:0] gray,
    output wire [ASIZE-1:0] bin
);

    assign bin = gray ^ (gray >> 1);

endmodule

// Synchronizer Register
module sync_register (
    input  wire [ASIZE-1:0] din,
    input  wire clk,
    input  wire rst_n,
    output reg  [ASIZE-1:0] dout
);

    reg [ASIZE-1:0] reg1, reg2;

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

// FIFO Memory
module fifo_memory
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        input  wire [ASIZE-1:0] wptr,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        input  wire [ASIZE-1:0] rptr,
        input  wire             FALLTHROUGH,
        output wire             wfull,
        output wire             awfull,
        output wire             rempty,
        output wire             arempty
    );

    reg [DSIZE-1:0] mem [0:(2**ASIZE)-1];
    reg [ASIZE-1:0] next_wptr, next_rptr;
    reg wfull_reg, rempty_reg, awfull_reg, arempty_reg;

    // Write Logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem <= '{default: 0};
            next_wptr <= 0;
            wfull_reg <= 0;
            awfull_reg <= 0;
        end else if (winc && !wfull_reg) begin
            mem[wptr] <= wdata;
            next_wptr <= wptr + 1;
        end
    end

    assign wfull_reg = (next_wptr == rptr + (2**ASIZE) - 1);
    assign awfull_reg = (next_wptr == rptr + (2**ASIZE) - 2);
    assign wfull = wfull_reg;
    assign awfull = awfull_reg;

    // Read Logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            next_rptr <= 0;
            rempty_reg <= 1;
            arempty_reg <= 1;
        end else if (rinc && !rempty_reg) begin
            next_rptr <= rptr + 1;
        end
    end

    assign rempty_reg = (wptr == rptr);
    assign arempty_reg = (wptr == rptr + 1);
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

    // Read Data
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else begin
            if (rinc && !rempty_reg) begin
                rdata <= mem[rptr];
            end else if (FALLTHROUGH && !rempty_reg) begin
                rdata <= mem[rptr];
            end
        end
    end

endmodule
