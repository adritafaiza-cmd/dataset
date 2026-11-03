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

    wire [ASIZE-1:0] w_gray_ptr, r_gray_ptr;
    wire [ASIZE-1:0] w_bin_ptr, r_bin_ptr;
    wire [ASIZE-1:0] w_gray_ptr_ff, r_gray_ptr_ff;
    wire w_full_flag, r_empty_flag;

    // Write Gray Counter
    gray_counter w_gray_counter (
        .clk      (wclk),
        .rst_n    (wrst_n),
        .inc      (winc),
        .gray_ptr (w_gray_ptr)
    );

    // Read Gray Counter
    gray_counter r_gray_counter (
        .clk      (rclk),
        .rst_n    (rrst_n),
        .inc      (rinc),
        .gray_ptr (r_gray_ptr)
    );

    // Write Gray to Binary Conversion
    gray_to_bin w_gray_to_bin (
        .gray_code (w_gray_ptr),
        .bin_code  (w_bin_ptr)
    );

    // Read Gray to Binary Conversion
    gray_to_bin r_gray_to_bin (
        .gray_code (r_gray_ptr),
        .bin_code  (r_bin_ptr)
    );

    // Write Binary to Gray Conversion for Cross-Domain Stability
    bin_to_gray w_bin_to_gray (
        .bin_code  (w_bin_ptr),
        .gray_code (w_gray_ptr_ff)
    );

    // Read Binary to Gray Conversion for Cross-Domain Stability
    bin_to_gray r_bin_to_gray (
        .bin_code  (r_bin_ptr),
        .gray_code (r_gray_ptr_ff)
    );

    // FIFO Memory
    async_fifo_memory fifo_memory (
        .wclk      (wclk),
        .wrst_n    (wrst_n),
        .winc      (winc),
        .wdata     (wdata),
        .w_bin_ptr (w_bin_ptr),
        .r_bin_ptr (r_bin_ptr),
        .rdata     (rdata)
    );

    // Full Flag Logic
    reg [ASIZE:0] w_bin_ptr_plus_one;
    always @(*) begin
        w_bin_ptr_plus_one = w_bin_ptr + 1;
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            w_full_flag <= 1'b0;
        end else begin
            w_full_flag <= (w_bin_ptr_plus_one[ASIZE-1:0] == r_gray_ptr_ff);
        end
    end

    // Empty Flag Logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            r_empty_flag <= 1'b1;
        end else begin
            r_empty_flag <= (w_gray_ptr_ff == r_bin_ptr);
        end
    end

    // Output Assignments
    assign wfull  = w_full_flag;
    assign awfull = w_full_flag;
    assign rempty = r_empty_flag;
    assign arempty = r_empty_flag;

endmodule

module gray_counter (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             inc,
    output wire [ASIZE-1:0] gray_ptr
);

    reg [ASIZE-1:0] gray_reg;
    wire [ASIZE-1:0] gray_next;

    // Gray Counter Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_reg <= {ASIZE{1'b0}};
        end else if (inc) begin
            gray_next = gray_reg + 1;
            gray_reg <= gray_next;
        end
    end

    assign gray_ptr = gray_reg;

endmodule

module gray_to_bin (
    input  wire [ASIZE-1:0] gray_code,
    output wire [ASIZE-1:0] bin_code
);

    genvar i;
    generate
        assign bin_code[0] = gray_code[0];
        for (i = 1; i < ASIZE; i = i + 1) begin : gen_gray_to_bin
            assign bin_code[i] = bin_code[i-1] ^ gray_code[i];
        end
    endgenerate

endmodule

module bin_to_gray (
    input  wire [ASIZE-1:0] bin_code,
    output wire [ASIZE-1:0] gray_code
);

    genvar i;
    generate
        assign gray_code[ASIZE-1] = bin_code[ASIZE-1];
        for (i = ASIZE-2; i >= 0; i = i - 1) begin : gen_bin_to_gray
            assign gray_code[i] = bin_code[i] ^ bin_code[i+1];
        end
    endgenerate

endmodule

module async_fifo_memory (
    input  wire             wclk,
    input  wire             wrst_n,
    input  wire             winc,
    input  wire [DSIZE-1:0] wdata,
    input  wire [ASIZE-1:0] w_bin_ptr,
    input  wire [ASIZE-1:0] r_bin_ptr,
    output wire [DSIZE-1:0] rdata
);

    reg [DSIZE-1:0] memory [0:(2**ASIZE)-1];

    // Write Operation
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (integer i = 0; i < 2**ASIZE; i = i + 1) begin
                memory[i] <= {DSIZE{1'b0}};
            end
        end else if (winc) begin
            memory[w_bin_ptr] <= wdata;
        end
    end

    // Read Operation
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= {DSIZE{1'b0}};
        end else begin
            rdata <= memory[r_bin_ptr];
        end
    end

endmodule
