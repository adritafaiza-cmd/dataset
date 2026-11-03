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

    reg [AW-1:0] s_addr_reg;
    reg [DW-1:0] s_wdata_reg;
    reg [DW/8-1:0] s_wstrb_reg;
    reg s_write_reg;
    reg [2:0] s_prot_reg;
    reg s_psel_reg;
    reg s_penable_reg;

    reg [AW-1:0] m_addr_reg;
    reg [DW-1:0] m_wdata_reg;
    reg [DW/8-1:0] m_wstrb_reg;
    reg m_write_reg;
    reg [2:0] m_prot_reg;
    reg m_psel_reg;
    reg m_penable_reg;

    reg s_ready_reg;
    reg m_ready_reg;

    reg [DW-1:0] s_rdata_reg;
    reg s_slverr_reg;

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_addr_reg <= 0;
            s_wdata_reg <= 0;
            s_wstrb_reg <= 0;
            s_write_reg <= 0;
            s_prot_reg <= 0;
            s_psel_reg <= 0;
            s_penable_reg <= 0;
            s_ready_reg <= 0;
            m_ready_reg <= 0;
            s_rdata_reg <= 0;
            s_slverr_reg <= 0;
        end else begin
            if (S_APB_PSEL && S_APB_PENABLE && !s_ready_reg) begin
                s_addr_reg <= S_APB_PADDR;
                s_wdata_reg <= S_APB_PWDATA;
                s_wstrb_reg <= S_APB_PWSTRB;
                s_write_reg <= S_APB_PWRITE;
                s_prot_reg <= S_APB_PPROT;
                s_psel_reg <= S_APB_PSEL;
                s_penable_reg <= S_APB_PENABLE;
                s_ready_reg <= 1;
            end else if (M_APB_PREADY && s_ready_reg) begin
                s_ready_reg <= 0;
            end

            if (s_ready_reg) begin
                m_addr_reg <= s_addr_reg;
                m_wdata_reg <= s_wdata_reg;
                m_wstrb_reg <= s_wstrb_reg;
                m_write_reg <= s_write_reg;
                m_prot_reg <= s_prot_reg;
                m_psel_reg <= s_psel_reg;
                m_penable_reg <= s_penable_reg;
                m_ready_reg <= 1;
            end else if (M_APB_PREADY && m_ready_reg) begin
                m_ready_reg <= 0;
            end
        end
    end

    assign S_APB_PREADY = s_ready_reg;

    assign S_APB_PRDATA = s_rdata_reg;
    assign S_APB_PSLVERR = s_slverr_reg;

    always @(posedge M_APB_PCLK) begin
        if (M_APB_PREADY) begin
            s_rdata_reg <= M_APB_PRDATA;
            s_slverr_reg <= M_APB_PSLVERR;
        end
    end

    assign M_PRESETn = S_PRESETn;
    assign M_APB_PSEL = m_psel_reg;
    assign M_APB_PENABLE = m_penable_reg;
    assign M_APB_PADDR = m_addr_reg;
    assign M_APB_PWRITE = m_write_reg;
    assign M_APB_PWDATA = m_wdata_reg;
    assign M_APB_PWSTRB = m_wstrb_reg;
    assign M_APB_PPROT = m_prot_reg;

endmodule
