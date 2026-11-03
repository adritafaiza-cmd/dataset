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

    reg [AW-1:0] s_addr;
    reg s_write;
    reg [DW-1:0] s_wdata;
    reg [DW/8-1:0] s_wstrb;
    reg [2:0] s_prot;
    wire s_ready;
    wire [DW-1:0] s_rdata;
    wire s_rslverr;

    reg m_addr;
    reg m_write;
    reg [DW-1:0] m_wdata;
    reg [DW/8-1:0] m_wstrb;
    reg [2:0] m_prot;
    wire m_ready;
    wire [DW-1:0] m_rdata;
    wire m_rslverr;

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 0;
            M_PRESETn <= 1;
        end else begin
            S_APB_PREADY <= m_ready;
            M_PRESETn <= 1;
        end
    end

    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
        end else begin
            M_APB_PSEL <= s_sel;
            M_APB_PENABLE <= s_en;
        end
    end

    wire s_sel = S_APB_PSEL & S_APB_PENABLE;
    wire s_en = s_ready;

    assign M_APB_PADDR = s_addr;
    assign M_APB_PWRITE = s_write;
    assign M_APB_PWDATA = s_wdata;
    assign M_APB_PWSTRB = s_wstrb;
    assign M_APB_PPROT = s_prot;

    assign s_addr = M_APB_PADDR;
    assign s_write = M_APB_PWRITE;
    assign s_wdata = M_APB_PWDATA;
    assign s_wstrb = M_APB_PWSTRB;
    assign s_prot = M_APB_PPROT;

    assign S_APB_PRDATA = m_rdata;
    assign S_APB_PSLVERR = m_rslverr;

    wire m_sel = M_APB_PSEL & M_APB_PENABLE;
    wire m_en = m_ready;

    assign S_APB_PADDR = m_addr;
    assign S_APB_PWRITE = m_write;
    assign S_APB_PWDATA = m_wdata;
    assign S_APB_PWSTRB = m_wstrb;
    assign S_APB_PPROT = m_prot;

    assign m_addr = S_APB_PADDR;
    assign m_write = S_APB_PWRITE;
    assign m_wdata = S_APB_PWDATA;
    assign m_wstrb = S_APB_PWSTRB;
    assign m_prot = S_APB_PPROT;

endmodule
