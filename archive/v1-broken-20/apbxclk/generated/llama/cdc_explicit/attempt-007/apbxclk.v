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

    reg [AW-1:0] addr_reg;
    reg [DW-1:0] data_reg;
    reg [DW/8-1:0] strb_reg;
    reg [2:0] prot_reg;
    reg write_reg;
    reg sel_reg;
    reg enable_reg;
    reg ready_reg;
    reg slverr_reg;
    reg [DW-1:0] rdata_reg;

    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam SEND = 2'b01;
    localparam WAIT = 2'b10;

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            state <= IDLE;
            S_APB_PREADY <= 1'b0;
            M_PRESETn <= 1'b0;
            M_APB_PSEL <= 1'b0;
            M_APB_PENABLE <= 1'b0;
        end else if (state == IDLE) begin
            if (S_APB_PSEL && !S_APB_PENABLE) begin
                addr_reg <= S_APB_PADDR;
                data_reg <= S_APB_PWDATA;
                strb_reg <= S_APB_PWSTRB;
                prot_reg <= S_APB_PPROT;
                write_reg <= S_APB_PWRITE;
                sel_reg <= S_APB_PSEL;
                enable_reg <= S_APB_PENABLE;
                state <= SEND;
            end
        end else if (state == SEND) begin
            M_PRESETn <= 1'b1;
            M_APB_PSEL <= sel_reg;
            M_APB_PENABLE <= 1'b1;
            M_APB_PADDR <= addr_reg;
            M_APB_PWRITE <= write_reg;
            M_APB_PWDATA <= data_reg;
            M_APB_PWSTRB <= strb_reg;
            M_APB_PPROT <= prot_reg;
            state <= WAIT;
        end else if (state == WAIT) begin
            if (M_APB_PREADY) begin
                rdata_reg <= M_APB_PRDATA;
                slverr_reg <= M_APB_PSLVERR;
                S_APB_PREADY <= 1'b1;
                S_APB_PRDATA <= rdata_reg;
                S_APB_PSLVERR <= slverr_reg;
                state <= IDLE;
            end
        end
    end

    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 1'b0;
        end else begin
            M_PRESETn <= 1'b1;
        end
    end

endmodule
