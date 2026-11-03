module apbxclk #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    parameter [0:0] OPT_REGISTERED = 1'b0,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH
) (
    input wire S_APB_PCLK, S_PRESETn,
    input wire S_APB_PSEL,
    input wire S_APB_PENABLE,
    output reg S_APB_PREADY,
    input wire [AW-1:0] S_APB_PADDR,
    input wire S_APB_PWRITE,
    input wire [DW-1:0] S_APB_PWDATA,
    input wire [DW/8-1:0] S_APB_PWSTRB,
    input wire [2:0] S_APB_PPROT,
    output wire [DW-1:0] S_APB_PRDATA,
    output wire S_APB_PSLVERR,
    input wire M_APB_PCLK,
    output reg M_PRESETn,
    output reg M_APB_PSEL,
    output reg M_APB_PENABLE,
    input wire M_APB_PREADY,
    output wire [AW-1:0] M_APB_PADDR,
    output wire M_APB_PWRITE,
    output wire [DW-1:0] M_APB_PWDATA,
    output wire [DW/8-1:0] M_APB_PWSTRB,
    output wire [2:0] M_APB_PPROT,
    input wire [DW-1:0] M_APB_PRDATA,
    input wire M_APB_PSLVERR
);

    reg [AW-1:0] addr;
    reg write;
    reg [DW-1:0] wdata;
    reg [DW/8-1:0] wstrb;
    reg [2:0] prot;
    reg [DW-1:0] rdata;
    reg slverr;
    reg req;
    reg ack;

    assign M_PRESETn = S_PRESETn;
    assign M_APB_PSEL = req;
    assign M_APB_PADDR = addr;
    assign M_APB_PWRITE = write;
    assign M_APB_PWDATA = wdata;
    assign M_APB_PWSTRB = wstrb;
    assign M_APB_PPROT = prot;

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 1'b0;
            req <= 1'b0;
            ack <= 1'b0;
        end else if (S_APB_PSEL && !S_APB_PENABLE) begin
            req <= 1'b1;
            addr <= S_APB_PADDR;
            write <= S_APB_PWRITE;
            wdata <= S_APB_PWDATA;
            wstrb <= S_APB_PWSTRB;
            prot <= S_APB_PPROT;
        end else if (req && M_APB_PREADY) begin
            req <= 1'b0;
            ack <= 1'b1;
        end else if (ack && S_APB_PENABLE) begin
            S_APB_PREADY <= 1'b1;
            ack <= 1'b0;
        end
    end

    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_APB_PENABLE <= 1'b0;
        end else if (req && !M_APB_PENABLE) begin
            M_APB_PENABLE <= 1'b1;
        end else if (M_APB_PREADY) begin
            M_APB_PENABLE <= 1'b0;
        end
    end

    always @(posedge S_APB_PCLK) begin
        if (S_APB_PENABLE && ack) begin
            S_APB_PRDATA <= M_APB_PRDATA;
            S_APB_PSLVERR <= M_APB_PSLVERR;
        end
    end

    always @(posedge M_APB_PCLK) begin
        if (M_APB_PREADY) begin
            rdata <= M_APB_PRDATA;
            slverr <= M_APB_PSLVERR;
        end
    end

endmodule
