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
    reg s_write_reg;
    reg [DW-1:0] s_wdata_reg;
    reg [DW/8-1:0] s_wstrb_reg;
    reg [2:0] s_prot_reg;
    reg s_sel_reg;
    reg s_enable_reg;
    reg m_ready_reg;

    reg [AW-1:0] m_addr_reg;
    reg m_write_reg;
    reg [DW-1:0] m_wdata_reg;
    reg [DW/8-1:0] m_wstrb_reg;
    reg [2:0] m_prot_reg;
    reg m_sel_reg;
    reg m_enable_reg;

    reg s_ready_reg;
    reg m_ready_out_reg;

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_addr_reg <= 0;
            s_write_reg <= 0;
            s_wdata_reg <= 0;
            s_wstrb_reg <= 0;
            s_prot_reg <= 0;
            s_sel_reg <= 0;
            s_enable_reg <= 0;
            s_ready_reg <= 0;
        end else begin
            if (S_APB_PSEL && S_APB_PENABLE && !S_APB_PREADY) begin
                s_addr_reg <= S_APB_PADDR;
                s_write_reg <= S_APB_PWRITE;
                s_wdata_reg <= S_APB_PWDATA;
                s_wstrb_reg <= S_APB_PWSTRB;
                s_prot_reg <= S_APB_PPROT;
                s_sel_reg <= S_APB_PSEL;
                s_enable_reg <= S_APB_PENABLE;
            end
            s_ready_reg <= S_APB_PREADY;
        end
    end

    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_addr_reg <= 0;
            m_write_reg <= 0;
            m_wdata_reg <= 0;
            m_wstrb_reg <= 0;
            m_prot_reg <= 0;
            m_sel_reg <= 0;
            m_enable_reg <= 0;
            m_ready_reg <= 0;
        end else begin
            if (m_ready_out_reg) begin
                M_APB_PADDR <= m_addr_reg;
                M_APB_PWRITE <= m_write_reg;
                M_APB_PWDATA <= m_wdata_reg;
                M_APB_PWSTRB <= m_wstrb_reg;
                M_APB_PPROT <= m_prot_reg;
                M_APB_PSEL <= m_sel_reg;
                M_APB_PENABLE <= m_enable_reg;
                m_ready_reg <= 1;
            end else begin
                m_ready_reg <= 0;
            end
        end
    end

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 0;
        end else begin
            S_APB_PREADY <= m_ready_reg;
        end
    end

    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 1;
        end else begin
            M_PRESETn <= 0;
        end
    end

    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            m_ready_out_reg <= 0;
        end else begin
            if (M_APB_PREADY) begin
                m_ready_out_reg <= 0;
            end else begin
                m_ready_out_reg <= 1;
            end
        end
    end

endmodule
