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

    // Internal signals
    reg [AW-1:0] s_apb_req_addr;
    reg s_apb_req_write;
    reg [DW-1:0] s_apb_req_wdata;
    reg [DW/8-1:0] s_apb_req_wstrb;
    reg [2:0] s_apb_req_prot;
    reg s_apb_req_valid;

    reg [AW-1:0] m_apb_req_addr;
    reg m_apb_req_write;
    reg [DW-1:0] m_apb_req_wdata;
    reg [DW/8-1:0] m_apb_req_wstrb;
    reg [2:0] m_apb_req_prot;
    reg m_apb_req_valid;

    reg [DW-1:0] m_apb_resp_rdata;
    reg m_apb_resp_slverr;
    reg m_apb_resp_valid;

    // Source APB clock domain
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 0;
            s_apb_req_valid <= 0;
        end else begin
            if (S_APB_PSEL && S_APB_PENABLE && !s_apb_req_valid) begin
                s_apb_req_addr <= S_APB_PADDR;
                s_apb_req_write <= S_APB_PWRITE;
                s_apb_req_wdata <= S_APB_PWDATA;
                s_apb_req_wstrb <= S_APB_PWSTRB;
                s_apb_req_prot <= S_APB_PPROT;
                s_apb_req_valid <= 1;
            end else if (m_apb_resp_valid) begin
                S_APB_PREADY <= 1;
                s_apb_req_valid <= 0;
            end else begin
                S_APB_PREADY <= 0;
            end
        end
    end

    // Destination APB clock domain
    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_PRESETn <= 0;
            M_APB_PSEL <= 0;
            M_APB_PENABLE <= 0;
            m_apb_req_valid <= 0;
            m_apb_resp_valid <= 0;
        end else begin
            M_PRESETn <= 1;

            if (s_apb_req_valid && !m_apb_req_valid) begin
                m_apb_req_addr <= s_apb_req_addr;
                m_apb_req_write <= s_apb_req_write;
                m_apb_req_wdata <= s_apb_req_wdata;
                m_apb_req_wstrb <= s_apb_req_wstrb;
                m_apb_req_prot <= s_apb_req_prot;
                m_apb_req_valid <= 1;
                M_APB_PSEL <= 1;
            end

            if (m_apb_req_valid && M_APB_PREADY) begin
                m_apb_req_valid <= 0;
                M_APB_PSEL <= 0;
                M_APB_PENABLE <= 0;
                m_apb_resp_rdata <= M_APB_PRDATA;
                m_apb_resp_slverr <= M_APB_PSLVERR;
                m_apb_resp_valid <= 1;
            end else if (M_APB_PSEL) begin
                M_APB_PENABLE <= 1;
            end else begin
                M_APB_PSEL <= 0;
                M_APB_PENABLE <= 0;
            end
        end
    end

    // Register crossing if OPT_REGISTERED is set
    reg [DW-1:0] s_apb_prdata_reg;
    reg s_apb_pslverr_reg;

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            s_apb_prdata_reg <= 0;
            s_apb_pslverr_reg <= 0;
        end else if (m_apb_resp_valid) begin
            s_apb_prdata_reg <= m_apb_resp_rdata;
            s_apb_pslverr_reg <= m_apb_resp_slverr;
        end
    end

    assign S_APB_PRDATA = OPT_REGISTERED ? s_apb_prdata_reg : m_apb_resp_rdata;
    assign S_APB_PSLVERR = OPT_REGISTERED ? s_apb_pslverr_reg : m_apb_resp_slverr;

    assign M_APB_PADDR = m_apb_req_addr;
    assign M_APB_PWRITE = m_apb_req_write;
    assign M_APB_PWDATA = m_apb_req_wdata;
    assign M_APB_PWSTRB = m_apb_req_wstrb;
    assign M_APB_PPROT = m_apb_req_prot;

endmodule
