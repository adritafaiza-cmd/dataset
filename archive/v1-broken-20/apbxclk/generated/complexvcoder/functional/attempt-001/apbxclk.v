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

    reg [AW-1:0] m_apb_paddr;
    reg m_apb_pwrite;
    reg [DW-1:0] m_apb_pwdata;
    reg [DW/8-1:0] m_apb_pwstrb;
    reg [2:0] m_apb_pprot;
    wire m_apb_pready;
    wire [DW-1:0] m_apb_prdata;
    wire m_apb_pslverr;

    reg s_apb_psel_reg;
    reg s_apb_penable_reg;
    reg [AW-1:0] s_apb_paddr_reg;
    reg s_apb_pwrite_reg;
    reg [DW-1:0] s_apb_pwdata_reg;
    reg [DW/8-1:0] s_apb_pwstrb_reg;
    reg [2:0] s_apb_pprot_reg;

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_apb_psel_reg <= 0;
            s_apb_penable_reg <= 0;
            s_apb_paddr_reg <= 0;
            s_apb_pwrite_reg <= 0;
            s_apb_pwdata_reg <= 0;
            s_apb_pwstrb_reg <= 0;
            s_apb_pprot_reg <= 0;
        end else begin
            s_apb_psel_reg <= S_APB_PSEL;
            s_apb_penable_reg <= S_APB_PENABLE;
            s_apb_paddr_reg <= S_APB_PADDR;
            s_apb_pwrite_reg <= S_APB_PWRITE;
            s_apb_pwdata_reg <= S_APB_PWDATA;
            s_apb_pwstrb_reg <= S_APB_PWSTRB;
            s_apb_pprot_reg <= S_APB_PPROT;
        end
    end

    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 1;
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
            M_APB_PADDR <= 0;
            M_APB_PWRITE <= 0;
            M_APB_PWDATA <= 0;
            M_APB_PWSTRB <= 0;
            M_APB_PPROT <= 0;
        end else begin
            M_PRESETn <= 0;
            M_APB_PSEL <= s_apb_psel_reg;
            M_APB_PENABLE <= s_apb_penable_reg;
            M_APB_PADDR <= s_apb_paddr_reg;
            M_APB_PWRITE <= s_apb_pwrite_reg;
            M_APB_PWDATA <= s_apb_pwdata_reg;
            M_APB_PWSTRB <= s_apb_pwstrb_reg;
            M_APB_PPROT <= s_apb_pprot_reg;
        end
    end

    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_apb_paddr <= 0;
            m_apb_pwrite <= 0;
            m_apb_pwdata <= 0;
            m_apb_pwstrb <= 0;
            m_apb_pprot <= 0;
            m_apb_pready <= 0;
            m_apb_prdata <= 0;
            m_apb_pslverr <= 0;
        end else begin
            m_apb_paddr <= s_apb_paddr_reg;
            m_apb_pwrite <= s_apb_pwrite_reg;
            m_apb_pwdata <= s_apb_pwdata_reg;
            m_apb_pwstrb <= s_apb_pwstrb_reg;
            m_apb_pprot <= s_apb_pprot_reg;
            m_apb_pready <= M_APB_PREADY;
            m_apb_prdata <= M_APB_PRDATA;
            m_apb_pslverr <= M_APB_PSLVERR;
        end
    end

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 0;
        end else begin
            S_APB_PREADY <= m_apb_pready;
        end
    end

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PRDATA <= 0;
            S_APB_PSLVERR <= 0;
        end else begin
            S_APB_PRDATA <= m_apb_prdata;
            S_APB_PSLVERR <= m_apb_pslverr;
        end
    end

endmodule
