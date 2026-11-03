module async_bidir_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir,
       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_winc,
       input wire [DSIZE-1:0]  b_wdata,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty,
       input wire              b_dir
       );

    localparam DEPTH = 1 << ASIZE;
    localparam AWIDTH = ASIZE;

    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // a-side signals
    reg [AWIDTH:0] a_wr_ptr;
    reg [AWIDTH:0] a_rd_ptr;
    reg [AWIDTH:0] a_wr_ptr_gray;
    reg [AWIDTH:0] a_rd_ptr_gray;
    reg [AWIDTH:0] b_rd_ptr_gray_sync;
    reg [AWIDTH:0] b_wr_ptr_gray_sync;

    // b-side signals
    reg [AWIDTH:0] b_wr_ptr;
    reg [AWIDTH:0] b_rd_ptr;
    reg [AWIDTH:0] b_wr_ptr_gray;
    reg [AWIDTH:0] b_rd_ptr_gray;
    reg [AWIDTH:0] a_rd_ptr_gray_sync;
    reg [AWIDTH:0] a_wr_ptr_gray_sync;

    // a-side logic
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_wr_ptr <= 0;
            a_rd_ptr <= 0;
        end else begin
            if (a_dir && !a_full) begin
                mem[a_wr_ptr[AWIDTH-1:0]] <= a_wdata;
                a_wr_ptr <= a_wr_ptr + 1;
            end
            if (!a_dir && !a_empty) begin
                a_rd_ptr <= a_rd_ptr + 1;
            end
        end
    end

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_wr_ptr_gray <= 0;
            a_rd_ptr_gray <= 0;
        end else begin
            a_wr_ptr_gray <= (a_wr_ptr >> 1) ^ a_wr_ptr;
            a_rd_ptr_gray <= (a_rd_ptr >> 1) ^ a_rd_ptr;
        end
    end

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            a_rd_ptr_gray_sync <= 0;
            a_wr_ptr_gray_sync <= 0;
        end else begin
            a_rd_ptr_gray_sync <= a_rd_ptr_gray;
            a_wr_ptr_gray_sync <= a_wr_ptr_gray;
        end
    end

    // b-side logic
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_wr_ptr <= 0;
            b_rd_ptr <= 0;
        end else begin
            if (b_dir && !b_full) begin
                mem[b_wr_ptr[AWIDTH-1:0]] <= b_wdata;
                b_wr_ptr <= b_wr_ptr + 1;
            end
            if (!b_dir && !b_empty) begin
                b_rd_ptr <= b_rd_ptr + 1;
            end
        end
    end

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_wr_ptr_gray <= 0;
            b_rd_ptr_gray <= 0;
        end else begin
            b_wr_ptr_gray <= (b_wr_ptr >> 1) ^ b_wr_ptr;
            b_rd_ptr_gray <= (b_rd_ptr >> 1) ^ b_rd_ptr;
        end
    end

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            b_wr_ptr_gray_sync <= 0;
            b_rd_ptr_gray_sync <= 0;
        end else begin
            b_wr_ptr_gray_sync <= b_wr_ptr_gray;
            b_rd_ptr_gray_sync <= b_rd_ptr_gray;
        end
    end

    // a-side flags
    assign a_full = (a_wr_ptr_gray[AWIDTH] != a_rd_ptr_gray_sync[AWIDTH]) && (a_wr_ptr_gray[AWIDTH-1:0] == a_rd_ptr_gray_sync[AWIDTH-1:0]);
    assign a_empty = (a_wr_ptr_gray_sync[AWIDTH] == a_rd_ptr_gray[AWIDTH]) && (a_wr_ptr_gray_sync[AWIDTH-1:0] == a_rd_ptr_gray[AWIDTH-1:0]);
    assign a_afull = (a_wr_ptr_gray[AWIDTH] != a_rd_ptr_gray_sync[AWIDTH]) && (a_wr_ptr_gray[AWIDTH-1:0] == (a_rd_ptr_gray_sync[AWIDTH-1:0] + 1));
    assign a_aempty = (a_wr_ptr_gray_sync[AWIDTH] == a_rd_ptr_gray[AWIDTH]) && (a_wr_ptr_gray_sync[AWIDTH-1:0] == (a_rd_ptr_gray[AWIDTH-1:0] - 1));

    // b-side flags
    assign b_full = (b_wr_ptr_gray[AWIDTH] != b_rd_ptr_gray_sync[AWIDTH]) && (b_wr_ptr_gray[AWIDTH-1:0] == b_rd_ptr_gray_sync[AWIDTH-1:0]);
    assign b_empty = (b_wr_ptr_gray_sync[AWIDTH] == b_rd_ptr_gray[AWIDTH]) && (b_wr_ptr_gray_sync[AWIDTH-1:0] == b_rd_ptr_gray[AWIDTH-1:0]);
    assign b_afull = (b_wr_ptr_gray[AWIDTH] != b_rd_ptr_gray_sync[AWIDTH]) && (b_wr_ptr_gray[AWIDTH-1:0] == (b_rd_ptr_gray_sync[AWIDTH-1:0] + 1));
    assign b_aempty = (b_wr_ptr_gray_sync[AWIDTH] == b_rd_ptr_gray[AWIDTH]) && (b_wr_ptr_gray_sync[AWIDTH-1:0] == (b_rd_ptr_gray[AWIDTH-1:0] - 1));

    // a-side read data
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_rdata <= 0;
        end else if (!a_dir && !a_empty) begin
            a_rdata <= mem[a_rd_ptr[AWIDTH-1:0]];
        end
    end

    // b-side read data
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_rdata <= 0;
        end else if (!b_dir && !b_empty) begin
            b_rdata <= mem[b_rd_ptr[AWIDTH-1:0]];
        end
    end

endmodule
