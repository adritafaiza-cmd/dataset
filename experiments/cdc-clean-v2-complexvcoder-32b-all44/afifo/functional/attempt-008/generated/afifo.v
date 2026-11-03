module afifo #(
        parameter	LGFIFO = 3,
        parameter	WIDTH  = 16,
        parameter	NFF    = 2,
        parameter [0:0]	WRITE_ON_POSEDGE = 1'b1,
        parameter [0:0]	OPT_REGISTER_READS = 1'b1
    ) (
        input	wire			i_wclk, i_wr_reset_n, i_wr,
        input	wire	[WIDTH-1:0]	i_wr_data,
        output	reg			o_wr_full,
        input	wire			i_rclk, i_rd_reset_n, i_rd,
        output	reg	[WIDTH-1:0]	o_rd_data,
        output	reg			o_rd_empty
    );

    // Internal signals
    reg [LGFIFO-1:0] wr_gray, rd_gray;
    reg [LGFIFO-1:0] wr_bin, rd_bin;
    reg wr_en, rd_en;
    reg wr_full, rd_empty;
    reg sync_rd_empty, sync_wr_full;
    reg [WIDTH-1:0] mem_rd_data;
    reg [WIDTH-1:0] rd_data_reg;

    // Write enable logic
    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            wr_en <= 1'b0;
        end else if (WRITE_ON_POSEDGE) begin
            wr_en <= i_wr & ~o_wr_full;
        end else begin
            wr_en <= ~o_wr_full;
            if (i_wr)
                wr_en <= ~o_wr_full;
            else
                wr_en <= 1'b0;
        end
    end

    // Read enable logic
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            rd_en <= 1'b0;
        end else begin
            rd_en <= i_rd & ~o_rd_empty;
        end
    end

    // Full and empty flags
    assign wr_full = (wr_gray == {1'b1, {(LGFIFO-1){1'b0}} ^ rd_gray};
    assign rd_empty = (wr_gray == rd_gray);

    // Gray counters
    gray_counter #(.LGFIFO(LGFIFO)) wr_gray_counter (
        .i_clk(i_wclk),
        .i_reset_n(i_wr_reset_n),
        .i_en(wr_en),
        .o_gray(wr_gray)
    );

    gray_counter #(.LGFIFO(LGFIFO)) rd_gray_counter (
        .i_clk(i_rclk),
        .i_reset_n(i_rd_reset_n),
        .i_en(rd_en),
        .o_gray(rd_gray)
    );

    // Binary to gray converters
    binary_gray_converter #(.LGFIFO(LGFIFO)) wr_bin_gray_converter (
        .i_bin(wr_bin),
        .o_gray(wr_gray)
    );

    binary_gray_converter #(.LGFIFO(LGFIFO)) rd_bin_gray_converter (
        .i_bin(rd_bin),
        .o_gray(rd_gray)
    );

    // FIFO memory
    fifo_memory #(.LGFIFO(LGFIFO), .WIDTH(WIDTH)) fifo_mem (
        .i_wclk(i_wclk),
        .i_wr_reset_n(i_wr_reset_n),
        .i_wr(wr_en),
        .i_wr_data(i_wr_data),
        .i_rclk(i_rclk),
        .i_rd_reset_n(i_rd_reset_n),
        .i_rd(rd_en),
        .o_rd_data(mem_rd_data)
    );

    // Synchronizers
    sync_register #(.NFF(NFF)) wr_sync_empty (
        .i_clk(i_wclk),
        .i_reset_n(i_wr_reset_n),
        .i_data(rd_empty),
        .o_data(sync_rd_empty)
    );

    sync_register #(.NFF(NFF)) rd_sync_full (
        .i_clk(i_rclk),
        .i_reset_n(i_rd_reset_n),
        .i_data(wr_full),
        .o_data(sync_wr_full)
    );

    // Outputs
    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            o_wr_full <= 1'b0;
        end else begin
            o_wr_full <= sync_wr_full;
        end
    end

    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            o_rd_empty <= 1'b1;
        end else begin
            o_rd_empty <= sync_rd_empty;
        end
    end

    // Read data output with optional register
    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            rd_data_reg <= {WIDTH{1'b0}};
        end else if (rd_en) begin
            rd_data_reg <= mem_rd_data;
        end
    end

    assign o_rd_data = OPT_REGISTER_READS ? rd_data_reg : mem_rd_data;

endmodule

module sync_register #(
        parameter NFF = 2
    ) (
        input wire i_clk,
        input wire i_reset_n,
        input wire i_data,
        output reg o_data
    );

    reg [NFF-1:0] sync_stage;

    always @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n) begin
            sync_stage <= {NFF{1'b0}};
        end else begin
            sync_stage <= {sync_stage[NFF-2:0], i_data};
        end
    end

    assign o_data = sync_stage[NFF-1];

endmodule

module fifo_memory #(
        parameter LGFIFO = 3,
        parameter WIDTH = 16
    ) (
        input wire i_wclk,
        input wire i_wr_reset_n,
        input wire i_wr,
        input wire [WIDTH-1:0] i_wr_data,
        input wire i_rclk,
        input wire i_rd_reset_n,
        input wire i_rd,
        output reg [WIDTH-1:0] o_rd_data
    );

    reg [WIDTH-1:0] memory [0:(1<<LGFIFO)-1];
    reg [LGFIFO-1:0] wr_addr;
    reg [LGFIFO-1:0] rd_addr;

    always @(posedge i_wclk or negedge i_wr_reset_n) begin
        if (!i_wr_reset_n) begin
            wr_addr <= 0;
        end else if (i_wr) begin
            memory[wr_addr] <= i_wr_data;
            wr_addr <= wr_addr + 1;
        end
    end

    always @(posedge i_rclk or negedge i_rd_reset_n) begin
        if (!i_rd_reset_n) begin
            rd_addr <= 0;
            o_rd_data <= 0;
        end else if (i_rd) begin
            o_rd_data <= memory[rd_addr];
            rd_addr <= rd_addr + 1;
        end
    end

endmodule

module gray_counter #(
        parameter LGFIFO = 3
    ) (
        input wire i_clk,
        input wire i_reset_n,
        input wire i_en,
        output reg [LGFIFO-1:0] o_gray
    );

    reg [LGFIFO-1:0] bin_counter;

    always @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n) begin
            bin_counter <= 0;
            o_gray <= 0;
        end else if (i_en) begin
            bin_counter <= bin_counter + 1;
            o_gray <= bin_counter ^ (bin_counter >> 1);
        end
    end

endmodule

module binary_gray_converter #(
        parameter LGFIFO = 3
    ) (
        input wire [LGFIFO-1:0] i_bin,
        output wire [LGFIFO-1:0] o_gray
    );

    assign o_gray = i_bin ^ (i_bin >> 1);

endmodule
