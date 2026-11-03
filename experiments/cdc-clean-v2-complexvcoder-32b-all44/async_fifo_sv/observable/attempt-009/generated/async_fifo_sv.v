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

    wire [ADDR_WIDTH:0] wrptr_gray, rdptr_gray, wrptr_gray_sync, rdptr_gray_sync;
    wire [ADDR_WIDTH:0] wrptr_bin, rdptr_bin;

    // Write Logic
    wire wrfull_flag;
    wire [ADDR_WIDTH:0] wrptr_next;

    gray_code_converter #(.WIDTH(ADDR_WIDTH+1)) gray_code_converter_wrptr (
        .bin_in(wrptr_bin),
        .gray_out(wrptr_gray)
    );

    sync_flop #(.WIDTH(ADDR_WIDTH+1)) sync_wrptr_gray (
        .clk_in(wclk),
        .rst_n_in(wrst_n),
        .d_in(wrptr_gray),
        .clk_out(rclk),
        .rst_n_out(rrst_n),
        .d_out(wrptr_gray_sync)
    );

    gray_code_converter #(.WIDTH(ADDR_WIDTH+1)) gray_code_converter_wrptr_sync (
        .gray_in(wrptr_gray_sync),
        .bin_out(wrptr_bin)
    );

    write_logic #(.ADDR_WIDTH(ADDR_WIDTH)) write_logic_inst (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wrptr_bin(wrptr_bin),
        .rdptr_gray_sync(rdptr_gray_sync),
        .wfull(wrfull_flag),
        .waddr(waddr)
    );

    assign wrptr_next = wraddr;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wrptr_bin <= 0;
        end else if (winc && !wrfull_flag) begin
            wrptr_bin <= wrptr_next;
        end
    end

    // Read Logic
    wire rempty_flag;
    wire [ADDR_WIDTH:0] rdptr_next;

    gray_code_converter #(.WIDTH(ADDR_WIDTH+1)) gray_code_converter_rdptr (
        .bin_in(rdptr_bin),
        .gray_out(rdptr_gray)
    );

    sync_flop #(.WIDTH(ADDR_WIDTH+1)) sync_rdptr_gray (
        .clk_in(rclk),
        .rst_n_in(rrst_n),
        .d_in(rdptr_gray),
        .clk_out(wclk),
        .rst_n_out(wrst_n),
        .d_out(rdptr_gray_sync)
    );

    gray_code_converter #(.WIDTH(ADDR_WIDTH+1)) gray_code_converter_rdptr_sync (
        .gray_in(rdptr_gray_sync),
        .bin_out(rdptr_bin)
    );

    read_logic #(.ADDR_WIDTH(ADDR_WIDTH)) read_logic_inst (
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc),
        .rdptr_bin(rdptr_bin),
        .wrptr_gray_sync(wrptr_gray_sync),
        .rdata(rdata),
        .rempty(rempty_flag),
        .raddr(raddr)
    );

    assign rdptr_next = raddr;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdptr_bin <= 0;
        end else if (rinc && !rempty_flag) begin
            rdptr_bin <= rdptr_next;
        end
    end

    // FIFO Memory
    fifo_memory #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) fifo_memory_inst (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wdata(wdata),
        .wrptr_bin(wrptr_bin),
        .rclk(rclk),
        .rdptr_bin(rdptr_bin),
        .rdata(rdata)
    );

    assign wfull = wrfull_flag;
    assign rempty = rempty_flag;

endmodule

module sync_flop #(
    parameter WIDTH = 5
)(
    input  wire clk_in,
    input  wire rst_n_in,
    input  wire [WIDTH-1:0] d_in,
    input  wire clk_out,
    input  wire rst_n_out,
    output reg [WIDTH-1:0] d_out
);

    reg [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];

    always @(posedge clk_in or negedge rst_n_in) begin
        if (!rst_n_in) begin
            sync_reg[0] <= 0;
        end else begin
            sync_reg[0] <= d_in;
        end
    end

    generate
        genvar i;
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : gen_sync
            always @(posedge clk_in or negedge rst_n_in) begin
                if (!rst_n_in) begin
                    sync_reg[i] <= 0;
                end else begin
                    sync_reg[i] <= sync_reg[i-1];
                end
            end
        end
    endgenerate

    always @(posedge clk_out or negedge rst_n_out) begin
        if (!rst_n_out) begin
            d_out <= 0;
        end else begin
            d_out <= sync_reg[SYNC_STAGES-1];
        end
    end

endmodule

module gray_code_converter #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-1:0] gray_out
);

    assign gray_out = bin_in ^ (bin_in >> 1);

endmodule

module fifo_memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire wclk,
    input  wire wrst_n,
    input  wire winc,
    input  wire [DATA_WIDTH-1:0] wdata,
    input  wire [ADDR_WIDTH:0] wrptr_bin,
    input  wire rclk,
    input  wire [ADDR_WIDTH:0] rdptr_bin,
    output reg [DATA_WIDTH-1:0] rdata
);

    reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (integer i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
                mem[i] <= 0;
            end
        end else if (winc) begin
            mem[wrptr_bin[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else begin
            rdata <= mem[rdptr_bin[ADDR_WIDTH-1:0]];
        end
    end

endmodule

module write_logic #(
    parameter ADDR_WIDTH = 4
)(
    input  wire wclk,
    input  wire wrst_n,
    input  wire winc,
    input  wire [ADDR_WIDTH:0] wrptr_bin,
    input  wire [ADDR_WIDTH:0] rdptr_gray_sync,
    output reg wfull,
    output reg [ADDR_WIDTH:0] waddr
);

    reg [ADDR_WIDTH:0] rdptr_bin_sync;

    gray_code_converter #(.WIDTH(ADDR_WIDTH+1)) gray_code_converter_rdptr_sync (
        .gray_in(rdptr_gray_sync),
        .bin_out(rdptr_bin_sync)
    );

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull <= 0;
            waddr <= 0;
        end else begin
            if (winc && !wfull) begin
                waddr <= wrptr_bin + 1;
            end
            if (wrptr_bin == {~rdptr_bin_sync[ADDR_WIDTH], rdptr_bin_sync[ADDR_WIDTH-1:0]}) begin
                wfull <= 1;
            end else begin
                wfull <= 0;
            end
        end
    end

endmodule

module read_logic #(
    parameter ADDR_WIDTH = 4
)(
    input  wire rclk,
    input  wire rrst_n,
    input  wire rinc,
    input  wire [ADDR_WIDTH:0] rdptr_bin,
    input  wire [ADDR_WIDTH:0] wrptr_gray_sync,
    input  wire [DATA_WIDTH-1:0] rdata,
    output reg rempty,
    output reg [ADDR_WIDTH:0] raddr
);

    reg [ADDR_WIDTH:0] wrptr_bin_sync;

    gray_code_converter #(.WIDTH(ADDR_WIDTH+1)) gray_code_converter_wrptr_sync (
        .gray_in(wrptr_gray_sync),
        .bin_out(wrptr_bin_sync)
    );

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty <= 1;
            raddr <= 0;
        end else begin
            if (rinc && !rempty) begin
                raddr <= rdptr_bin + 1;
            end
            if (rdptr_bin == wrptr_bin_sync) begin
                rempty <= 1;
            end else begin
                rempty <= 0;
            end
        end
    end

endmodule
