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

    wire [ASIZE-1:0] gray_wr_cnt_out;
    wire [ASIZE-1:0] gray_rd_cnt_out;
    wire [ASIZE-1:0] wr_cnt_bin;
    wire [ASIZE-1:0] rd_cnt_bin;
    wire [ASIZE-1:0] gray_wr_cnt_out_sync;
    wire [ASIZE-1:0] gray_rd_cnt_out_sync;
    wire [ASIZE-1:0] wr_cnt_bin_sync;
    wire [ASIZE-1:0] rd_cnt_bin_sync;

    wire [ASIZE:0] wr_addr_plus_one;
    wire [ASIZE:0] rd_addr_plus_one;
    wire [ASIZE:0] wr_ptr_gray_sync_plus_one;
    wire [ASIZE:0] rd_ptr_gray_sync_plus_one;

    assign wr_addr_plus_one = wr_cnt_bin + 1;
    assign rd_addr_plus_one = rd_cnt_bin + 1;
    assign wr_ptr_gray_sync_plus_one = wr_cnt_bin_sync + 1;
    assign rd_ptr_gray_sync_plus_one = rd_cnt_bin_sync + 1;

    assign wfull = (wr_addr_plus_one[ASIZE-1:0] == rd_cnt_bin_sync);
    assign awfull = (wr_ptr_gray_sync_plus_one[ASIZE-1:0] == rd_cnt_bin);
    assign rempty = (wr_cnt_bin_sync == rd_addr_plus_one[ASIZE-1:0]);
    assign arempty = (wr_cnt_bin == rd_ptr_gray_sync_plus_one[ASIZE-1:0]);

    gray_counter gray_wr_cnt (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .gray_out(gray_wr_cnt_out)
    );

    gray_counter gray_rd_cnt (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .gray_out(gray_rd_cnt_out)
    );

    gray_to_bin gray_to_bin_wr (
        .gray_in(gray_wr_cnt_out),
        .bin_out(wr_cnt_bin)
    );

    gray_to_bin gray_to_bin_rd (
        .gray_in(gray_rd_cnt_out),
        .bin_out(rd_cnt_bin)
    );

    gray_to_bin gray_to_bin_wr_sync (
        .gray_in(gray_wr_cnt_out_sync),
        .bin_out(wr_cnt_bin_sync)
    );

    gray_to_bin gray_to_bin_rd_sync (
        .gray_in(gray_rd_cnt_out_sync),
        .bin_out(rd_cnt_bin_sync)
    );

    sync_register sync_wr_cnt (
        .src_clk(wclk),
        .src_signal(gray_wr_cnt_out),
        .dst_clk(rclk),
        .dst_signal(gray_wr_cnt_out_sync)
    );

    sync_register sync_rd_cnt (
        .src_clk(rclk),
        .src_signal(gray_rd_cnt_out),
        .dst_clk(wclk),
        .dst_signal(gray_rd_cnt_out_sync)
    );

    fifo_memory fifo_mem (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wdata(wdata),
        .wr_cnt_bin(wr_cnt_bin),
        .rdata(rdata),
        .rinc(rinc),
        .rd_cnt_bin(rd_cnt_bin)
    );

endmodule

module gray_counter (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             inc,
    output wire [ASIZE-1:0] gray_out
);

    reg [ASIZE-1:0] count;
    reg [ASIZE-1:0] next_count;
    wire [ASIZE-1:0] gray_next;

    assign gray_next = (count ^ (count >> 1));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else if (inc) begin
            count <= next_count;
        end
    end

    always @(*) begin
        next_count = count + 1;
    end

    assign gray_out = gray_next;

endmodule

module gray_to_bin (
    input  wire [ASIZE-1:0] gray_in,
    output wire [ASIZE-1:0] bin_out
);

    wire [ASIZE-1:0] bin_next;

    assign bin_next[0] = gray_in[0];
    generate
        genvar i;
        for (i = 1; i < ASIZE; i = i + 1) begin: gen_gray_to_bin
            assign bin_next[i] = bin_next[i-1] ^ gray_in[i];
        end
    endgenerate

    assign bin_out = bin_next;

endmodule

module sync_register (
    input  wire             src_clk,
    input  wire [ASIZE-1:0] src_signal,
    input  wire             dst_clk,
    output wire [ASIZE-1:0] dst_signal
);

    reg [ASIZE-1:0] reg1;
    reg [ASIZE-1:0] reg2;

    always @(posedge src_clk) begin
        reg1 <= src_signal;
    end

    always @(posedge dst_clk) begin
        reg2 <= reg1;
    end

    assign dst_signal = reg2;

endmodule

module fifo_memory (
    input  wire             wclk,
    input  wire             wrst_n,
    input  wire             winc,
    input  wire [DSIZE-1:0] wdata,
    input  wire [ASIZE-1:0] wr_cnt_bin,
    output wire [DSIZE-1:0] rdata,
    input  wire             rinc,
    input  wire [ASIZE-1:0] rd_cnt_bin
);

    reg [DSIZE-1:0] memory [0:(2**ASIZE)-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (integer i = 0; i < (2**ASIZE); i = i + 1) begin
                memory[i] <= 0;
            end
        end else if (winc) begin
            memory[wr_cnt_bin] <= wdata;
        end
    end

    always @(posedge rclk) begin
        if (rinc) begin
            rdata <= memory[rd_cnt_bin];
        end
    end

endmodule
