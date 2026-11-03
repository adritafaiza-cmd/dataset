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

    wire [ASIZE:0] gray_counter_w_out;
    wire [ASIZE:0] gray_counter_r_out;
    wire [ASIZE:0] sync_wr_gray_dout;
    wire [ASIZE:0] sync_rd_gray_dout;
    wire [ASIZE:0] gray_counter_w_wr_ptr;
    wire [ASIZE:0] gray_counter_r_rd_ptr;

    gray_counter #(.ASIZE(ASIZE)) gray_counter_w (
        .clk     (wclk),
        .rst_n   (wrst_n),
        .inc     (winc & ~wfull),
        .wr_gray (sync_rd_gray_dout),
        .out     (gray_counter_w_out),
        .wr_ptr  (gray_counter_w_wr_ptr),
        .rd_gray (),
        .rd_ptr  ()
    );

    gray_counter #(.ASIZE(ASIZE)) gray_counter_r (
        .clk     (rclk),
        .rst_n   (rrst_n),
        .inc     (rinc & ~rempty),
        .wr_gray (),
        .out     (gray_counter_r_out),
        .wr_ptr  (),
        .rd_gray (sync_wr_gray_dout),
        .rd_ptr  (gray_counter_r_rd_ptr)
    );

    sync_register #(.WIDTH(ASIZE+1)) sync_wr_gray (
        .clk   (rclk),
        .rst_n (rrst_n),
        .din   (gray_counter_w_out),
        .dout  (sync_wr_gray_dout)
    );

    sync_register #(.WIDTH(ASIZE+1)) sync_rd_gray (
        .clk   (wclk),
        .rst_n (wrst_n),
        .din   (gray_counter_r_out),
        .dout  (sync_rd_gray_dout)
    );

    mem #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_mem (
        .wclk    (wclk),
        .wrst_n  (wrst_n),
        .wr_ptr  (gray_counter_w_wr_ptr),
        .wr_data (wdata),
        .rclk    (rclk),
        .rrst_n  (rrst_n),
        .rd_ptr  (gray_counter_r_rd_ptr),
        .rd_data (rdata)
    );

    wire [ASIZE:0] bin_wr_ptr;
    wire [ASIZE:0] bin_rd_ptr;

    assign bin_wr_ptr = (gray_counter_w_out ^ (gray_counter_w_out >> 1));
    assign bin_rd_ptr = (sync_wr_gray_dout ^ (sync_wr_gray_dout >> 1));

    wire [ASIZE:0] diff_ptr = bin_wr_ptr - bin_rd_ptr;

    assign wfull   = (diff_ptr == (2**(ASIZE) - 1));
    assign awfull  = (diff_ptr == (2**(ASIZE) - 2));
    assign rempty  = (diff_ptr == 0);
    assign arempty = (diff_ptr == 1);

endmodule

module gray_counter
    #(
        parameter ASIZE = 4
    )(
        input  wire             clk,
        input  wire             rst_n,
        input  wire             inc,
        input  wire [ASIZE:0]   wr_gray,
        output wire [ASIZE:0]   out,
        output wire [ASIZE:0]   wr_ptr,
        input  wire [ASIZE:0]   rd_gray,
        output wire [ASIZE:0]   rd_ptr
    );

    reg [ASIZE:0] bin_ptr;
    reg [ASIZE:0] gray;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_ptr <= 0;
            gray    <= 0;
        end else if (inc) begin
            bin_ptr <= bin_ptr + 1;
            gray    <= bin_ptr ^ (bin_ptr >> 1);
        end
    end

    assign out    = gray;
    assign wr_ptr = bin_ptr;
    assign rd_ptr = (wr_gray ^ (wr_gray >> 1));

endmodule

module sync_register
    #(
        parameter WIDTH = 5
    )(
        input  wire             clk,
        input  wire             rst_n,
        input  wire [WIDTH-1:0] din,
        output wire [WIDTH-1:0] dout
    );

    reg [WIDTH-1:0] reg1;
    reg [WIDTH-1:0] reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg1 <= 0;
            reg2 <= 0;
        end else begin
            reg1 <= din;
            reg2 <= reg1;
        end
    end

    assign dout = reg2;

endmodule

module mem
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire [ASIZE:0]   wr_ptr,
        input  wire [DSIZE-1:0] wr_data,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire [ASIZE:0]   rd_ptr,
        output wire [DSIZE-1:0] rd_data
    );

    reg [DSIZE-1:0] mem_array [0:(2**ASIZE)-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem_array <= '{default: 0};
        end else if (wr_ptr[ASIZE] == 0) begin
            mem_array[wr_ptr[ASIZE-1:0]] <= wr_data;
        end
    end

    reg [DSIZE-1:0] rd_data_reg;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_data_reg <= 0;
        end else if (rd_ptr[ASIZE] == 0) begin
            rd_data_reg <= mem_array[rd_ptr[ASIZE-1:0]];
        end
    end

    assign rd_data = rd_data_reg;

endmodule
