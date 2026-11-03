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

    wire [ASIZE-1:0] gray_wptr_out;
    wire [ASIZE-1:0] gray_rptr_out;
    wire [ASIZE-1:0] bin_wptr_out_wclk;
    wire [ASIZE-1:0] bin_wptr_out_rclk;
    wire [ASIZE-1:0] bin_rptr_out_wclk;
    wire [ASIZE-1:0] bin_rptr_out_rclk;
    wire [ASIZE:0]   diff_wclk;
    wire [ASIZE:0]   diff_rclk;

    // Write-side Gray Counter
    gray_counter #(.ASIZE(ASIZE)) gray_wptr (
        .clk     (wclk),
        .rst_n   (wrst_n),
        .inc     (winc),
        .gray_out(gray_wptr_out)
    );

    // Read-side Gray Counter
    gray_counter #(.ASIZE(ASIZE)) gray_rptr (
        .clk     (rclk),
        .rst_n   (rrst_n),
        .inc     (rinc),
        .gray_out(gray_rptr_out)
    );

    // Write-side Gray to Binary Converter
    gray_to_bin #(.ASIZE(ASIZE)) gray_to_bin_wptr (
        .gray_in (gray_wptr_out),
        .bin_out (bin_wptr_out_wclk)
    );

    // Read-side Gray to Binary Converter
    gray_to_bin #(.ASIZE(ASIZE)) gray_to_bin_rptr (
        .gray_in (gray_rptr_out),
        .bin_out (bin_rptr_out_rclk)
    );

    // Dual-Clock RAM
    dual_clock_ram #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_memory (
        .wclk    (wclk),
        .wrst_n  (wrst_n),
        .winc    (winc),
        .waddr   (bin_wptr_out_wclk),
        .wdata   (wdata),
        .rclk    (rclk),
        .rrst_n  (rrst_n),
        .rinc    (rinc),
        .raddr   (bin_rptr_out_rclk),
        .rdata   (rdata)
    );

    // Binary snapshots for full/empty detection
    reg [ASIZE-1:0] bin_wptr_out_rclk_reg;
    reg [ASIZE-1:0] bin_rptr_out_wclk_reg;

    // Synchronize write pointer to read clock
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            bin_wptr_out_rclk_reg <= 0;
        end else begin
            bin_wptr_out_rclk_reg <= bin_wptr_out_rclk;
        end
    end

    // Synchronize read pointer to write clock
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            bin_rptr_out_wclk_reg <= 0;
        end else begin
            bin_rptr_out_wclk_reg <= bin_rptr_out_wclk;
        end
    end

    // Calculate differences for full and empty detection
    assign diff_wclk = bin_wptr_out_wclk - bin_rptr_out_wclk_reg;
    assign diff_rclk = bin_wptr_out_rclk_reg - bin_rptr_out_rclk;

    // Full and Almost Full Detection (write clock domain)
    assign wfull = (diff_wclk == (2**ASIZE));
    assign awfull = (diff_wclk == (2**ASIZE - 1));

    // Empty and Almost Empty Detection (read clock domain)
    assign rempty = (diff_rclk == 0);
    assign arempty = (diff_rclk <= 1);

endmodule

// Gray Code Counter
module gray_counter #(
    parameter ASIZE = 4
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          inc,
    output wire [ASIZE-1:0] gray_out
);

    reg [ASIZE-1:0] gray_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_reg <= 0;
        end else if (inc) begin
            gray_reg <= gray_reg + 1;
        end
    end

    assign gray_out = (gray_reg >> 1) ^ gray_reg;

endmodule

// Gray to Binary Converter
module gray_to_bin #(
    parameter ASIZE = 4
)(
    input  wire [ASIZE-1:0] gray_in,
    output wire [ASIZE-1:0] bin_out
);

    wire [ASIZE:0] gray_ext;
    assign gray_ext = {1'b0, gray_in};

    genvar i;
    generate
        for (i = 0; i < ASIZE; i = i + 1) begin : g_gray_to_bin
            assign bin_out[i] = gray_ext[i] ^ gray_ext[i+1];
        end
    endgenerate

endmodule

// Dual-Clock RAM
module dual_clock_ram #(
    parameter DSIZE = 8,
    parameter ASIZE = 4
)(
    input  wire             wclk,
    input  wire             wrst_n,
    input  wire             winc,
    input  wire [ASIZE-1:0] waddr,
    input  wire [DSIZE-1:0] wdata,
    input  wire             rclk,
    input  wire             rrst_n,
    input  wire             rinc,
    input  wire [ASIZE-1:0] raddr,
    output wire [DSIZE-1:0] rdata
);

    reg [DSIZE-1:0] memory [0:(2**ASIZE)-1];
    reg [DSIZE-1:0] rdata_reg;

    // Write Port
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (integer i = 0; i < 2**ASIZE; i = i + 1) begin
                memory[i] <= 0;
            end
        end else if (winc) begin
            memory[waddr] <= wdata;
        end
    end

    // Read Port
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= 0;
        end else if (rinc) begin
            rdata_reg <= memory[raddr];
        end
    end

    assign rdata = rdata_reg;

endmodule
