module async_bidir_ramif_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
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
       input wire              b_dir,
       output wire             o_ram_a_clk,
       output wire [DSIZE-1:0] o_ram_a_wdata,
       input wire [DSIZE-1:0]  i_ram_a_rdata,
       output wire [ASIZE-1:0] o_ram_a_addr,
       output wire             o_ram_a_rinc,
       output wire             o_ram_a_winc,
       output wire             o_ram_b_clk,
       output wire [DSIZE-1:0] o_ram_b_wdata,
       input wire [DSIZE-1:0]  i_ram_b_rdata,
       output wire [ASIZE-1:0] o_ram_b_addr,
       output wire             o_ram_b_rinc,
       output wire             o_ram_b_winc
       );

    // Internal signals for a_clk domain
    reg [ASIZE-1:0] a_wptr, a_rptr;
    reg [ASIZE-1:0] a_wptr_gray, a_rptr_gray;
    reg [ASIZE-1:0] a_wptr_gray_sync, a_rptr_gray_sync;
    reg [DSIZE-1:0] a_rdata_reg;
    reg             a_full_sync, a_empty_sync;

    // Internal signals for b_clk domain
    reg [ASIZE-1:0] b_wptr, b_rptr;
    reg [ASIZE-1:0] b_wptr_gray, b_rptr_gray;
    reg [ASIZE-1:0] b_wptr_gray_sync, b_rptr_gray_sync;
    reg [DSIZE-1:0] b_rdata_reg;
    reg             b_full_sync, b_empty_sync;

    // Gray code conversion
    function [ASIZE-1:0] bin2gray;
        input [ASIZE-1:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Binary code conversion
    function [ASIZE-1:0] gray2bin;
        input [ASIZE-1:0] gray;
        integer i;
        reg [ASIZE-1:0] bin;
        bin = gray;
        for (i = ASIZE-2; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        gray2bin = bin;
    endfunction

    // a_clk domain logic
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_wptr <= 0;
            a_rptr <= 0;
            a_wptr_gray <= 0;
            a_rptr_gray <= 0;
        end else begin
            // Write pointer
            if (a_winc && !a_full_sync) begin
                a_wptr <= a_wptr + 1;
                a_wptr_gray <= bin2gray(a_wptr + 1);
            end

            // Read pointer
            if (a_rinc && !a_empty_sync) begin
                a_rptr <= a_rptr + 1;
                a_rptr_gray <= bin2gray(a_rptr + 1);
            end
        end
    end

    // Synchronize pointers to b_clk domain
    sync_cell a_wptr_gray_sync_inst (
        .clk(b_clk),
        .rst_n(b_rst_n),
        .din(a_wptr_gray),
        .dout(a_wptr_gray_sync)
    );

    sync_cell a_rptr_gray_sync_inst (
        .clk(b_clk),
        .rst_n(b_rst_n),
        .din(a_rptr_gray),
        .dout(a_rptr_gray_sync)
    );

    // Determine FIFO status in b_clk domain
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            a_full_sync <= 0;
            a_empty_sync <= 1;
        end else begin
            a_full_sync <= (a_wptr_gray_sync == bin2gray({{ASIZE-1{1'b1}}, 1'b0}));
            a_empty_sync <= (a_wptr_gray_sync == a_rptr_gray_sync);
        end
    end

    // b_clk domain logic
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_wptr <= 0;
            b_rptr <= 0;
            b_wptr_gray <= 0;
            b_rptr_gray <= 0;
        end else begin
            // Write pointer
            if (b_winc && !b_full_sync) begin
                b_wptr <= b_wptr + 1;
                b_wptr_gray <= bin2gray(b_wptr + 1);
            end

            // Read pointer
            if (b_rinc && !b_empty_sync) begin
                b_rptr <= b_rptr + 1;
                b_rptr_gray <= bin2gray(b_rptr + 1);
            end
        end
    end

    // Synchronize pointers to a_clk domain
    sync_cell b_wptr_gray_sync_inst (
        .clk(a_clk),
        .rst_n(a_rst_n),
        .din(b_wptr_gray),
        .dout(b_wptr_gray_sync)
    );

    sync_cell b_rptr_gray_sync_inst (
        .clk(a_clk),
        .rst_n(a_rst_n),
        .din(b_rptr_gray),
        .dout(b_rptr_gray_sync)
    );

    // Determine FIFO status in a_clk domain
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            b_full_sync <= 0;
            b_empty_sync <= 1;
        end else begin
            b_full_sync <= (b_wptr_gray_sync == bin2gray({{ASIZE-1{1'b1}}, 1'b0}));
            b_empty_sync <= (b_wptr_gray_sync == b_rptr_gray_sync);
        end
    end

    // FIFO flags in a_clk domain
    assign a_full = a_full_sync;
    assign a_empty = a_empty_sync;
    assign a_afull = (a_wptr_gray == bin2gray({{ASIZE-2{1'b1}}, 2'b01}));
    assign a_aempty = (a_wptr_gray == a_rptr_gray);

    // FIFO flags in b_clk domain
    assign b_full = b_full_sync;
    assign b_empty = b_empty_sync;
    assign b_afull = (b_wptr_gray == bin2gray({{ASIZE-2{1'b1}}, 2'b01}));
    assign b_aempty = (b_wptr_gray == b_rptr_gray);

    // Read data in a_clk domain
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_rdata_reg <= 0;
        end else if (a_rinc && !a_empty_sync) begin
            a_rdata_reg <= i_ram_a_rdata;
        end
    end

    assign a_rdata = a_rdata_reg;

    // Read data in b_clk domain
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_rdata_reg <= 0;
        end else if (b_rinc && !b_empty_sync) begin
            b_rdata_reg <= i_ram_b_rdata;
        end
    end

    assign b_rdata = b_rdata_reg;

    // RAM interface in a_clk domain
    assign o_ram_a_clk = a_clk;
    assign o_ram_a_wdata = a_wdata;
    assign o_ram_a_addr = a_wptr[ASIZE-1:0];
    assign o_ram_a_rinc = a_rinc;
    assign o_ram_a_winc = a_winc;

    // RAM interface in b_clk domain
    assign o_ram_b_clk = b_clk;
    assign o_ram_b_wdata = b_wdata;
    assign o_ram_b_addr = b_wptr[ASIZE-1:0];
    assign o_ram_b_rinc = b_rinc;
    assign o_ram_b_winc = b_winc;

endmodule

// Synchronization cell for asynchronous domain crossing
module sync_cell (
    input wire clk,
    input wire rst_n,
    input wire [ASIZE-1:0] din,
    output reg [ASIZE-1:0] dout
    );

    reg [ASIZE-1:0] stage1, stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1 <= 0;
            stage2 <= 0;
            dout <= 0;
        end else begin
            stage1 <= din;
            stage2 <= stage1;
            dout <= stage2;
        end
    end

endmodule
